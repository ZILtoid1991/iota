module iota.controls.mouse;

public import iota.controls.types;

version (Windows) {
	import core.sys.windows.windows;
	import core.sys.windows.wtypes;
}
/** 
 * Defines mouse button codes.
 *
 * Others might exist, but not necessarily supported by API. Their numbers should go incrementally.
 */
public enum MouseButtons : ubyte {
    Left    =   1,
    Right   =   2,
    Middle  =   3,
    Prev    =   4,
    Next    =   5
}
/** 
 * Defines mouse button flags.
 *
 * Others might exist, but not necessarily supported by API. Their flags should go incrementally.
 */
public enum MouseButtonFlags {
    Left    =   1<<0,
    Right   =   1<<1,
    Middle  =   1<<2,
    Prev    =   1<<3,
    Next    =   1<<4
}
public class Mouse : InputDevice {

    package this() {

    }
    override public int poll(ref InputEvent output) @nogc nothrow {
        return 0;
    }
}