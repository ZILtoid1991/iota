module iota.etc.window;

version (Windows) {
	import core.sys.windows.windows;
	import core.sys.windows.wtypes;
}
import std.utf : toUTF16z;
import std.algorithm.searching;
public import iota.etc.vers;




/** 
 * Creates a window and returns its handle, while also saving its reference for later and to safe and automatic 
 * deallocation.
 * Params:
 *   title = The title of the window.
 *   x = X position of the window, or -1 for OS default.
 *   y = Y position of the window, or -1 for OS default.
 *   width = Width of the window, or -1 for OS default.
 *   height = Height of the window, or -1 for OS default.
 *   parent = Parent if there's any
 *   styleIDs = Style identifiers, see enum `WindowStyleIDs` for details.
 * Returns: The Window handle, or null if an error have happened.
 * Note: Only some basic functionality can be accessed from here. More advanced functionality is out of scope of this
 * library to minimize its complexity, and it's not supposed to be a GUI library. However, function `addWindow` will 
 * add any window handle to the reference counting if needed.
 */
/+public WindowH createWindow(io_str_t title, int x, int y, int width, int height, WindowH parent = null, 
		uint[] styleIDs = [WindowStyleIDs.Default]) {
	version (Windows) {
		LPCTSTR name = toUTF16z(title);
		WNDCLASSEXW clsReg;
		clsReg.cbSize = cast(UINT)WNDCLASSEXW.sizeof;
		clsReg.style = CS_OWNDC;
		clsReg.lpfnWndProc = &wndprocCallback;
		clsReg.lpszClassName = name;
		RegisterClassExW(&clsReg);


		DWORD flags;
		foreach (uint i ; styleIDs) {
			switch(i) {
				case WindowStyleIDs.Border:
					flags |= WS_BORDER;
					break;
				case WindowStyleIDs.Caption:
					flags |= WS_CAPTION;
					break;
				case WindowStyleIDs.Child:
					flags |= WS_CHILD;
					break;
				case WindowStyleIDs.Disabled:
					flags |= WS_DISABLED;
					break;
				case WindowStyleIDs.Resizable:
					flags |= WS_THICKFRAME;
					break;
				case WindowStyleIDs.Maximized:
					flags |= WS_MAXIMIZE;
					break;
				case WindowStyleIDs.Minimized:
					flags |= WS_MINIMIZE;
					break;
				case WindowStyleIDs.MaximizeBtn:
					flags |= WS_MAXIMIZEBOX | WS_SYSMENU;
					break;
				case WindowStyleIDs.MinimizeBtn:
					flags |= WS_MINIMIZEBOX | WS_SYSMENU;
					break;
				case WindowStyleIDs.PopUp:
					flags |= WS_POPUPWINDOW;
					break;
				case WindowStyleIDs.Visible:
					flags |= WS_VISIBLE;
					break;
				case WindowStyleIDs.Default:
					flags |= WS_TILEDWINDOW | WS_VISIBLE;
					break;
				default:
					break;
			}
		}
		if (x == -1) x = CW_USEDEFAULT;
		if (y == -1) y = CW_USEDEFAULT;
		if (width == -1) width = CW_USEDEFAULT;
		if (height == -1) height = CW_USEDEFAULT;
		WindowH handle; 
		
		handle = CreateWindowW(name, name, flags, x, y, width, height, parent, 
				null, null, null);
		if (handle)
			allAppWindows ~= handle;
		return handle;
	} else {
		return null;
	}
}+/
/** 
 * Adds a non-library created window handle to its references to cooperation with the library.
 * Params:
 *   ext = The window handle that needs to be added.
 * Returns: The reference, or null if either already added or an error happened.
 */
/+public WindowH addWindowRef(WindowH ext) nothrow {
	try {
		if (!count(allAppWindows, ext)) {
			allAppWindows ~= ext;
			return ext;
		} else {
			return null;
		}
	} catch (Exception e) {		//The count function should not throw, but still let know the user that some error have happened
		return null;
	}
}+/
version (Windows) {
	///As of now, this works as a dummy function. If more functionality needed in the future, then it might become part
	///of a class.
	
}
