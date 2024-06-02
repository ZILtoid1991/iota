module iota.window.oswindow;

version (Windows) {
	import core.sys.windows.windows;
	import core.sys.windows.wtypes;
	import core.sys.windows.commctrl;
	import std.conv : to;
	/* enum STAP_ALLOW_NONCLIENT = 1<<0;
	enum STAP_ALLOW_CONTROLS = 1<<1;
	enum STAP_ALLOW_WEBCONTENT = 1<<2;
	extern (Windows) nothrow @nogc {
		void SetThemeAppProperties(DWORD dwFlags);
	} */
	
} else {
	import x11.Xlib;
	import x11.X;
	import x11.Xresource;
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
	///Contains various statuscodes of the window.
	protected Status			status;
	///Stores various flags related to the window.
	protected ushort			flags;
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
				/+case WM_NCCREATE:
					DefWindowProcW(windowHandle, msg, wParam, lParam);+/
				default:
					foreach (OSWindow key; refCount) {
						if (key.getHandle() == hWnd)
							return key.wndCallback(msg, wParam, lParam);
					}
					return LRESULT.init;
			}
		}
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
		WNDCLASSEXW* registeredClass;
		protected ATOM				regClResult;
		protected LPCWSTR			classname, windowname;
		protected HGLRC				glRenderingContext;
		///hInstance is stored here, which is needed for window creation, etc.
		///NOTE: This is Windows exclusive, and won't be accessable under other OSes.
		public static HINSTANCE		mainInst;
		///The current input language code (Windows).
		package static uint			inputLang;
		shared static this() {
			//NOTE: This is not the proper way of doing stuff like this.
			//However, this way we can possibly eliminate the need for use of `WinMain` and might also piss off some
			//people at Microsoft.
			mainInst = GetModuleHandle(null);

			INITCOMMONCONTROLSEX cctrl;
			cctrl.dwICC = 0x0000_ffff;
			assert(InitCommonControlsEx(&cctrl) == TRUE);
			/* SetThemeAppProperties(0x7); */
		}
	} else {
		public static Display* mainDisplay;
		public static Window root;
		public XIM im;
		public XIC ic;
		protected immutable(char)* windowname;
		protected XSetWindowAttributes attr;
		/**
		 * Initializes X11.
		 */
		shared static this() {
			mainDisplay = XOpenDisplay(null);
			root = XRootWindow(mainDisplay, DefaultScreen(mainDisplay));
			//XSelectInput();
			//im = XOpenIM(mainDisplay, null, null, null);
			/* assert(im !is null, "Input method couldn't be opened!");
			ic = XCreateIC(im); */
		}
		///Automatic cleanup.
		shared static ~this() {
			/* XDestroyIC(ic); */
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
	 *   flags = Configuration flags. Bit 0-31: Window style flags, bit 32-47: Output surface configuration
	 *   icon = The icon of the window, if any.
	 *   menu = The menubar of the window, if any.
	 *   parent = Parent if exists, null otherwise.
	 */
	public this(io_str_t title, io_str_t name, int x, int y, int w, int h, ulong flags,
			WindowBitmap icon = null, OSWindow parent = null) {
		version (Windows) {
			
			classname = toUTF16z(name);
			registeredClass = new WNDCLASSEXW(WNDCLASSEXW.sizeof, CS_HREDRAW | CS_VREDRAW | CS_OWNDC, 
					&wndprocCallback, 0, 0, mainInst, LoadIcon(null, IDI_APPLICATION), LoadCursor(null, IDC_ARROW), 
					GetSysColorBrush(COLOR_APPWORKSPACE), null, classname, null);
			/* registeredClass.style = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
			registeredClass.hInstance = mainInst;
			registeredClass.lpfnWndProc = &wndprocCallback;
			registeredClass.hbrBackground = GetSysColorBrush(COLOR_3DFACE);
			registeredClass.hCursor = LoadCursor(null, IDC_ARROW);
			registeredClass.hIcon = LoadIcon(null, IDI_APPLICATION);
			registeredClass.lpszClassName = classname; */
			regClResult = RegisterClassExW(registeredClass);
			if (!regClResult) {
				auto errorCode = GetLastError();
				throw new WindowCreationException("Failed to register window class!", errorCode);
			}
			DWORD dwStyle = WS_OVERLAPPEDWINDOW | WS_VISIBLE, dwExStyle = WS_EX_APPWINDOW;
			/*if (flags & WindowStyleIDs.Border)
				dwStyle |= WS_BORDER;
			if (flags & WindowStyleIDs.Caption)
				dwStyle |= WS_CAPTION;
			if (flags & WindowStyleIDs.Child)
				dwStyle |= WS_CHILD;
			if (flags & WindowStyleIDs.Disabled)
				dwStyle |= WS_DISABLED;
			if (flags & WindowStyleIDs.Resizable)
				dwStyle |= WS_THICKFRAME;
			if (flags & WindowStyleIDs.Maximized)
				dwStyle |= WS_MAXIMIZE;
			if (flags & WindowStyleIDs.Minimized)
				dwStyle |= WS_MINIMIZE;
			if (flags & WindowStyleIDs.MaximizeBtn)
				dwStyle |= WS_MAXIMIZEBOX | WS_SYSMENU;
			if (flags & WindowStyleIDs.MinimizeBtn)
				dwStyle |= WS_MINIMIZEBOX | WS_SYSMENU;
			if (flags & WindowStyleIDs.PopUp)
				dwStyle |= WS_POPUPWINDOW;
			if (flags & WindowStyleIDs.Visible)
				dwStyle |= WS_VISIBLE;
			if (flags & WindowStyleIDs.Default)
				dwStyle |= WS_TILEDWINDOW | WS_VISIBLE;
			if (flags & WindowStyleIDs.AppWindow)
				dwExStyle |= WS_EX_APPWINDOW;
			if (flags & WindowStyleIDs.DragNDrop)
				dwExStyle |= WS_EX_ACCEPTFILES;
			if (flags & WindowStyleIDs.ContextHelp)
				dwExStyle |= WS_EX_CONTEXTHELP; */
			
			if (x <= 0) x = CW_USEDEFAULT;
			if (y <= 0) y = CW_USEDEFAULT;
			if (w <= 0) w = CW_USEDEFAULT;
			if (h <= 0) h = CW_USEDEFAULT;
			windowname = toUTF16z(title);
			HWND parentHndl = null;
			if (parent !is null)
				parentHndl = parent.getHandle();
			/* windowHandle = CreateWindowExW(dwExStyle, classname, windowname, dwStyle, x, y, w, h, parentHndl, null, mainInst, 
					null); */
			windowHandle = CreateWindowW(classname, windowname, dwStyle, x, y, w, h, parentHndl, null, mainInst, 
					null);
			if (!windowHandle) {
				auto errorCode = GetLastError();
				throw new WindowCreationException("Failed to create window!", errorCode);
			}
			/* NONCLIENTMETRICSW ncm;
			ncm.cbSize = NONCLIENTMETRICSW.sizeof;
			SystemParametersInfoW(SPI_GETNONCLIENTMETRICS, NONCLIENTMETRICSW.sizeof, &ncm, 0);
			HFONT hFont = CreateFontIndirectW(&ncm.lfMessageFont);
			SendMessageW(windowHandle, WM_SETFONT, cast(WPARAM)hFont, TRUE); */

			refCount ~= this;
			//SetLayeredWindowAttributes(windowHandle, 0, 0xFF, LWA_ALPHA);
			ShowWindow(windowHandle, SW_RESTORE);
			UpdateWindow(windowHandle);
		} else {
			string nameUTF8 = toUTF8(title);
			windowname = toStringz(nameUTF8);
			Window pH = root;
			if (parent !is null)
				pH = parent.windowHandle;
			const int scr = DefaultScreen(mainDisplay);
			/* windowHandle = XCreateWindow(mainDisplay, pH, x, y, w, h, 15, CopyFromParent, 
			((flags & WindowStyleIDs.Visible) ? InputOutput : InputOnly), cast(Visual*)CopyFromParent, 0, &attr); */
			windowHandle = XCreateSimpleWindow(mainDisplay, pH, x, y, w, h, 1,
					BlackPixel(mainDisplay, scr), WhitePixel(mainDisplay, scr));
			XStoreName(mainDisplay, windowHandle, cast(char*)windowname);
			XSelectInput(mainDisplay, windowHandle, 0x01_ff_ff_ff);
			im = XOpenIM(mainDisplay, null, null, null);
			ic = XCreateIC(im, XNInputStyle, XIMPreeditNothing | XIMStatusNothing, XNClientWindow, windowHandle, null);
			XMapWindow(mainDisplay, windowHandle);
		}
	}
	protected this(WindowH hndl) {
		windowHandle = hndl;
	}

	~this() {
		version (Windows) {
			if (glRenderingContext) wglDeleteContext(glRenderingContext);
			DestroyWindow(windowHandle);
			UnregisterClassW(classname, mainInst);
		} else {
			if (ic) XDestroyIC(ic);
			if (im) XCloseIM(im);
			XDestroyWindow(mainDisplay, windowHandle);
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
		return cast(size_t)windowHandle;
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
	public void maximizeWindow() {
		version (Windows) {
			ShowWindow(windowHandle, SW_MAXIMIZE);
		}
	}
	/**
	 * Manually minimizes the window from code.
	 */
	public void minimizeWindow() {
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
	public void moveWindow(int x, int y, int w, int h) @nogc nothrow {
		version (Windows) {
			MoveWindow(windowHandle, x, y, w, h, TRUE);
		} else {
			XMoveResizeWindow(mainDisplay, windowHandle, x, y, w, h);
		}
	}
	/**
	 * Returns an array, of which the first two elements are the top-left coordinates 
	 * of the window, and the last two elements are the size of the active area of the
	 * window.
	 */
	public int[4] getWindowPosition() @nogc nothrow {
		version (Windows) {
			RECT windowSize;
			GetWindowRect(windowHandle, &windowSize);
			return [windowSize.left, windowSize.top, windowSize.right - windowSize.left + 1, 
					windowSize.bottom - windowSize.top + 1];
		} else {
			XWindowAttributes winattr;
			XGetWindowAttributes(mainDisplay, windowHandle, &winattr);
			return [winattr.x, winattr.y, winattr.width, winattr.height];
		}
	}
	/**
	 * Sets the window to full screen using the supplied video mode number. (UNIMPLEMENTED)
	 */
	public void setWindowToFullscreen(int mode) {

	}
	/**
	 * Creates, then returns the OpenGL handle associated with the window.
	 */
	public void* getOpenGLHandle() @nogc nothrow {
		version (Windows) {
			if (glRenderingContext) return glRenderingContext;
			HDC windowDeviceContext = GetDC(windowHandle);
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
		} else {
			return null;
		}
	}
	/**
	 * Returns the current input language code. (Linux UNIMPLEMENTED)
	 */
	public uint getInputLangCode() @nogc @safe nothrow const {
		version (Windows)
			return inputLang;
		else
			return 0;
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
			case WM_INPUTLANGCHANGEREQUEST, WM_INPUTLANGCHANGE:
				status = Status.InputLangCh;
				inputLang = cast(uint)lParam;
				with (lastInputEvent) {
					handle = this.windowHandle;
					type = InputEventType.WindowMove;
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
				if (wParam == SC_KEYMENU) return 0;
				goto default;
			/* case WM_SYSCHAR, WM_SYSDEADCHAR, WM_SYSKEYUP, WM_SYSKEYDOWN:

				return 0; */
			/* case WM_NCCALCSIZE:			
				if (wParam)
					return 0x30;
				else
					return 0; */
			default:
				return DefWindowProcW(windowHandle, msg, wParam, lParam);
		}
	}
}

