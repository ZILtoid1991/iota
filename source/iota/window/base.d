module iota.window.base;

version (Windows) {
	import core.sys.windows.windows;
	import core.sys.windows.wtypes;
	import std.utf : toUTF16z;
	import std.conv : to;
}
public import iota.window.types;
public import iota.window.exception;
public import iota.etc.vers;
//import collections.treemap;

/** 
 * Implements a wrapper for whatever windowing interface the OS has, with automatic reference counting.
 * Other window types supported by this library are inherited from this class.
 */
public class OSWindow {
	public enum Status {
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
	/** 
	 * Used for reference counting purposes.
	 * External keys should be added to it with function `addRef()`.
	 */
	public static OSWindow[]	refCount;
	///Handle to the window. Used for both automatic reference counting and for arguments in the I/O system.
	protected WindowH			windowHandle;
	///Contains various statusflags of the window.
	protected uint				statusFlags;

	version (Windows) {
		///Various calls from the OS are redirected to here, so then it can be used for certain types of event processing.
		///TODO: implement various window events (menu, drag-and-drop, etc)
		static extern (Windows) LRESULT wndprocCallback(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam) nothrow @system {
			switch (msg) {
				case WM_CREATE:
					return 0;
				case WM_NCCREATE:
					return TRUE;
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
		OSWindow newRef = new OSWindow(hndl);
		if (!count(refCount, newRef)) {
			refCount ~= newRef;
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
			registeredClass.style = 32_769;
			registeredClass.hInstance = mainInst;
			registeredClass.lpfnWndProc = &wndprocCallback;
			LPCWSTR classname = toUTF16z(name);
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
			const LPWSTR windowname = toUTF16z(title);
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
			ShowWindow(windowHandle, SW_SHOW);
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
	public bool opEquals(OSWindow rhs) const @nogc @safe pure nothrow {
		return windowHandle == rhs.windowHandle;
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
	/** 
	 * Callback function for windowing. Can be overridden to process more messages than by default.
	 * See Microsoft documentation for details on return value and parameters.
	 */
	version (Windows)
	protected LRESULT wndCallback(UINT msg, WPARAM wParam, LPARAM lParam) nothrow @system {
		switch (msg) {
			case WM_CREATE:
				return 0;
			case WM_NCCREATE:
				return TRUE;
			case WM_NCACTIVATE:
				return FALSE;
			case WM_DESTROY, WM_NCDESTROY:
				return 0;
			case WM_QUIT:
				statusFlags = Status.Quit;
				return 0;
			case WM_MOVE:
				statusFlags = Status.MoveEnded;
				return 0;
			case WM_MOVING:
				statusFlags = Status.Move;
				return 0;
			case WM_SIZE:
				statusFlags = Status.ResizeEnded;
				return 0;
			case WM_SIZING:
				statusFlags = Status.Resize;
				return 0;
			case WM_INPUTLANGCHANGEREQUEST:
				statusFlags = Status.InputLangChReq;
				inputLang = cast(uint)lParam;
				return 0;
			case WM_INPUTLANGCHANGE:
				statusFlags = Status.InputLangCh;
				inputLang = cast(uint)lParam;
				return 0;
			default:
				return LRESULT.init;
		}
	}
}

