module iota.window;


public import iota.window.oswindow;
public import iota.window.types;

/** 
 * Initializes some additional things on the given platform.
 * Currently on Windows, it initializes common controls.
 */
void initWindow_ext() {
    version (Windows) {
        import core.sys.windows.windows;
        import core.sys.windows.commctrl;
        INITCOMMONCONTROLSEX icex;
	    icex.dwSize = INITCOMMONCONTROLSEX.sizeof;
	    icex.dwICC = ICC_STANDARD_CLASSES;
	    assert(InitCommonControlsEx(&icex) == TRUE);
    }
}