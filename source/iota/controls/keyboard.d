module iota.controls.keyboard;

public import iota.controls.types;

version (Windows) {
	import core.sys.windows.windows;
	import core.sys.windows.wtypes;
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
	}
	package this() nothrow {
		_type = InputDeviceType.Keyboard;
		status |= StatusFlags.IsConnected;
	}
	/** 
	 * Polls the device for events.
	 * Params:
	 *   output = InputEvents outputted by the 
	 * Returns: 1 if there's still events to be polled, 0 if no events left. Other values are error codes.
	 */
	public override int poll(ref InputEvent output) @nogc nothrow {
		version (Windows) {
			//Since Windows is a bit weird when it comes to inputs, inputs are polled from system.
			//This class mainly exists here to provide context and other interfaces
			return 0;
		} else {
			return 0;
		}
	}
	/**
	 * Returns true if the text input has been enabled.
	 */
	public final bool isTextInputEn() @property @nogc @safe pure nothrow const {
		return (status & KeyboardFlags.TextInput) != 0;
	}
	/**
	 * Sets whether the text input is enabled or not, then 
	 */
	public bool setTextInput(bool val) @property @nogc @safe pure nothrow {
		if (val)
			status |= KeyboardFlags.TextInput;
		else
			status &= ~KeyboardFlags.TextInput;
		return isTextInputEn();
	}
	/**
	 * Returns true if locklight modifiers are ignored.
	 */
	public final bool isIgnoringLockLights() @property @nogc @safe pure nothrow const {
		return (status & KeyboardFlags.IgnoreLLMods) != 0;
	}
	/**
	 * Sets locklight ignoring behavior.
	 */
	public bool setIgnoreLockLights(bool val) @property @nogc @safe pure nothrow {
		if (val)
			status |= KeyboardFlags.IgnoreLLMods;
		else
			status &= ~KeyboardFlags.IgnoreLLMods;
		return isIgnoringLockLights();
	}
	/**
	 * Returns true if menu key (Alt and F10 on Windows) behavior is disabled.
	 * If disabled, these keys won't open the menu bar of a Window.
	 */
	public final bool isMenuKeyDisabled() @property @nogc @safe pure nothrow const {
		return (status & KeyboardFlags.MenuKeyFix) != 0;
	}
	/**
	 * Disables menu key (Alt and F10 on Windows) behavior.
	 * If disabled, these keys won't open the menu bar of a Window.
	 */
	public bool setMenuKeyDisabled(bool val) @property @nogc @safe pure nothrow {
		if (val)
			status |= KeyboardFlags.MenuKeyFix;
		else
			status &= ~KeyboardFlags.MenuKeyFix;
		return isMenuKeyDisabled();
	}
	/**
	 * Returns true if single meta key presses are not passed to the OS.
	 */
	public final bool isMetaKeyDisabled() @property @nogc @safe pure nothrow const {
		return (status & KeyboardFlags.DisableMetaKey) != 0;
	}
	/**
	 * If set true, single meta key presses won't be passed to the OS.
	 * NOTE: May disable combinations too.
	 */
	public bool setMetaKeyDisabled(bool val) @property @nogc @safe pure nothrow {
		if (val)
			status |= KeyboardFlags.DisableMetaKey;
		else
			status &= ~KeyboardFlags.DisableMetaKey;
		return isMetaKeyDisabled();
	}
	public final bool isMetaKeyCombDisabled() @property @nogc @safe pure nothrow const {
		return (status & KeyboardFlags.DisableMetaKeyComb) != 0;
	}
	public bool setMetaKeyCombDisabled(bool val) @property @nogc @safe pure nothrow {
		if (val)
			status |= KeyboardFlags.DisableMetaKeyComb;
		else
			status &= ~KeyboardFlags.DisableMetaKeyComb;
		return isMenuKeyDisabled();
	}
	/**
	 * Returns the currently active modifier keys.
	 */
	public ubyte getModifiers() @nogc nothrow {
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
	public override string toString() @safe const {
		import std.conv : to;
		return "name: " ~ _name.to!string ~ "; devID: " ~ _devNum.to!string ~ "; devHandle: " ~ devHandle.to!string;
	}
}