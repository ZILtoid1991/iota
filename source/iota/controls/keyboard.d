module iota.controls.keyboard;

public import iota.controls.types;

version (Windows) {
	import core.sys.windows.windows;
	import core.sys.windows.wtypes;
} else {
	import x11.extensions.XI;
	import x11.extensions.XInput;
	import x11.extensions.XI2;
	import x11.extensions.XInput2;
}
/** 
 * Defines keyboard modifiers.
 * `Meta` is an OS-agnostic name for Windows, Command, etc. keys.
 */
public enum KeyboardModifiers : ubyte {
	init,
	Shift	=	1<<0,
	Ctrl	=	1<<1,
	Alt		=	1<<2,
	Meta	=	1<<3,
	NumLock	=	1<<4,
	CapsLock=	1<<5,
	ScrollLock= 1<<6,
	Aux		=	1<<7,
}
/** 
 * Defines keyboard locklight flags.
 * Both `Compose` and `Kana` exist within USB HID specifications, however they not necessarily are implemented within
 * OS API. Same with the now obsolete Scroll Lock.
 */
public enum KeyboardLocklights : ubyte {
	NumLock	=	1<<0,
	CapsLock=	1<<1,
	ScrollLock= 1<<2,
	Compose	=	1<<3,
	Kana	=	1<<4,
}
/** 
 * Implements keyboard I/O.
 */
public class Keyboard : InputDevice {
	protected static uint globalFlags;
	///Defines keyboard-specific flags.
	enum KeyboardFlags : ushort {
		TextInput		=	1<<8,	///Set if text input is enabled.
		IgnoreLLMods	=	1<<9,	///Set if lock light modifiers are to be ignored.
		///~~Fixes one of the greatest mistakes of deciding what the Alt key should do~~
		///Set if "open menubar on alt key" is disabled.
		MenuKeyFix		=	1<<10,	
		DisableMetaKey	=	1<<11,	///Disables meta key passthrough to OS
		DisableMetaKeyComb=	1<<12,	///Disables meta key shortcut passthrough to OS
	}
	version (Windows) {
		package HANDLE		devHandle;
		package this(io_str_t _name, ubyte _devNum, HANDLE devHandle) nothrow {
			this._name = _name;
			this._devNum = _devNum;
			this.devHandle = devHandle;
			_type = InputDeviceType.Keyboard;
			status |= StatusFlags.IsConnected;
		}
	} else {
		package XDevice*	devHandle;
		package this(io_str_t _name, ubyte _devNum, XID devID) nothrow {
			this._name = _name;
			this._devNum = _devNum;
			this.devHandle = XOpenDevice(OSWindow.mainDisplay, devID);
			_type = InputDeviceType.Keyboard;
			status |= StatusFlags.IsConnected;
		}
		~this() {
			XCloseDevice(OSWindow.mainDisplay, devHandle);
		}
	}
	package this() nothrow {
		_type = InputDeviceType.Keyboard;
		status |= StatusFlags.IsConnected;
	}
	/**
	 * Returns true if the text input has been enabled.
	 */
	public static bool isTextInputEn() @property @nogc @safe nothrow {
		return (globalFlags & KeyboardFlags.TextInput) != 0;
	}
	/**
	 * Sets whether the text input is enabled or not, then 
	 */
	public static bool setTextInput(bool val) @property @nogc @safe nothrow {
		if (val)
			globalFlags |= KeyboardFlags.TextInput;
		else
			globalFlags &= ~KeyboardFlags.TextInput;
		return isTextInputEn();
	}
	/**
	 * Returns true if locklight modifiers are ignored.
	 */
	public static bool isIgnoringLockLights() @property @nogc @safe nothrow {
		return (globalFlags & KeyboardFlags.IgnoreLLMods) != 0;
	}
	/**
	 * Sets locklight ignoring behavior.
	 */
	public static bool setIgnoreLockLights(bool val) @property @nogc @safe nothrow {
		if (val)
			globalFlags |= KeyboardFlags.IgnoreLLMods;
		else
			globalFlags &= ~KeyboardFlags.IgnoreLLMods;
		return isIgnoringLockLights();
	}
	/**
	 * Returns true if menu key (Alt and F10 on Windows) behavior is disabled.
	 * If disabled, these keys won't open the menu bar of a Window.
	 */
	public static bool isMenuKeyDisabled() @property @nogc @safe nothrow {
		return (globalFlags & KeyboardFlags.MenuKeyFix) != 0;
	}
	/**
	 * Disables menu key (Alt and F10 on Windows) behavior.
	 * If disabled, these keys won't open the menu bar of a Window.
	 */
	public static bool setMenuKeyDisabled(bool val) @property @nogc @safe nothrow {
		if (val)
			globalFlags |= KeyboardFlags.MenuKeyFix;
		else
			globalFlags &= ~KeyboardFlags.MenuKeyFix;
		return isMenuKeyDisabled();
	}
	/**
	 * Returns true if single meta key presses are not passed to the OS.
	 */
	public static bool isMetaKeyDisabled() @property @nogc @safe nothrow {
		return (globalFlags & KeyboardFlags.DisableMetaKey) != 0;
	}
	/**
	 * If set true, single meta key presses won't be passed to the OS.
	 * NOTE: May disable combinations too.
	 */
	public static bool setMetaKeyDisabled(bool val) @property @nogc @safe nothrow {
		if (val)
			globalFlags |= KeyboardFlags.DisableMetaKey;
		else
			globalFlags &= ~KeyboardFlags.DisableMetaKey;
		return isMetaKeyDisabled();
	}
	public static bool isMetaKeyCombDisabled() @property @nogc @safe nothrow {
		return (globalFlags & KeyboardFlags.DisableMetaKeyComb) != 0;
	}
	public static bool setMetaKeyCombDisabled(bool val) @property @nogc @safe nothrow {
		if (val)
			globalFlags |= KeyboardFlags.DisableMetaKeyComb;
		else
			globalFlags &= ~KeyboardFlags.DisableMetaKeyComb;
		return isMenuKeyDisabled();
	}
	/**
	 * Returns the currently active modifier keys.
	 */
	public ubyte getModifiers() @nogc nothrow @trusted {
		ubyte result;
		version (Windows) {
			if (GetAsyncKeyState(VK_SHIFT))
				result |= KeyboardModifiers.Shift;
			if (GetAsyncKeyState(VK_CONTROL))
				result |= KeyboardModifiers.Ctrl;
			if (GetAsyncKeyState(VK_MENU))
				result |= KeyboardModifiers.Alt;
			if (GetAsyncKeyState(VK_LWIN) | GetAsyncKeyState(VK_RWIN))
				result |= KeyboardModifiers.Meta;
			if (!isIgnoringLockLights()) {
				if (GetKeyState(VK_NUMLOCK))
					result |= KeyboardModifiers.NumLock;
				if (GetKeyState(VK_CAPITAL))
					result |= KeyboardModifiers.CapsLock;
				if (GetKeyState(VK_SCROLL))
					result |= KeyboardModifiers.ScrollLock;
			}
		}
		return result;
	}
	package void processTextCommandEvent(ref InputEvent ie, int code, int dir) nothrow @nogc @safe {
		import iota.controls.keybscancodes;
		
		ie.source = this;
		ie.type = InputEventType.TextCommand;
		ie.textCmd.flags = getModifiers() & 31;
		if (dir) {	//down
			switch (code) {
				case ScanCode.BACKSPACE:
					ie.textCmd.type = TextCommandType.Delete;
					ie.textCmd.amount = -1;
					break;
				case ScanCode.DELETE:
					ie.textCmd.type = TextCommandType.Delete;
					ie.textCmd.amount = 1;
					break;
				case ScanCode.LEFT:
					ie.textCmd.type = TextCommandType.Cursor;
					ie.textCmd.amount = -1;
					break;
				case ScanCode.RIGHT:
					ie.textCmd.type = TextCommandType.Cursor;
					ie.textCmd.amount = 1;
					break;
				case ScanCode.UP:
					ie.textCmd.type = TextCommandType.CursorV;
					ie.textCmd.amount = -1;
					break;
				case ScanCode.DOWN:
					ie.textCmd.type = TextCommandType.CursorV;
					ie.textCmd.amount = 1;
					break;
				case ScanCode.HOME:
					ie.textCmd.type = TextCommandType.Home;
					break;
				case ScanCode.END:
					ie.textCmd.type = TextCommandType.End;
					break;
				case ScanCode.PAGEUP:
					ie.textCmd.type = TextCommandType.PageUp;
					break;
				case ScanCode.PAGEDOWN:
					ie.textCmd.type = TextCommandType.PageDown;
					break;
				case ScanCode.ENTER, ScanCode.NP_ENTER:
					if (getModifiers & KeyboardModifiers.Shift)
						ie.textCmd.type = TextCommandType.NewLine;
					else
						ie.textCmd.type = TextCommandType.NewPara;
					break;
				default:
					ie.type = InputEventType.init;
					break;
			}
		} else {	//up
			switch (code) {
				case ScanCode.INSERT:
					ie.textCmd.type = TextCommandType.Insert;
					break;
				case ScanCode.ESCAPE:
					ie.textCmd.type = TextCommandType.Cancel;
					break;
				default:
					ie.type = InputEventType.init;
					break;
			}
		}
		
		
		
	}
	public override string toString() @safe const {
		import std.conv : to;
		return "name: " ~ _name.to!string ~ "; devID: " ~ _devNum.to!string ~ "; devHandle: " ~ devHandle.to!string;
	}
}