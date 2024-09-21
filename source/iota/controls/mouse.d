module iota.controls.mouse;

public import iota.controls.types;

version (Windows) {
	import core.sys.windows.windows;
	import core.sys.windows.wtypes;
} else {
	import x11.X;
	import x11.Xlib;
	import x11.extensions.XInput;
}
/** 
 * Defines mouse button codes.
 *
 * Others might exist, but not necessarily supported by API. Their numbers should go incrementally.
 */
public enum MouseButtons : ubyte {
	Left	=	1,
	Right	=	2,
	Middle	=	3,
	Prev	=	4,
	Next	=	5
}
/** 
 * Defines mouse button flags.
 *
 * Others might exist, but not necessarily supported by API. Their flags should go incrementally.
 */
public enum MouseButtonFlags {
	Left	=	1<<0,
	Right	=	1<<1,
	Middle	=	1<<2,
	Prev	=	1<<3,
	Next	=	1<<4
}
public class Mouse : InputDevice {
	package int[2]		lastPosition;
	package uint		lastButtonState;
	version (Windows) {
		//package uint	winButtonState;
		package this(string _name, ubyte _devNum, HANDLE devHandle) nothrow {
			this._name = _name;
			this._devNum = _devNum;
			this.hDevice = devHandle;
			_type = InputDeviceType.Mouse;
			status |= StatusFlags.IsConnected;
		}
	} else {
		package XDevice*	devHandle;
		package this(string _name, ubyte _devNum, XID devID) nothrow {
			this._name = _name;
			this._devNum = _devNum;
			//this.devHandle = XOpenDevice(OSWindow.mainDisplay, devID);
			_type = InputDeviceType.Keyboard;
			status |= StatusFlags.IsConnected;
		}
		~this() {
			//XCloseDevice(OSWindow.mainDisplay, devHandle);
		}
	}
	package this() nothrow {
		_type = InputDeviceType.Mouse;
		status |= StatusFlags.IsConnected;
	}

	public int[2] getLastPosition() @nogc @safe pure nothrow const {
		return lastPosition;
	}

	public uint getButtonState() @nogc @safe pure nothrow const {
		return lastButtonState;
	}
	
	public override string toString() @safe const {
		import std.conv : to;
		return "{" ~ _name.to!string ~ "; devID: " ~ _devNum.to!string ~ "; devHandle: " ~ hDevice.to!string ~ "}";
	}
	/* override public int poll(ref InputEvent output) @nogc nothrow {
		return 0;
	} */
}