module iota.window.oswindow;

version (Windows) {
	import core.sys.windows.windows;
	import core.sys.windows.wtypes;
	import std.utf : toUTF16z;
	import std.conv : to;
}
public import iota.window.types;
public import iota.window.exception;
public import iota.etc.vers;
import std.algorithm.mutation : remove;
//import collections.treemap;

/** 
 * Implements a wrapper for whatever windowing interface the OS has, with automatic reference counting.
 * Other window types supported by this library are inherited from this class.
 */
public class OSWindow {
	///Defines Window status values, also used on Windows for event handling.
	public enum Status {
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
	 * Used for reference counting purposes.
	 * External keys should be added to it with function `addRef()`.
	 */
	public static OSWindow[]	refCount;
	///Handle to the window. Used for both automatic reference counting and for arguments in the I/O system.
	protected WindowH			windowHandle;
	///Contains various statusflags of the window.
	protected Status			statusFlags;
	///Delegate called when a draw request is sent to the class.
	///It can intercept it for various reasons, but this is not OS independent, and so far no drawing API is planned 
	///that uses OS provided functions. 
	public nothrow @system void delegate(DrawParams params) drawDeleg;
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
		//protected static HINSTANCE	hInstance;
		///Stores registered class info. Each window has its own registered class by default.
		protected WNDCLASSEXW		registeredClass;
		protected ATOM				regClResult;
		protected LPCWSTR			classname, windowname;
		///hInstance is stored here, which is needed for window creation, etc.
		///NOTE: This is Windows exclusive, and won't be accessable under other OSes.
		public static HINSTANCE	mainInst;
		///The current input language code (Windows).
		///Stored here due to ease of access.
		public static uint		inputLang;
		shared static this() {
			//NOTE: This is not the proper way of doing stuff like this.
			//However, this way we can possibly eliminate the need for use of `WinMain` and might also piss off some
			//people at Microsoft.
			mainInst = GetModuleHandle(null);
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
	 *   parent = Parent if exists, null otherwise.
	 */
	public this(io_str_t title, io_str_t name, int x, int y, int w, int h, ulong flags, WindowIcon icon = null, 
			WindowMenu menu = null, OSWindow parent = null) {
		version (Windows) {
			registeredClass.cbSize = WNDCLASSEXW.sizeof;
			registeredClass.style = CS_HREDRAW | CS_VREDRAW;
			registeredClass.hInstance = mainInst;
			registeredClass.lpfnWndProc = &wndprocCallback;
			classname = toUTF16z(name);
			registeredClass.lpszClassName = classname;
			regClResult = RegisterClassExW(&registeredClass);
			if (!regClResult) {
				auto errorCode = GetLastError();
				throw new WindowCreationException("Failed to register window class!", errorCode);
			}
			DWORD dwStyle, dwExStyle;
			if (flags & WindowStyleIDs.Border)
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
				dwExStyle |= WS_EX_CONTEXTHELP;
			
			if (x <= 0) x = CW_USEDEFAULT;
			if (y <= 0) y = CW_USEDEFAULT;
			if (w <= 0) w = CW_USEDEFAULT;
			if (h <= 0) h = CW_USEDEFAULT;
			windowname = toUTF16z(title);
			HWND parentHndl = null;
			if (parent !is null)
				parentHndl = parent.getHandle();
			windowHandle = CreateWindowExW(dwExStyle, classname, windowname, dwStyle, x, y, w, h, parentHndl, null, mainInst, 
					null);
			if (!windowHandle) {
				auto errorCode = GetLastError();
				throw new WindowCreationException("Failed to create window!", errorCode);
			}
			refCount ~= this;
			SetLayeredWindowAttributes(windowHandle, 0, 0xFF, LWA_ALPHA);
			ShowWindow(windowHandle, SW_RESTORE);
			UpdateWindow(windowHandle);
		}
	}
	protected this(WindowH hndl) {
		windowHandle = hndl;
	}

	~this() {
		version (Windows) {
			DestroyWindow(windowHandle);
			UnregisterClassW(registeredClass.lpszClassName, mainInst);
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
	public Status getWindowStatus() @nogc @safe pure nothrow {
		Status result = statusFlags;
		statusFlags = Status.init;
		return result;
	}
	/**
	 * Manually maximizes the window from code.
	 */
	public void maximizeWindow() {
		ShowWindow(windowHandle, SW_MAXIMIZE);
	}
	/**
	 * Manually minimizes the window from code.
	 */
	public void minimizeWindow() {
		ShowWindow(windowHandle, SW_MINIMIZE);
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
				statusFlags = Status.Quit;
				return 0;
			case WM_QUIT:
				statusFlags = Status.Quit;
				goto default;
			case WM_MOVE:
				statusFlags = Status.MoveEnded;
				goto default;
			case WM_MOVING:
				statusFlags = Status.Move;
				goto default;
			case WM_SIZE:
				statusFlags = Status.ResizeEnded;
				goto default;
			case WM_SIZING:
				statusFlags = Status.Resize;
				goto default;
			case WM_INPUTLANGCHANGEREQUEST:
				statusFlags = Status.InputLangChReq;
				inputLang = cast(uint)lParam;
				goto default;
			case WM_INPUTLANGCHANGE:
				statusFlags = Status.InputLangCh;
				inputLang = cast(uint)lParam;
				goto default;
			case WM_PAINT:
				PAINTSTRUCT ps;
				RECT rc;
				HDC hdc = BeginPaint(windowHandle, &ps);
				GetClientRect(windowHandle, &rc);
				FillRect(hdc, &rc, cast(HBRUSH)(COLOR_WINDOW));
				DrawFrameControl(hdc, &rc, DFC_CAPTION, 0);
				EndPaint(windowHandle, &ps);
				goto default;
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

