module iota.controls.system;

version (Windows) {
	import core.sys.windows.windows;
	
	import core.sys.windows.wtypes;
	import iota.controls.keyboard;
	import iota.controls.mouse;
	import std.utf;
	import std.stdio;
	import iota.controls.keybscancodes : translateSC, translatePS2MC;
} else version (OSX) {
	import cocoa.nsscreen;
	import cocoa.foundation;
} else {
	import x11.X;
	import x11.Xlib;
	import x11.extensions.XInput;
	import x11.extensions.XInput2;
}
import iota.controls.types;
import iota.etc.charcode;
import iota.window;

/** 
 * Implements a class for system-wide events.
 */
public class System : InputDevice {
	version (iota_use_utf8) {
		///Character input converted to UTF-8
		char[4]				lastChar;
	} else {
		///Character input converted to UTF-32
		dchar				lastChar;
	}
	///Sizes of the screen. 0 : Virtual desktop width, 1 : Virtual desktop height, 2 : Screen width, 3: Screen height
	package int[4]			screenSize;
	protected size_t		winCount;	///Window counter.	
	
	enum SystemFlags : ushort {
		Win_RawInput		=	1 << 8,
	}
	package this(uint config = 0, uint osConfig = 0) @nogc nothrow {
		version (Windows) {
			screenSize = [GetSystemMetrics(SM_CXVIRTUALSCREEN), GetSystemMetrics(SM_CXVIRTUALSCREEN), 
					GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN)];
		} else version(OSX) {
			NSScreen mainScreen = NSScreen.mainScreen();
			if (mainScreen !is null) {
				CGRect frame = mainScreen.frame();
				screenSize = [
					cast(int)frame.size.width,
					cast(int)frame.size.height,
					cast(int)frame.size.width,
					cast(int)frame.size.height
				];
			}
		} else {
			if (OSWindow.mainDisplay) {
				screenSize = [WidthOfScreen(OSWindow.mainDisplay), HeightOfScreen(OSWindow.mainDisplay),
						WidthOfScreen(OSWindow.mainDisplay), HeightOfScreen(OSWindow.mainDisplay)];
			} else {
				screenSize = [-1, -1, -1, -1];
			}
		}
	}
		
}
