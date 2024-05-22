module iota.controls.types;

public import iota.window.oswindow;
import std.conv : to;
import std.bitmanip : bitfields;
public import core.time : MonoTime;
version (Windows) {
	import core.sys.windows.wtypes;
	import core.sys.windows.windows;
}

///Defines the type of the timestamp
///Resolution is 1 microsecond, but full resolution might not be available depending on OS.
alias Timestamp = ulong;

/** 
 * Generates a relatively high precision timesstamp.
 */
package Timestamp getTimestamp() @nogc nothrow {
	return MonoTime.currTime.ticks / 10;
}
/** 
 * Defines the types of the input devices.
 */
public enum InputDeviceType : ubyte {
	init,
	Keyboard,
	Mouse,
	GameController,		///Joysticks, gamepads, etc.
	Pen,				///Graphics tablet, etc.
	TouchScreen,
	Gyro,				///Built-in Gyro device.
	System,				///Misc. system related input devices and events.
	MIDI,				///If enabled, MIDI devices can function as regular input devices creating regular input events from key press and control change commands.
}
/**
 * Defines possible input event types.
 */
public enum InputEventType {
	init,
	Keyboard,
	TextInput,
	TextCommand,
	TextEdit,
	MouseClick,
	MouseMove,
	MouseScroll,
	HPMouse,
	GCButton,		///Any button of a game controller
	GCAxis,			///Any axis of a game controller
	GCHat,			///POV hat, or D-Pad
	Pen,
	DeviceAdded,
	DeviceRemoved,
	Clipboard,
	WindowClose,
	WindowResize,
	WindowMinimize,
	WindowMaximize,
	WindowRestore,
	WindowMove,
	InputLangChange,
	ApplExit,
	Debug_DataDump,	///RawInput data dump 
}
/** 
 * Defines text command event types.
 */
public enum TextCommandType {
	init,
	Cursor,		///Horizontal cursor
	CursorV,	///Vertical cursor

	Home,
	End,
	PageUp,
	PageDown,

	Delete,

	Insert,		///Insert toggle

	NewLine,	///Shift + Enter
	NewPara,	///Enter
	Cancel,		///End text input

	
}
/** 
 * Defines configuration flags for the input subsystem.
 */
public enum ConfigFlags : uint {
	///Enables touchscreen handling. (Always on under mobile platforms)
	enableTouchscreen			=	1 << 0,
	///Toggles game controller trigger handling mode.
	///If set, they will be treated as analog buttons, otherwise as axes that go between 0.0 and 1.0.
	gc_TriggerMode				=	1 << 1,
	///Enables game controller handling. (Always on under game consoles)
	gc_Enable					=	1 << 2,
}
/** 
 * Operating system specific flags
 */
public enum OSConfigFlags : uint {
	///Enables raw input under Windows for more capabilities.
	win_RawInput				=	1 << 0,
	///Uses the older Wintab over other options.
	win_Wintab					=	1 << 1,
	///Disables hotkey handling on Windows.
	win_DisableHotkeys			=	1 << 2,
	///Enables rawinput for game controllers.
	win_RawInputGC				=	1 << 3,
	///Use XInput for game controllers.
	win_XInput					=	1 << 4,
	///Enables x11 input extensions.
	x11_InputExtensions			=	1 << 0,
}
/** 
 * Defines return codes for the `iota.controls.initInput` function.
 */
public enum InputInitializationStatus {
	AllOk					=	0,
	win_RawInputError		=	-1,
	win_DevicesAdded		=	-2,

	x11_InputExtNotAvailable=	-32,
}
/** 
 * Defines return codes for event polling.
 */
public enum EventPollStatus {
	Done			=	0,
	HasMore			=	1,
	DeviceInvalidated,
	DeviceError,
	NoDevsFound,
	win_RawInputError,
}
/**
 * Defines return codes for haptic events.
 */
public enum HapticDeviceStatus {
	AllOk,
	DeviceInvalidated,
	UnsupportedCapability,
	OutOfRange,
	FrequencyNeeded,
}
/** 
 * Defines text edit event flags.
 */
public enum TextCommandFlags {
	PerWord = 1<<0,		///Modifies cursor and delete to work on a per-word basis (essentially holding down the Ctrl key)
	Select = 1<<1,		///Modifies cursor and other nav commands
}
/**
 * Contains basic info about the input device.
 * Child classes might also contain references to OS variables and pointers.
 */
public abstract class InputDevice {
	protected InputDeviceType	_type;		/// Defines the type of the input device
	protected ubyte				_devNum;	/// Defines the number of the input device within the group of same types
	protected ubyte				_battP;		/// Current percentage of the battery
	protected io_str_t			_name;		/// The name of the device if there's any
	/// Status flags of the device.
	/// Bits 0-7 are common, 8-15 are special to each device/interface type.
	/// Note: flags related to indicators/etc should be kept separately.
	package ushort				status;
	package void*				hDevice;	/// Windows only field for RawInput
	/**
	 * Defines common status codes
	 */
	public enum StatusFlags : ushort {
		IsConnected		=	1<<0,			///Set if device is connected
		IsInvalidated	=	1<<1,			///Set if device is invalidated (disconnected, etc.)
		HasBattery		=	1<<2,			///Set if device has a battery
		IsAnalog		=	1<<3,			///Set if device has analog capabilities
		IsVirtual		=	1<<4,			///Set if device is emulated/virtual (e.g. on-screen keyboard)
		IsHapticCapable	=	1<<5,			///Set if device is haptic capable
	}
	/** 
	 * Returns the type of the device.
	 */
	public InputDeviceType type() @nogc @safe pure nothrow const @property {
		return _type;
	}
	/** 
	 * Returns the device number.
	 */
	public ubyte devNum() @nogc @safe pure nothrow const @property {
		return _devNum;
	}
	/**
	 * Returns true if the device is connected.
	 */
	public bool isConnected() @nogc @safe pure nothrow const @property {
		return (status & StatusFlags.IsConnected);
	}
	/** 
	 * Returns true if device got invalidated (disconnected, etc).
	 */
	public bool isInvalidated() @nogc @safe pure nothrow const @property {
		return (status & StatusFlags.IsInvalidated) != 0;
	}
	///Returns true if device got haptic capabilities.
	public bool isHapticCapable() @nogc @safe pure nothrow const @property {
		return (status & StatusFlags.IsHapticCapable) != 0;
	}
	/** 
	 * Returns true if device has analog capabilities.
	 */
	public bool isAnalog() @nogc @safe pure nothrow const @property {
		return (status & StatusFlags.IsAnalog) != 0;
	}
	/** 
	 * Returns true if device is virtual, emulated, etc.
	 */
	public bool isVirtual() @nogc @safe pure nothrow const @property {
		return (status & StatusFlags.IsVirtual) != 0;
	}
	/** 
	 * Returns the battery percentage of the device, or ubyte.max if it doesn't have a battery.
	 */
	public ubyte battP() @nogc @safe pure nothrow const @property {
		if (status & StatusFlags.HasBattery) 
			return _battP;
		else
			return ubyte.max;
	}
	public io_str_t name() @nogc @safe pure nothrow const @property {
		return _name;
	}
	public override string toString() @safe const {
		import std.conv : to;
		return _name.to!string;
	}
}
/**
 * Defines basic functions for haptic devices.
 */
public interface HapticDevice {
	///Defines capabilities of haptic devices.
	public enum Capabilities {
		init,
		LeftMotor,
		RightMotor,
		TriggerRumble,
	}
	///Defines potential zones of haptic capabilities.
	public enum Zones {
		init,		///Used when capability does not have zones
		Left,
		Right,
	}
	/**
	 * Returns all capabilities of the haptic device.
	 */
	public uint[] getCapabilities() nothrow;
	/**
	 * Returns all zones associated with the capability of the device.
	 * Returns null if zones are not applicable for the device's given capability.
	 */
	public uint[] getZones(uint capability) nothrow;
	/**
	 * Applies a given effect.
	 * Params:
	 *   capability: The capability to be used.
	 *   zone: The zone where the effect should be used.
	 *   val: The strength of the capability (between 0.0 and 1.0).
	 *   freq: The frequency if supported, float.nan otherwise.
	 * Returns: 0 on success, or a specific error code.
	 */
	public int applyEffect(uint capability, uint zone, float val, float freq = float.nan) nothrow;
	/**
	 * Stops all haptic effects of the device.
	 * Returns: 0 on success, or a specific error code.
	 */
	public int reset() nothrow;
}
/** 
 * Defines a button (keyboard, game controller) event data.
 */
public struct ButtonEvent {
	ubyte		dir;	///Up (0) or down (1)
	ubyte		repeat;	///Used for repetition if supported by source
	ushort		aux;	///Used to identify modifier keys on keyboard, etc.
	uint		id;		///Button ID
	float		auxF;	///Placeholder for pressure-sensitive buttons, NaN otherwise
	string toString() @safe pure const {
		return "Direction: " ~ to!string(dir) ~" ; repeat: " ~ to!string(repeat) ~ " ; aux: " ~ to!string(aux) ~ " ; ID: " ~ 
				to!string(id) ~ " ; auxF: " ~ to!string(auxF) ~ " ;";
	}
}
/** 
 * Defines the contents of a text input data.
 *
 * Version label `iota_use_utf8` will make the middleware to convert text input to UTF8 on non-UTF8 systems, leaving
 * it out will make UTF32 as the standard
 */
public struct TextInputEvent {
	///Pointer to the character buffer.
	private io_chr_t* _text;
	///The amount of characters on the buffer.
	private size_t _length;
	
	string toString() @safe pure const {
		return "Text: \"" ~ to!string(text[0.._length]); 
	}
	io_str_t text() @nogc @trusted pure nothrow const {
		io_str_t helperFunc() @nogc @system pure nothrow const {
			return cast(dstring)_text[0.._length];
		}
		return helperFunc();
	}
	size_t length() @nogc @safe pure nothrow const {
		return _length;
	}
}
/** 
 * Defines text editing command events that could happen during a text input.
 */
public struct TextCommandEvent {
	TextCommandType	type;	///The type of the text editing event.
	int			amount;		///Amount of the event + direction, if applicable.
	uint		flags;		///Extra flags for text edit events, i.e. modifiers.
	uint		buttonID;	///Used if the source is a keyboard
}
/**
 * Defines an axis event.
 * Per-axis IDs are being used.
 */
public struct AxisEvent {
	uint		id;		///Identifier number of the axis.
	float		val;	///Current value of the axis (either -1.0 to 1.0 or 0.0 to 1.0)
	int			raw;	///Raw value from the controller if available
	string toString() @safe pure const {
		return "ID: " ~ to!string(id)  ~ " ; val: " ~ to!string(val) ~ " ; ";
	}
}
/**
 * Defines a mouse click event.
 * Also supplies the screen coordinates of the click event.
 */
public struct MouseClickEvent {
	ubyte		dir;	///Up (1), or down (0)
	ubyte		repeat;	///Non-zero if multiple clicks occured.
	ushort		button;	///Button ID
	int			x;		///X coordinate
	int			y;		///Y coordinate
	string toString() @safe pure const {
		return "Direction: " ~ to!string(dir) ~ " ; repeat: " ~ to!string(repeat) ~ " ; button: " ~ to!string(button) ~ 
				" ; x: " ~ to!string(x) ~ " y; " ~ to!string(y) ~" ; ";
	}
}
/**
 * Defines a mouse motion event with the buttons that are held down.
 */
public struct MouseMotionEvent {
	///If a bit high, it indicates that button is being held down.
	///See enum MouseButtonFlags to identify each button.
	uint		buttons;
	int			x;		///X position of the cursor.
	int			y;		///Y position of the cursor.
	int			xD;		///X amount of the motion.
	int			yD;		///Y amount of the motion.
	string toString() @safe pure const {
		return "Buttons: " ~ to!string(buttons) ~ " ; x: " ~ to!string(x) ~ " ; y: " ~ to!string(y) ~ " ; xD: " ~ 
				to!string(xD) ~ " ; yD " ~ to!string(yD) ~ " ; ";
	}
}
/**
 * Defines a mouse scroll event.
 */
public struct MouseScrollEvent {
	int			xS;		///Amount of horizontal scroll
	int			yS;		///Amount of vertical scroll
	int			x;		///X position of the cursor
	int			y;		///Y position of the cursor
	string toString() @safe pure const {
		return "xS: " ~ to!string(xS) ~ " ; yS: " ~ to!string(yS) ~ " ; x: " ~ to!string(x) ~ " ; y: " ~ to!string(y) ~ " ; ";
	}
}
/** 
 * Defines a high-precision mouse event. Only available with drivers that support such capability.
 * X and Y coordinates are fixed-point fractional with the lower half containing the fraction, and the higher-half 
 * containing the whole numbers.
 * WWWW.FFFF
 */
public struct HighPrecMouseEvent {
	byte		hScroll;///horizontal scroll amount
	byte		vScroll;///vertical scroll amount
	ushort		buttons;///button vector
	int			x;		///X position of the cursor.
	int			y;		///Y position of the cursor.
	int			xD;		///X amount of the motion.
	int			yD;		///Y amount of the motion.
	string toString() @safe pure const {
		return "Buttons: " ~ to!string(buttons) ~ " ; x: " ~ to!string(x / 65_536.0) ~ " ; y: " ~ to!string(y / 65_536.0) ~ 
				" ; xD: " ~ to!string(xD / 65_536.0) ~ " ; yD " ~ to!string(yD / 65_536.0) ~ " ; hScroll: " ~ to!string(hScroll) ~ 
				" ; vScroll: " ~ to!string(vScroll) ~ " ; ";
	}
}
/**
 * Defines a pen event of a graphic tablet, screen, etc.
 */
public struct PenEvent {
	int			x;			/// X position of the event
	int			y;			/// Y position of the event
	float		tilt;		/// The tilt amount of the pen 
	float		pDir;		/// The direction of the pen
	float		tDir;		/// The tilt direction of the pen
}
public struct WindowEvent {
	int			x;
	int			y;
	int			width;
	int			height;
	string toString() @safe pure const {
		return "x: " ~ to!string(x) ~ "; y: " ~ to!string(y) ~ "; width: " ~ to!string(width) ~ "; height:" ~ 
				to!string(height);
	}
}
/**
 * Defines a clipboard event.
 * Also used for data dumping RawInput data.
 */
public struct ClipboardEvent {
	size_t		length;
	ubyte*		data;
	uint		type;
	ubyte[] getData() @trusted {
		ubyte[] _getData() @system {
			return data[0..length];
		}
		return _getData();
	}
	string toString() const {
		return to!string(data[0..length]);
	}
}
/**
 * Contains data generated by input devices.
 */
public struct InputEvent {
	InputDevice				source;		///Pointer to the source input device class.
	WindowH					handle;		///Window handle for GUI applications if there's any, null otherwise.
	Timestamp				timestamp;	///Timestamp for when the event have happened.
	InputEventType			type;		///Type of the input event.
	union {
		ButtonEvent			button;
		TextInputEvent		textIn;
		TextCommandEvent	textCmd;
		AxisEvent			axis;
		MouseClickEvent		mouseCE;
		MouseMotionEvent	mouseME;
		MouseScrollEvent	mouseSE;
		HighPrecMouseEvent	mouseHP;
		PenEvent			pen;
		WindowEvent			window;
		ClipboardEvent		clipboard;
	}
	string toString() {
		string result = "Source: " ~ (source is null ? "null" : "{" ~ source.toString ~ "}") ~ " ; Window handle: " ~ 
				to!string(cast(size_t)handle) ~ " ; Timestamp: " ~ to!string(timestamp) ~ " ; Type: " ~ to!string(type) ~ 
				" ; Rest: {";
		switch (type) {
			case InputEventType.Keyboard, InputEventType.GCButton:
				result ~= button.toString();
				break;
			case InputEventType.TextInput:
				result ~= textIn.toString();
				break;
			case InputEventType.MouseClick:
				result ~= mouseCE.toString();
				break;
			case InputEventType.MouseMove:
				result ~= mouseME.toString();
				break;
			case InputEventType.MouseScroll:
				result ~= mouseSE.toString();
				break;
			case InputEventType.GCAxis:
				result ~= axis.toString();
				break;
			case InputEventType.WindowMaximize, InputEventType.WindowMinimize, InputEventType.WindowMove, 
					InputEventType.WindowResize, InputEventType.WindowRestore:
				result ~= window.toString();
				break;
			case InputEventType.HPMouse:
				result ~= mouseHP.toString();
				break;
			case InputEventType.Clipboard, InputEventType.Debug_DataDump:
				result ~= clipboard.toString();
				break;
			default:
				break;
		}
		result ~= "}";
		return result;
	}
}