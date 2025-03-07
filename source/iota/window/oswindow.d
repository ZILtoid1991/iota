module iota.window.oswindow;

version (Windows) {
	import core.sys.windows.windows;
	import core.sys.windows.wtypes;
	import core.sys.windows.commctrl;
	import core.sys.windows.wingdi;
	import std.conv : to;
	package extern(Windows) @nogc nothrow {
		alias  PFNWGLCREATECONTEXTATTRIBSARBPROC = HGLRC function(HDC hDC, HGLRC hShareContext, const(int)* attribList);
	}
} else version(OSX) {
	import cocoa;
	import objc.meta;
	import objc.runtime;
	import bindbc.opengl;
	import iota.controls.polling : setEventMonitor;
	struct Display {
        int width;
        int height;
    }

    alias inputContext = void*;  // For OSX compatibility with the existing interface
} else {
	import x11.Xlib;
	import x11.X;
	import x11.Xresource;
	import x11.Xutil;
	import x11.Xatom;
	import iota.window.backend_x11;
	import x11.extensions.XI;
	import x11.extensions.XI2;
	import x11.extensions.XInput;
	import x11.extensions.XInput2;
	import x11.cursorfont;
	//import deimos.X11.Xlib;
	//import deimos.X11.X;

}
public import iota.window.types;
public import iota.window.exception;
public import iota.etc.vers;
public import iota.window.fbdev;
import std.algorithm.mutation : remove;
import std.utf : toUTF16z, toUTF8;
import std.string : toStringz;
import iota.controls.types;
import bindbc.opengl;
//import collections.treemap;

/** 
 * Implements a wrapper for whatever windowing interface the OS has, with automatic reference counting.
 * Other window types supported by this library are inherited from this class.
 */
public class OSWindow {
	
	///Defines Window status values, also used on Windows for event handling.
	public enum Status : ubyte {
		init,
		Quit,
		Minimize,
		Maximize,
		Move,
		MoveEnded,
		Resize,
		ResizeEnded,
		InputLangCh,
		InputLangChReq,
	}
	public struct DrawParams {
		version (Windows) {
			HWND hWnd;
			UINT msg;
			WPARAM wParam;
			LPARAM lParam;
		}
	}
	/**
	 * NOT MEANT TO BE USER MODIFIED!
	 * Used for reference counting purposes.
	 * External keys should be added to it with function `addRef()`.
	 */
	public static OSWindow[]	refCount;
	///Handle to the window. Used for both automatic reference counting and for arguments in the I/O system.
	protected WindowH			windowHandle;
	protected WindowBitmap		icon;
	///Contains various statuscodes of the window.
	protected Status			status;
	protected bool				glAttribARBDone;
	///Stores various flags related to the window.
	protected uint				flags;
	protected int[4]			prevVals;
	///Window renderer should be kept here to ensure safe destruction.
	public FrameBufferRenderer	renderer;
	public static InputEvent	lastInputEvent;
	///Delegate called when a draw request is sent to the class.
	///It can intercept it for various reasons, but this is not OS independent, and so far no drawing API is planned 
	///that uses OS provided functions. 
	public nothrow @system void delegate(DrawParams params) drawDeleg;
	public nothrow @system void delegate(DrawParams params) frameDrawDeleg;
	version (Windows) {
		///Various calls from the OS are redirected to here, so then it can be used for certain types of event processing.
		///TODO: implement various window events (menu, drag-and-drop, etc)
		static extern (Windows) LRESULT wndprocCallback(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam) nothrow @system {
			//return DefWindowProcW(hWnd, msg, wParam, lParam);
			switch (msg) {
				case WM_CREATE, WM_NCCREATE:
					return DefWindowProcW(hWnd, msg, wParam, lParam);
				default:
					foreach (OSWindow key; refCount) {
						if (key.getHandle() == hWnd)
							return key.wndCallback(msg, wParam, lParam);
					}
					return DefWindowProcW(hWnd, msg, wParam, lParam);
			}
		}
		///Draw function for testing purposes
		debug public void testDraw(DrawParams params) @system nothrow {
			PAINTSTRUCT ps;
			RECT rc;
			HDC hdc = BeginPaint(windowHandle, &ps);
			GetClientRect(windowHandle, &rc);
			FillRect(hdc, &rc, cast(HBRUSH)(COLOR_WINDOW));
			DrawFrameControl(hdc, &rc, DFC_CAPTION, 0);
			EndPaint(windowHandle, &ps);
		}
		//protected static HINSTANCE	hInstance;
		///Stores registered class info. Each window has its own registered class by default.
		WNDCLASSW registeredClass;
		protected ATOM				regClResult;
		protected LPCWSTR			classname, windowname;
		protected HGLRC				glRenderingContext;
		protected HDC				windowDeviceContext;
		protected HCURSOR			winCursor;
		protected HICON				hIcon;
		protected static PFNWGLCREATECONTEXTATTRIBSARBPROC wglCreateContextAttribsARB;
		///hInstance is stored here, which is needed for window creation, etc. (WINDOWS ONLY)
		public static HINSTANCE		mainInst;
		///The current input language code (Windows).
		package static uint			inputLang;
		///All supported device modes. First dimension: device, second dimension: mode
		package static DEVMODEA[][]	screenModes;
		//package static DISPLAY_DEVICEA[] dispDevices;
		shared static this() {
			//NOTE: This is not the proper way of doing stuff like this.
			//However, this way we can possibly eliminate the need for use of `WinMain` and might also piss off some
			//people at Microsoft.
			mainInst = GetModuleHandle(null);

			INITCOMMONCONTROLSEX cctrl;
			cctrl.dwICC = 0x0000_ffff;
			InitCommonControlsEx(&cctrl);
			/* debug assert(InitCommonControlsEx(&cctrl) == TRUE, GetLastError().to!string());
			else assert(InitCommonControlsEx(&cctrl) == TRUE); */
			/* SetThemeAppProperties(0x7); */

			//const ULONG drvModesSize = DrvGet
			DISPLAY_DEVICEA[] dispDevices;
			DWORD counter;
			BOOL deviceResult;
			do {
				DISPLAY_DEVICEA currDevice = void;
				currDevice.cb = DISPLAY_DEVICEA.sizeof;
				deviceResult = EnumDisplayDevicesA(null, counter, &currDevice, 0x0001);
				if (deviceResult) dispDevices ~= currDevice;
				counter++;
			} while (deviceResult);
			screenModes.length = counter;
			for (int i ; i < dispDevices.length ; i++) {
				counter = 0;
				do {
					DEVMODEA currMode = void;
					currMode.dmSize = DEVMODEA.sizeof;
					deviceResult = EnumDisplaySettingsExA(dispDevices[i].DeviceName.ptr, counter, &currMode, 0x0004);
					if (deviceResult) screenModes[i] ~= currMode;
					counter++;
				} while (deviceResult);
			}
		}
	} else version (OSX) {
        protected NSWindow nsWindow;
        protected NSView contentView;
		private NSOpenGLContext glContext;
    	private NSOpenGLPixelFormat pixelFormat;

        @property Display mainDisplay() {
            Display disp;
            NSScreen screen = NSScreen.mainScreen();
            CGRect frame = screen.frame();
            disp.width = cast(int)frame.size.width;
            disp.height = cast(int)frame.size.height;
            return disp;
        }

        @property inputContext ic() {
            return null; // Temporary stub for OSX
        }

		public NSWindow getNSWindow() @nogc nothrow {
			return nsWindow;
		}

        shared static this() {
            // Initialize NSApplication
			auto app = NSApplication.sharedApplication;
            app.setActivationPolicy(NSApplicationActivationPolicy.Regular);
            app.activateIgnoringOtherApps(YES);
			setEventMonitor();
        }
	} else version (linux) {
		public static Atom WM_DELETE_WINDOW;
		public static Display* mainDisplay;
		public static Window root;
		protected static XVisualInfo* vInfo;
		protected static GLint[] attrList = [GLX_RGBA, GLX_DEPTH_SIZE, 24, GLX_DOUBLEBUFFER, None];
		protected static GLint[] glxAttribs = [
				GLX_X_RENDERABLE    , True,
				GLX_DRAWABLE_TYPE   , GLX_WINDOW_BIT,
				GLX_RENDER_TYPE     , GLX_RGBA_BIT,
				GLX_X_VISUAL_TYPE   , GLX_TRUE_COLOR,
				GLX_RED_SIZE        , 8,
				GLX_GREEN_SIZE      , 8,
				GLX_BLUE_SIZE       , 8,
				GLX_ALPHA_SIZE      , 8,
				GLX_DEPTH_SIZE      , 24,
				GLX_STENCIL_SIZE    , 8,
				GLX_DOUBLEBUFFER    , True,
				None
			];
		protected static Colormap cmap;
		public static const bool xinputAvail;
		public XIM im;
		public XIC ic;
		protected immutable(char)* windowname;
		protected XSetWindowAttributes attr;
		//protected GLXDrawable glxDr;
		protected GLXContext glxContext;
		struct Hints {
			c_ulong flags;
			c_ulong functions;
			c_ulong decorations;
			c_long inputMode;
			c_ulong status;
		}
		/**
		 * Initializes X11.
		 */
		shared static this() {
			mainDisplay = XOpenDisplay(null);
			const defScr = DefaultScreen(mainDisplay);
			root = XRootWindow(mainDisplay, defScr);
			int fbcount;
			GLXFBConfigP* fbc = glXChooseFBConfig(mainDisplay, defScr, glxAttribs.ptr, &fbcount);
			assert(fbc, "Failed to create framebuffer");
			int bestFBC = -1, worstFBC = -1, bestNumSamp = -1, worstNumSamp = 999;
			for (int i = 0; i < fbcount; ++i) {
				XVisualInfo* vi = glXGetVisualFromFBConfig(mainDisplay, fbc[i]);
				if (vi != null) {
					int sampBuf, samples;
					glXGetFBConfigAttrib(mainDisplay, fbc[i], GLX_SAMPLE_BUFFERS, &sampBuf);
					glXGetFBConfigAttrib(mainDisplay, fbc[i], GLX_SAMPLES, &samples);

					if (bestFBC < 0 || (sampBuf && samples > bestNumSamp)) {
						bestFBC = i;
						bestNumSamp = samples;
					}
					if (worstFBC < 0 || !sampBuf || samples < worstNumSamp) {
						worstFBC = i;
						worstNumSamp = samples;
					}
				}
				XFree(vi);
			}
			GLXFBConfigP bestFBCFinal = fbc[bestFBC];
			XFree(fbc);

			// vInfo = glXGetVisualFromFBConfig(mainDisplay, defScr, attrList.ptr);
			vInfo = glXGetVisualFromFBConfig(mainDisplay, bestFBCFinal);
			assert(vInfo, "Could not create visual info");
			cmap = XCreateColormap(mainDisplay, root, vInfo.visual, AllocNone);

			WM_DELETE_WINDOW = XInternAtom(mainDisplay, "WM_DELETE_WINDOW", False);

			int xi_opCode, event, error;
			immutable(char)* extName = "XInputExtension".ptr;
			if (XQueryExtension(mainDisplay, cast(char*)extName, &xi_opCode, &event, &error)) {
				import x11.extensions.XI;
				import x11.extensions.XInput;
				import x11.extensions.XI2;
				import x11.extensions.XInput2;
				int major = 2 , minor = 0;
				if (XIQueryVersion(mainDisplay, &major, &minor) == 0) {
					xinputAvail = true;
				}
			}
		}
		///Automatic cleanup.
		shared static ~this() {
			//XDestroyIC(ic);
			//XCloseIM(im);
			XDestroyWindow(mainDisplay, root);
			XCloseDisplay(mainDisplay);
		}
		debug public void testDraw(DrawParams params) @system nothrow {

		}
	}
	/** 
	 * Simply adds a window to the reference count
	 * Params:
	 *   hndl = handle to the window.
	 * Returns: 0 on success, 1 if handle already exists.
	 * Note: This function in theory should not throw, unless something goes really wrong.
	 */
	public static int addRef(WindowH hndl) {
		import std.algorithm.searching : count;
		//OSWindow newRef = new OSWindow(hndl);
		if (!count(refCount, hndl)) {
			refCount ~= new OSWindow(hndl);
			return 0;
		} else {
			return 1;
		}
	}
	public static OSWindow byRef(WindowH hndl) @nogc nothrow {
		foreach (OSWindow key; refCount) {
			if (hndl == key.windowHandle)
				return key;
		}
		return null;
	}
	/** 
	 * Creates an empty window. It can either be used by getting its handle and adding elements manually (not OS 
	 * agnostic), or by using it as an output surface.
	 * Params:
	 *   title = The title of the window, that can be seen on the titlebar if there's any.
	 *   name = The name of the window, that can be seen in other places. Might not be used on certain OSes.
	 *   x = X coordinate of the window.
	 *   y = Y coordinate of the window.
	 *   w = Width of the window.
	 *   h = Height of the window.
	 *   flags = Configuration flags.
	 *   icon = The icon of the window, if any.
	 *   parent = Parent if exists, null otherwise.
	 * Bugs:
	 *   (Windows) icon handling works as of now, but is preliminary and masking does not work. Future versions will
	 * feature better one, including live decompression.
	 */
	public this(string title, string name, int x, int y, int w, int h, uint flags,
			WindowBitmap icon = null, OSWindow parent = null) @trusted {
		this.flags = flags;
		this.icon = icon;
		version (Windows) {
			if (icon !is null) {
				HDC hdc = CreateCompatibleDC(null);
				ICONINFO iInfo;
				iInfo.fIcon = TRUE;
				uint[] pixels = cast(uint[])icon.pixels;
				iInfo.hbmColor = CreateBitmap(icon.width, icon.height, 1, 32, null);
				iInfo.hbmMask = CreateBitmap(icon.width, icon.height, 1, 1, null);
				SelectObject(hdc, iInfo.hbmColor);
				for (int iy ; iy < icon.height ; iy++) {
					for (int ix ; ix < icon.width ; ix++) {
						const pixel = pixels[iy * icon.width + ix]&0x00FFFFFF;
						SetPixel(hdc, ix, iy, (pixel>>16) | (pixel&0x00FF00) | ((pixel&0x0000ff)<<16));
					}
				}
				// Note: I cannot find a way to write the

				// SelectObject(hdc, iInfo.hbmMask);
				// for (int iy ; iy < icon.height ; iy++) {
					// for (int ix ; ix < icon.width ; ix++) {
						// const pixel = pixels[iy * icon.width + ix]>>24;
						// SetPixelV(hdc, ix, iy, pixel ? 0 : 0xFFFFFF);
					// }
				// }
				hIcon = CreateIconIndirect(&iInfo);
				DeleteObject(iInfo.hbmColor);
				DeleteObject(iInfo.hbmMask);
				DeleteDC(hdc);
			} else {
				hIcon = LoadIcon(null, IDI_APPLICATION);
			}
			classname = toUTF16z(name);
			registeredClass = WNDCLASSW(CS_HREDRAW | CS_VREDRAW | CS_OWNDC, &wndprocCallback, 0, 0, mainInst, 
					hIcon, LoadCursor(null, IDC_ARROW), GetSysColorBrush(COLOR_3DFACE), null, classname);
			regClResult = RegisterClassW(&registeredClass);
			if (!regClResult) {
				auto errorCode = GetLastError();
				throw new WindowCreationException("Failed to register window class!", errorCode);
			}
			DWORD dwStyle = WS_OVERLAPPEDWINDOW | WS_VISIBLE;
						
			if (x <= 0) x = CW_USEDEFAULT;
			if (y <= 0) y = CW_USEDEFAULT;
			if (w <= 0) w = CW_USEDEFAULT;
			// else if ((flags & WindowCfgFlags.NoDecorations) == 0) w += GetSystemMetrics(SM_CXSIZEFRAME);
			if (h <= 0) h = CW_USEDEFAULT;
			// else if ((flags & WindowCfgFlags.NoDecorations) == 0) h += GetSystemMetrics(SM_CYSIZEFRAME);
			RECT windowRect = RECT(0,0,w,h);
			AdjustWindowRect(&windowRect, dwStyle, FALSE);
			windowname = toUTF16z(title);
			HWND parentHndl = null;
			if (parent !is null)
				parentHndl = parent.getHandle();
			windowHandle = CreateWindowW(classname, windowname, dwStyle, x, y, windowRect.right - windowRect.left,
					windowRect.bottom - windowRect.top, parentHndl, null, mainInst, null);
			if (!windowHandle) {
				auto errorCode = GetLastError();
				throw new WindowCreationException("Failed to create window!", errorCode);
			}
			
			refCount ~= this;
			//SetLayeredWindowAttributes(windowHandle, 0, 0xFF, LWA_ALPHA);
			ShowWindow(windowHandle, SW_RESTORE);
			UpdateWindow(windowHandle);
		} else version(OSX) {
			CGRect frame = CGRect(CGPoint(x, y), CGSize(w, h));

			auto app = NSApp();
			app.setActivationPolicy(NSApplicationActivationPolicy.Regular);

			auto delegate_ = AppDelegate.alloc.initialize();
			NSApp.setDelegate(delegate_);

			// Create menubar and app menu
			NSMenu menubar = NSMenu.new_();
			NSMenuItem appMenuItem = NSMenuItem.new_();
			menubar.addItem(appMenuItem);
			NSApp.setMainMenu(menubar);

			NSMenu appMenu = NSMenu.new_();
			NSMenuItem quitMenuItem = NSMenuItem.alloc()
			    .initWithTitle("Quit".ns, sel_registerName("terminate:"), "q".ns);
			quitMenuItem.setTarget(app);
			quitMenuItem.setAction(sel_registerName("terminate:"));
			appMenu.addItem(quitMenuItem);
			appMenuItem.setSubmenu(appMenu);

			// Create and set up window
			nsWindow = NSWindow.alloc.initWithContentRect(
			    frame,
			    NSWindowStyleMask.Titled | NSWindowStyleMask.Closable |
			    NSWindowStyleMask.Miniaturizable | NSWindowStyleMask.Resizable,
			    NSBackingStoreType.Buffered,
			    NO
			);
	
			nsWindow.setTitle(title.ns);
			nsWindow.center();
			
			// contentView = NSView.alloc.initWithFrame(frame);
			// nsWindow.setContentView(contentView);

			// After contentView creation
			NSTrackingAreaOptions options = NSTrackingAreaOptions.ActiveAlways | 
			                               NSTrackingAreaOptions.MouseMoved |
			                               NSTrackingAreaOptions.MouseEnteredAndExited;
			NSTrackingArea trackingArea = NSTrackingArea.alloc.initWithRect(
			    contentView.bounds(),
			    options,
			    contentView,
			    null
			);
			contentView.addTrackingArea(trackingArea);


		    // Set up window and activation
			import iota.controls.polling : setCurrentWindow;		
	        nsWindow.makeKeyAndOrderFront(null);
	        NSApp.activateIgnoringOtherApps(YES);	
			setCurrentWindow(this);

			refCount ~= this;
		} else {
			string nameUTF8 = toUTF8(title);
			windowname = toStringz(nameUTF8);
			const int scr = DefaultScreen(mainDisplay);
			XSetWindowAttributes swa;
			swa.colormap = cmap;
			swa.event_mask = StructureNotifyMask | KeyPressMask | KeyReleaseMask |
					PointerMotionMask | ButtonPressMask | ButtonReleaseMask |
					ExposureMask | FocusChangeMask | VisibilityChangeMask |
					EnterWindowMask | LeaveWindowMask | PropertyChangeMask;
			swa.override_redirect = True;
			swa.border_pixel = BlackPixel(mainDisplay, scr);
			swa.background_pixel = WhitePixel(mainDisplay, scr);
			Window pH = root;
			if (parent !is null)
				pH = parent.windowHandle;


			windowHandle = XCreateWindow(mainDisplay, pH, x, y, w, h, 15, vInfo.depth, InputOutput, 
					vInfo.visual, CWBackPixel | CWColormap | CWBorderPixel | CWEventMask, &swa);
			XStoreName(mainDisplay, windowHandle, cast(char*)windowname);
			XSetWMProtocols(mainDisplay, windowHandle, &WM_DELETE_WINDOW, 1);
			refCount ~= this;
			im = XOpenIM(mainDisplay, null, null, null);
			ic = XCreateIC(im, XNInputStyle, XIMPreeditNothing | XIMStatusNothing, XNClientWindow, windowHandle, null);
			XMapWindow(mainDisplay, windowHandle);
		}
	}
	protected this(WindowH hndl) @nogc nothrow {
		windowHandle = hndl;
	}

	~this() {
	    version(Windows) {
	        if(glRenderingContext) wglDeleteContext(glRenderingContext);
	        DestroyWindow(windowHandle);
	        UnregisterClassW(classname, mainInst);
			DestroyIcon(hIcon);
	    } else version(OSX) {
	        if(nsWindow) {
	            nsWindow.release();
	            nsWindow = null;
	        }
	        if(contentView) {
	            contentView.release();
	            contentView = null;
	        }
	    } else {
	        if(glxContext) {
	            glXMakeCurrent(mainDisplay, None, null);
	            glXDestroyContext(mainDisplay, glxContext);
				glxContext = null;
	        }
	        if(ic) {
				XDestroyIC(ic);
				ic = null;
			}
	        if(im) {
				XCloseIM(im);
				im = null;
			}
			XSync(mainDisplay, False);
			if (windowHandle) {
		        XDestroyWindow(mainDisplay, windowHandle);
				windowHandle = 0;
			}
			XFlush(mainDisplay);
	    }
	}
	/**
	 * Compares two classes to each other.
	 */
	public bool opEquals(OSWindow rhs) const @nogc @safe pure nothrow {
		return windowHandle == rhs.windowHandle;
	}
	/**
	 * Compares a class to a Window handle.
	 */
	public bool opEquals(WindowH rhs) const @nogc @safe pure nothrow {
		return windowHandle == rhs;
	}
	///Just to make the scanner happy...
	public override size_t toHash() const @nogc @safe pure nothrow {
		version (OSX) {
			return 0xf456; // Just random number, otherwise we get and error on OSX
		} else {
			return cast(size_t)windowHandle;
		}
	}
	/**  
	 * Returns the handle of this window.
	 */
	public WindowH getHandle() @nogc @safe pure nothrow {
		return windowHandle;
	}
	///Note to end user: DO NOT USE! IT IS MADE PUBLIC DUE TO ANOTHER PACKAGE NEEDING IT!
	///Returns the last window event code, then clears the variable that stored it.
	public Status getWindowStatus() @nogc @safe pure nothrow {
		Status result = status;
		status = Status.init;
		return result;
	}
	/**
	 * Manually maximizes the window from code.
	 */
	public void maximizeWindow() @nogc nothrow @trusted {
		version (Windows) {
			ShowWindow(windowHandle, SW_MAXIMIZE);
		}
	}
	/**
	 * Manually minimizes the window from code.
	 */
	public void minimizeWindow() @nogc nothrow @trusted {
		version (Windows) {
			ShowWindow(windowHandle, SW_MINIMIZE);
		}
	}
	/**
	 * Moves and resizes the window.
	 * Params:
	 *   x = X coordinate on the screen.
	 *   y = Y coordinate on the screen.
	 *   w = Width of the active area of the window.
	 *   h = Height of the active area of the window.
	 */
	 public void moveWindow(int x, int y, int w, int h) @nogc nothrow @trusted {
	     version(Windows) {
	         MoveWindow(windowHandle, x, y, w, h, TRUE);
	     } else version(OSX) {
	         CGRect frame = CGRect(CGPoint(x, y), CGSize(w, h));
	         nsWindow.setFrame(frame, YES);
	     } else {
	         XMoveResizeWindow(mainDisplay, windowHandle, x, y, w, h);
	     }
	 }
	/**
	 * Returns an array, of which the first two elements are the top-left coordinates 
	 * of the window, and the last two elements are the size of the active area of the
	 * window.
	 */
	 public int[4] getWindowPosition() @nogc nothrow @trusted {
	    version(Windows) {
	        RECT windowSize;
	        GetWindowRect(windowHandle, &windowSize);
	        return [windowSize.left, windowSize.top, windowSize.right - windowSize.left + 1, 
	                windowSize.bottom - windowSize.top + 1];
	    } else version(OSX) {
	        CGRect frame = nsWindow.frame();
	        return [cast(int)frame.origin.x, cast(int)frame.origin.y, 
	                cast(int)frame.size.width, cast(int)frame.size.height];
	    } else {
	        XWindowAttributes winattr;
	        XGetWindowAttributes(mainDisplay, windowHandle, &winattr);
	        return [winattr.x, winattr.y, winattr.width, winattr.height];
	    }
	}
	/**
	 * Sets the window to the given screen mode.
	 * If `display` is not -1, then it selects a specific display, otherwise it uses the default one.
	 * `mode` can be either the index of a screen mode, or a value defined by `DisplayMode`
	 * Returns: 0 on success, or a specific error code on error.
	 * To Do: Get some info on how one exits the fullscreen mode on x11.
	 */
	public int setScreenMode(int display, int mode) @nogc nothrow @system {
		version (Windows) {
			LONG errorcode;
			switch (mode) {
			case DisplayMode.Windowed:
				/* LPCSTR devicename = null;
				if (display >= 0) devicename = cast(LPCSTR)screenModes[display][0].dmDeviceName.ptr;
				errorcode = ChangeDisplaySettingsExA(devicename, null, null, 0, null); */
				SetWindowLongA(windowHandle, GWL_EXSTYLE, 0);
				SetWindowLongA(windowHandle, GWL_STYLE, WS_OVERLAPPEDWINDOW | WS_VISIBLE);
				SetWindowPos(windowHandle, HWND_TOPMOST, prevVals[0], prevVals[1], prevVals[2], prevVals[3], SWP_SHOWWINDOW);
				errorcode = ChangeDisplaySettingsA(null, 0);
				ShowWindow(windowHandle, SW_NORMAL);
				break;
			case DisplayMode.FullscreenDesktop:
				/* LPCSTR devicename = null;
				if (display >= 0) devicename = cast(LPCSTR)screenModes[display][0].dmDeviceName.ptr;
				errorcode = ChangeDisplaySettingsExA(devicename, null, null, CDS_FULLSCREEN, null); */
				prevVals = getWindowPosition();
				DEVMODEA currDesktopSetting;
				EnumDisplaySettingsA(null, ENUM_CURRENT_SETTINGS, &currDesktopSetting);
				SetWindowLongA(windowHandle, GWL_EXSTYLE, WS_EX_APPWINDOW | WS_EX_TOPMOST);
				SetWindowLongA(windowHandle, GWL_STYLE, WS_POPUP | WS_VISIBLE);
				SetWindowPos(windowHandle, HWND_TOPMOST, 0, 0, currDesktopSetting.dmPelsWidth, currDesktopSetting.dmPelsHeight, 
						SWP_SHOWWINDOW);
				errorcode = ChangeDisplaySettingsA(&currDesktopSetting, CDS_FULLSCREEN);
				ShowWindow(windowHandle, SW_MAXIMIZE);
				break;
			default:
				prevVals = getWindowPosition();
				if (display <= -1) return 1;
				if (display >= screenModes.length) return 2;
				if (mode >= screenModes[display].length) return 3;
				DEVMODEA devicemode = screenModes[display][mode];
				SetWindowLongA(windowHandle, GWL_EXSTYLE, WS_EX_APPWINDOW | WS_EX_TOPMOST);
				SetWindowLongA(windowHandle, GWL_STYLE, WS_POPUP | WS_VISIBLE);
				SetWindowPos(windowHandle, HWND_TOPMOST, 0, 0, devicemode.dmPelsWidth, devicemode.dmPelsHeight, SWP_SHOWWINDOW);
				errorcode = ChangeDisplaySettingsA(&devicemode, CDS_FULLSCREEN);
				ShowWindow(windowHandle, SW_MAXIMIZE);
				break;
			}
			return cast(int)errorcode;
		} else version (OSX) {
		    switch(mode) {
		        case DisplayMode.Windowed:
		            nsWindow.setStyleMask(NSWindowStyleMask.Titled | NSWindowStyleMask.Closable | 
		                NSWindowStyleMask.Miniaturizable | NSWindowStyleMask.Resizable);
		            nsWindow.setFrame(CGRect(CGPoint(prevVals[0], prevVals[1]), 
		                CGSize(prevVals[2], prevVals[3])), YES);
		            return 0;

		        case DisplayMode.FullscreenDesktop:
		            prevVals = getWindowPosition();
		            nsWindow.toggleFullScreen(null);
		            return 0;

		        default:
		            return 1;
		    }
		} else {
			Atom windowType = XInternAtom (mainDisplay, "_NET_WM_WINDOW_TYPE_NORMAL", True);
			XEvent ev;
			Hints hint;
			Atom[10] x11_AllowedActions, x11_State;
        	uint x11_AllowedActionsCount, x11_StateCount;
			switch (mode) {
			case DisplayMode.Windowed:
				
				hint = Hints(0x03, 0x01, 0x01, 0, 0);

				XDeleteProperty(mainDisplay, windowHandle, XInternAtom(mainDisplay, "_NET_WM_ACTION_FULLSCREEN", True));
				XDeleteProperty(mainDisplay, windowHandle, XInternAtom(mainDisplay, "_NET_WM_ACTION_ABOVE", True));
				XDeleteProperty(mainDisplay, windowHandle, XInternAtom(mainDisplay, "_NET_WM_STATE_FULLSCREEN", True));
				XDeleteProperty(mainDisplay, windowHandle, XInternAtom(mainDisplay, "_NET_WM_STATE_ABOVE", True));

				x11_AllowedActions[x11_AllowedActionsCount++] = XInternAtom(mainDisplay, "_NET_WM_ACTION_MOVE", True);
                x11_AllowedActions[x11_AllowedActionsCount++] = XInternAtom(mainDisplay, "_NET_WM_ACTION_RESIZE", True);
                x11_AllowedActions[x11_AllowedActionsCount++] = XInternAtom(mainDisplay, "_NET_WM_ACTION_CLOSE", True);
                x11_AllowedActions[x11_AllowedActionsCount++] = XInternAtom(mainDisplay, "_NET_WM_ACTION_MINIMIZE", 
						True);
                x11_AllowedActions[x11_AllowedActionsCount++] = XInternAtom(mainDisplay, "_NET_WM_ACTION_MAXIMIZE_HORZ", 
						True);
                x11_AllowedActions[x11_AllowedActionsCount++] = XInternAtom(mainDisplay, "_NET_WM_ACTION_MAXIMIZE_VERT", 
						True);

				ev.type = ClientMessage;
				ev.xclient.window = windowHandle;
				ev.xclient.message_type = XInternAtom (mainDisplay, "_NET_WM_STATE", True);
				ev.xclient.format = 32;
				ev.xclient.data.l[0] = 0;
				ev.xclient.data.l[1] = XInternAtom(mainDisplay, "_NET_WM_STATE_FULLSCREEN", True);
				ev.xclient.data.l[2] = 0;

				break;
			case DisplayMode.FullscreenDesktop:
				prevVals = getWindowPosition();

				hint = Hints(0x03, 0, 0, 0, 0);

				x11_AllowedActions[x11_AllowedActionsCount++] = XInternAtom(mainDisplay, "_NET_WM_ACTION_FULLSCREEN", True);
				x11_AllowedActions[x11_AllowedActionsCount++] = XInternAtom(mainDisplay, "_NET_WM_ACTION_ABOVE", True);

				x11_State[x11_StateCount++] = XInternAtom(mainDisplay, "_NET_WM_STATE_FULLSCREEN", True);
				x11_State[x11_StateCount++] = XInternAtom(mainDisplay, "_NET_WM_STATE_ABOVE", True);

				XSizeHints sizeHints;
				sizeHints.flags = PMinSize | PMaxSize;

				sizeHints.min_width = 0;
				sizeHints.max_width = int.max;
				sizeHints.min_height = 0;
				sizeHints.max_height = int.max;

				XSetWMNormalHints(mainDisplay, windowHandle, &sizeHints);
				
				
				
				
				ev.type = ClientMessage;
				ev.xclient.window = windowHandle;
				ev.xclient.message_type = XInternAtom (mainDisplay, "_NET_WM_STATE", True);
				ev.xclient.format = 32;
				ev.xclient.data.l[0] = 1;
				ev.xclient.data.l[1] = XInternAtom(mainDisplay, "_NET_WM_STATE_FULLSCREEN", True);
				ev.xclient.data.l[2] = 0;

				
				break;
			default:
				return 5;
			}
			Atom motifWindowHintsAtom = XInternAtom(mainDisplay, "_MOTIF_WM_HINTS", True);
			if (motifWindowHintsAtom != None) {
				XChangeProperty(mainDisplay, windowHandle, motifWindowHintsAtom, motifWindowHintsAtom, 32, PropModeReplace, 
						cast(ubyte*)&hint, 5);
			}
			Atom xaAtom = XInternAtom(mainDisplay, "XA_ATOM", True);
			if (xaAtom != None) {
				Atom allowedActionsAtom = XInternAtom(mainDisplay, "_NET_WM_ALLOWED_ACTIONS", True);
				if (allowedActionsAtom != None) {
					XChangeProperty(mainDisplay, windowHandle, allowedActionsAtom, xaAtom, 32, PropModeReplace, 
							cast(ubyte*)x11_AllowedActions.ptr, x11_AllowedActionsCount);
				}

				Atom stateAtom = XInternAtom(mainDisplay, "_NET_WM_STATE", True);
				if (stateAtom != None) {
					XChangeProperty(mainDisplay, windowHandle, stateAtom, xaAtom, 32, PropModeReplace, cast(ubyte*)x11_State.ptr, 
							x11_StateCount);
				}
			}
			XMapWindow(mainDisplay, windowHandle);
			XSendEvent(mainDisplay, root, False, SubstructureRedirectMask | SubstructureNotifyMask, &ev);
				
			XFlush(mainDisplay);
			return 0;
		}
	}
	public ScreenMode setScreenMode(ScreenMode mode) @nogc nothrow @system {
		import std.math;
		version (Windows) {
			LONG errorcode;
			DEVMODEA currDesktopSetting;
			EnumDisplaySettingsA(null, ENUM_CURRENT_SETTINGS, &currDesktopSetting);
			currDesktopSetting.dmPelsWidth = mode.width;
			currDesktopSetting.dmPelsHeight = mode.height;
			currDesktopSetting.dmDisplayFrequency = cast(DWORD)nearbyint(mode.refreshRate);
			SetWindowLongA(windowHandle, GWL_EXSTYLE, WS_EX_APPWINDOW | WS_EX_TOPMOST);
			SetWindowLongA(windowHandle, GWL_STYLE, WS_POPUP | WS_VISIBLE);
			SetWindowPos(windowHandle, HWND_TOPMOST, 0, 0, currDesktopSetting.dmPelsWidth, currDesktopSetting.dmPelsHeight, 
					SWP_SHOWWINDOW);
			errorcode = ChangeDisplaySettingsA(&currDesktopSetting, CDS_FULLSCREEN);
			ShowWindow(windowHandle, SW_MAXIMIZE);
		}
		return ScreenMode.init;
	}
	public void setCursor(StandardCursors cursor) @nogc nothrow @trusted {
		version (Windows) {
			final switch (cursor) with (StandardCursors) {
			case Arrow:
				winCursor = LoadCursorW(NULL, IDC_ARROW);
				break;
			case TextSelect:
				winCursor = LoadCursorW(NULL, IDC_IBEAM);
				break;
			case Busy:
				winCursor = LoadCursorW(NULL, IDC_WAIT);
				break;
			case PrecisionSelect:
				winCursor = LoadCursorW(NULL, IDC_CROSS);
				break;
			case AltSelect:
				winCursor = LoadCursorW(NULL, IDC_UPARROW);
				break;
			case ResizeTopRight, ResizeBottomLeft:
				winCursor = LoadCursorW(NULL, IDC_SIZENESW);
				break;
			case ResizeTopLeft, ResizeBottomRight:
				winCursor = LoadCursorW(NULL, IDC_SIZENWSE);
				break;
			case ResizeTop, ResizeBottom, ResizeVert:
				winCursor = LoadCursorW(NULL, IDC_SIZENS);
				break;
			case ResizeLeft, ResizeRight, ResizeHoriz:
				winCursor = LoadCursorW(NULL, IDC_SIZEWE);
				break;
			case Move:
				winCursor = LoadCursorW(NULL, IDC_SIZEALL);
				break;
			case Forbidden:
				winCursor = LoadCursorW(NULL, IDC_NO);
				break;
			case Hand:
				winCursor = LoadCursorW(NULL, IDC_HAND);
				break;
			case WaitArrow:
				winCursor = LoadCursorW(NULL, IDC_APPSTARTING);
				break;
			case HelpSelect:
				winCursor = LoadCursorW(NULL, IDC_HELP);
				break;
			case LocationSelect:
				winCursor = LoadCursorW(NULL, MAKEINTRESOURCE_T!(32_671));
				break;
			case PersonSelect:
				winCursor = LoadCursorW(NULL, MAKEINTRESOURCE_T!(32_672));
				break;
			}
			/* SetCursor(winCursor);
			SetClassLongW(windowHandle, GCL_HCURSOR, cast(DWORD)winCursor);
			ShowCursor(TRUE); */
	    } else version(OSX) {
	        NSCursor systemCursor;
			final switch(cursor) with(StandardCursors) {
				case Arrow: 
	                NSCursor.arrowCursor().set(); break;
	            case TextSelect: 
	                NSCursor.IBeamCursor().set(); break;
	            case Busy:
	            case WaitArrow:
	                NSCursor.operationNotAllowedCursor().set(); break;
	            case PrecisionSelect:
	                NSCursor.crosshairCursor().set(); break;
	            case AltSelect:
	            case HelpSelect:
	                NSCursor.contextualMenuCursor().set(); break;
	            case ResizeTopLeft:
				    NSCursor.windowResizeNorthWestSouthEastCursor().set(); break;
	            case ResizeTopRight:
				    NSCursor.windowResizeNorthEastSouthWestCursor().set(); break;
	            case ResizeBottomLeft:
				    NSCursor.windowResizeNorthWestSouthEastCursor().set(); break;
	            case ResizeBottomRight:
				    NSCursor.windowResizeNorthEastSouthWestCursor().set(); break;
	            case ResizeLeft:
	                NSCursor.resizeLeftCursor().set(); break;
	            case ResizeRight:
	                NSCursor.resizeRightCursor().set(); break;
	            case ResizeHoriz:
	                NSCursor.resizeLeftRightCursor().set(); break;
	            case ResizeTop:
	                NSCursor.resizeUpCursor().set(); break;
	            case ResizeBottom:
	                NSCursor.resizeDownCursor().set(); break;
	            case ResizeVert:
	                NSCursor.resizeUpDownCursor().set(); break;
	            case Move:
	                NSCursor.openHandCursor().set(); break;
	            case Forbidden:
	                NSCursor.operationNotAllowedCursor().set(); break;
	            case Hand:
	            case LocationSelect:
	            case PersonSelect:
	                NSCursor.pointingHandCursor().set(); break;
			}
	        systemCursor.set();
		} else {
			Cursor x11_cursor;
			final switch (cursor) with (StandardCursors) {
			case Arrow:
				x11_cursor = XCreateFontCursor(mainDisplay, XC_left_ptr);
				break;
			case TextSelect:
				x11_cursor = XCreateFontCursor(mainDisplay, XC_xterm);
				break;
			case Busy:
				x11_cursor = XCreateFontCursor(mainDisplay, XC_watch);
				break;
			case PrecisionSelect:
				x11_cursor = XCreateFontCursor(mainDisplay, XC_crosshair);
				break;
			case AltSelect:
				x11_cursor = XCreateFontCursor(mainDisplay, XC_center_ptr);
				break;
			case ResizeTopLeft:
				x11_cursor = XCreateFontCursor(mainDisplay, XC_top_left_corner);
				break;
			case ResizeTopRight:
				x11_cursor = XCreateFontCursor(mainDisplay, XC_top_right_corner);
				break;
			case ResizeBottomLeft:
				x11_cursor = XCreateFontCursor(mainDisplay, XC_bottom_left_corner);
				break;
			case ResizeBottomRight:
				x11_cursor = XCreateFontCursor(mainDisplay, XC_bottom_right_corner);
				break;
			case ResizeLeft:
				x11_cursor = XCreateFontCursor(mainDisplay, XC_left_side);
				break;
			case ResizeRight:
				x11_cursor = XCreateFontCursor(mainDisplay, XC_right_side);
				break;
			case ResizeTop:
				x11_cursor = XCreateFontCursor(mainDisplay, XC_top_side);
				break;
			case ResizeBottom:
				x11_cursor = XCreateFontCursor(mainDisplay, XC_bottom_side);
				break;
			case Move:
				x11_cursor = XCreateFontCursor(mainDisplay, XC_fleur);
				break;
			case Forbidden:
				x11_cursor = XCreateFontCursor(mainDisplay, XC_X_cursor);
				break;
			case Hand:
				x11_cursor = XCreateFontCursor(mainDisplay, XC_hand2 );
				break;
			case WaitArrow:
				x11_cursor = XCreateFontCursor(mainDisplay, XC_clock);
				break;
			case HelpSelect:
				x11_cursor = XCreateFontCursor(mainDisplay, XC_question_arrow);
				break;
			case LocationSelect:
				x11_cursor = XCreateFontCursor(mainDisplay, XC_arrow);
				break;
			case PersonSelect:
				x11_cursor = XCreateFontCursor(mainDisplay, XC_man);
				break;
			case ResizeHoriz:
				x11_cursor = XCreateFontCursor(mainDisplay, XC_sb_h_double_arrow);
				break;
			case ResizeVert:
				x11_cursor = XCreateFontCursor(mainDisplay, XC_sb_v_double_arrow);
			}
			XDefineCursor(mainDisplay, windowHandle, x11_cursor);
		}
	}
	/**
	 * Creates, then returns the OpenGL handle associated with the window.
	 */
	public void* getOpenGLHandle() @nogc nothrow @trusted {
		version (Windows) {
			if (glRenderingContext) return glRenderingContext;
			windowDeviceContext = GetDC(windowHandle);
			PIXELFORMATDESCRIPTOR pfd = PIXELFORMATDESCRIPTOR(cast(WORD)PIXELFORMATDESCRIPTOR.sizeof, 1, 
					PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER, PFD_TYPE_RGBA, 32, 
					0,0,0,0,0,0,
					0,0,0,
					0,0,0,0,
					24,8,0,PFD_MAIN_PLANE,0,0,0,0);
			int pixelFormatNum = ChoosePixelFormat(windowDeviceContext, &pfd);
			SetPixelFormat(windowDeviceContext, pixelFormatNum, &pfd);

			glRenderingContext = wglCreateContext(windowDeviceContext);
			wglMakeCurrent(windowDeviceContext, glRenderingContext);
			return glRenderingContext;
		} else version(OSX) {
	        if (!glContext) {
	            static immutable int[] attrs = [
	                NSOpenGLPFADoubleBuffer,
	                NSOpenGLPFAColorSize, 24,
	                NSOpenGLPFAAlphaSize, 8,
	                NSOpenGLPFADepthSize, 24,
	                NSOpenGLPFAStencilSize, 8,
	                0
	            ];

	            pixelFormat = NSOpenGLPixelFormat.alloc.initWithAttributes(attrs.ptr);
	            glContext = NSOpenGLContext.alloc.initWithFormat(pixelFormat, null);

	            const int swapInterval = 1;
	            glContext.setValues(&swapInterval, NSOpenGLContextParameter.NSOpenGLCPSwapInterval);

	            NSView contentView = getNSWindow().contentView();
	            glContext.setView(contentView);
	        }

	        glContext.makeCurrentContext();
	        return cast(void*)glContext;
		} else {
			if (glxContext) return glxContext;
			glxContext = glXCreateContext(mainDisplay, vInfo, null, GL_TRUE);
			glXMakeCurrent(mainDisplay, windowHandle, glxContext);
			return glxContext;
		}
	}
	public void* getOpenGLHandleAttribsARB(const(int)[] attribList) @nogc nothrow @trusted {
		assert(attribList[$ - 1] == 0, "Missing closing null value");
		version (Windows) {
			if (glAttribARBDone) return glRenderingContext;
			if (!glRenderingContext) getOpenGLHandle();
			wglCreateContextAttribsARB = cast(PFNWGLCREATECONTEXTATTRIBSARBPROC)wglGetProcAddress("wglCreateContextAttribsARB");
			wglDeleteContext(glRenderingContext);
			glRenderingContext = null;
			if (wglCreateContextAttribsARB is null) return null;
			windowDeviceContext = GetDC(windowHandle);
			PIXELFORMATDESCRIPTOR pfd = PIXELFORMATDESCRIPTOR(cast(WORD)PIXELFORMATDESCRIPTOR.sizeof, 1,
					PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER, PFD_TYPE_RGBA, 32,
					0,0,0,0,0,0,
					0,0,0,
					0,0,0,0,
					24,8,0,PFD_MAIN_PLANE,0,0,0,0);
			int pixelFormatNum = ChoosePixelFormat(windowDeviceContext, &pfd);
			SetPixelFormat(windowDeviceContext, pixelFormatNum, &pfd);

			glRenderingContext = wglCreateContextAttribsARB(windowDeviceContext, null, attribList.ptr);
			wglMakeCurrent(windowDeviceContext, glRenderingContext);
			glAttribARBDone = true;
			return glRenderingContext;
		} else version(OSX) {
			return null;
		} else {
			if (glxContext) return glxContext;
			glxContext = glXCreateContextAttribsARB(mainDisplay, vInfo, null, GL_TRUE, attribList.ptr);
			glXMakeCurrent(mainDisplay, windowHandle, glxContext);
			return glxContext;
		}
	}
	public void gl_swapBuffers() @nogc nothrow @trusted {
		version (Windows) {
			SwapBuffers(windowDeviceContext);
		} else version(OSX) {
			(cast(NSOpenGLContext)getOpenGLHandle()).flushBuffer();
		} else glXSwapBuffers(mainDisplay, windowHandle);
	}
	public void gl_makeCurrent() @nogc nothrow @trusted {
		version (Windows) {
			wglMakeCurrent(windowDeviceContext, glRenderingContext);
		} else version (OSX) {
			(cast(NSOpenGLContext)getOpenGLHandle()).makeCurrentContext();
		}
		else glXMakeCurrent(mainDisplay, windowHandle, glxContext);
	}
	/**
	 * Returns the current input language code. (Linux UNIMPLEMENTED)
	 */
	public uint getInputLangCode() @nogc nothrow const {
		version (Windows)
			return inputLang;
		else version(OSX)
        	return NSTextInputContext.currentInputContext().selectedKeyboardInputSource().intValue();
		else
			return 0;
	}

	public void processEvents() @nogc nothrow {
	    version(OSX) {
	        NSEvent event = NSApplication.sharedApplication().nextEventMatchingMask(
	            NSEventMaskAny,
	            NSDate.distantPast(),
	            "kCFRunLoopDefaultMode".ns,
	            true
	        );
	
	        if (event !is null) {
	            NSApplication.sharedApplication().sendEvent(event);
	        }
	    }
	}

	/** 
	 * Callback function for windowing. Can be overridden to process more messages than by default.
	 * See Microsoft documentation for details on return value and parameters.
	 */
	version (Windows)
	protected LRESULT wndCallback(UINT msg, WPARAM wParam, LPARAM lParam) nothrow @system {
		switch (msg) {
			case WM_NCACTIVATE:
				goto default;//return FALSE;
			case WM_DESTROY, WM_NCDESTROY:
				return 0;
			case WM_CLOSE:
				status = Status.Quit;
				lastInputEvent.handle = this.windowHandle;
				lastInputEvent.type = InputEventType.WindowClose;
				return 0;
			case WM_QUIT:
				status = Status.Quit;
				goto default;
			case WM_MOVE, WM_MOVING:
				status = Status.Move;
				with (lastInputEvent) {
					handle = this.windowHandle;
					type = InputEventType.WindowMove;
					window.x = cast(short)LOWORD(lParam);
					window.y = cast(short)HIWORD(lParam);
					window.width = 0;
					window.height = 0;
				}
				goto default;
			case WM_SIZE, WM_SIZING:
				status = Status.Resize;
				with (lastInputEvent) {
					handle = this.windowHandle;
					type = InputEventType.WindowResize;
					window.x = 0;
					window.y = 0;
					window.width = LOWORD(lParam);
					window.height = HIWORD(lParam);
				}
				goto default;
			case WM_SETCURSOR:
				if (LOWORD(lParam) == HTCLIENT && winCursor != NULL) {
					SetCursor(winCursor);
					return TRUE;
				}
				//return FALSE;
				goto default;
			case WM_INPUTLANGCHANGEREQUEST, WM_INPUTLANGCHANGE:
				status = Status.InputLangCh;
				inputLang = cast(uint)lParam;
				with (lastInputEvent) {
					handle = this.windowHandle;
					type = InputEventType.InputLangChange;
					rawData[0] = inputLang;
				}
				goto default;
			case WM_PAINT:
				if (drawDeleg !is null) {
					drawDeleg(DrawParams(windowHandle, msg, wParam, lParam));
				} else {
					PAINTSTRUCT ps;
        			BeginPaint(windowHandle, &ps);
        			EndPaint(windowHandle, &ps);
				}
				goto default;
			case WM_SYSCOMMAND:
				if (wParam == SC_KEYMENU && (flags & WindowCfgFlags.IgnoreMenuKey)) return 0;
				goto default;
			default:
				return DefWindowProcW(windowHandle, msg, wParam, lParam);
		}
	}
}

