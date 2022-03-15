module iota.controls.keyboard;

public import iota.controls.types;

version (Windows) {
	import core.sys.windows.windows;
	import core.sys.windows.wtypes;
}
/** 
 * Defines keyboard modifiers.
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
 * Both `Compose` and `Kana` exist within USB HID specifications, however they not necessarily are implemented whithin
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
	}
	package this() {
		_type = InputDeviceType.Keyboard;
	}
	/** 
	 * Polls the device for events.
	 * Params:
	 *   output = InputEvents outputted by the 
	 * Returns: 1 if there's still events to be polled, 0 if no events left. Other values are error codes.
	 */
	public override int poll(ref InputEvent output) @nogc nothrow {
		version (Windows) {
			//Since Windows is a bit weird when it comes to inputs, so inputs are polled from system.
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
	public final bool isIgnoringLockLights() @property @nogc @safe pure nothrow const {
		return (status & KeyboardFlags.IgnoreLLMods) != 0;
	}
	public bool setIgnoreLockLights(bool val) @property @nogc @safe pure nothrow {
		if (val)
			status |= KeyboardFlags.IgnoreLLMods;
		else
			status &= ~KeyboardFlags.IgnoreLLMods;
		return isIgnoringLockLights();
	}
	public ubyte getModifiers() @nogc nothrow {
		ubyte result;
		version (Windows) {
			if (GetKeyState(VK_SHIFT))
				result |= KeyboardModifiers.Shift;
			if (GetKeyState(VK_CONTROL))
				result |= KeyboardModifiers.Ctrl;
			if (GetKeyState(VK_MENU))
				result |= KeyboardModifiers.Alt;
			if (GetKeyState(VK_LWIN) | GetKeyState(VK_RWIN))
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
}