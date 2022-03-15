module iota.etc.window;

version (Windows) {
	import core.sys.windows.windows;
	import core.sys.windows.wtypes;
}

public enum MessageWindowType {
	init,
}
/** 
 * Implements Window handles for GUI apps.
 */
version (Windows) {
	alias WindowH = HWND;
} else {
	alias WindowH = void*;
}
/** 
 * Returns the handle of the currently active Window.
 */
public WindowH getActiveWindowH() @nogc nothrow {
	version (Windows) {
		return GetActiveWindow();
	} else {
		return null;
	}
}