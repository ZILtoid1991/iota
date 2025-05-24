module iota.controls.types;

public import iota.window.oswindow;
import iota.controls.gamectrl;
import std.conv : to;
import std.bitmanip : bitfields;
import std.string : toStringz, fromStringz, splitLines, split;
public import core.time : MonoTime;
version (Windows) {
	import core.sys.windows.wtypes;
	import core.sys.windows.windows;
} else version (linux) {
	import iota.controls.backend.linux;
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
	HPMouse,		///High-precision mouse events, used by RawInput under Windows
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
	// MacOS specific
    GestureBegin = 32,
    GestureEnd = 33,
    GestureZoom = 34,
    GestureRotate = 35,
    GestureSwipe = 36,
    ForceTouchPressure = 37
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
	enableTouchscreen			=	1<<0,
	///Toggles game controller trigger handling mode.
	///If set, they will be treated as analog buttons, otherwise as axes that go between 0.0 and 1.0.
	gc_TriggerMode				=	1<<1,
	///Enables game controller handling. (Always on under game consoles)
	gc_Enable					=	1<<2,
}
/** 
 * Operating system specific flags
 */
public enum OSConfigFlags : uint {
	///Enables raw input under Windows for more capabilities.
	win_RawInput				=	1<<0,
	///Uses the older Wintab over other options.
	win_Wintab					=	1<<1,
	///Disables hotkey handling on Windows.
	win_DisableHotkeys			=	1<<2,
	///Enables rawinput for game controllers.
	win_RawInputGC				=	1<<3,
	///Use XInput for game controllers.
	win_XInput					=	1<<4,
	///Enables x11 input extensions.
	x11_InputExtensions			=	1<<5,
	///Enables libevdev for Linux.
	libevdev_enable				=	1<<6,
	libevdev_writeenable		=	1<<7,
	libevdev_gconly				=	1<<8,
	win_GameInput				=	1<<9,
}
/** 
 * Defines return codes for the `iota.controls.initInput` function.
 */
public enum InputInitializationStatus {
	AllOk					=	0,
	win_RawInputError		=	-1,
	win_DevicesAdded		=	-2,

	x11_InputExtNotAvailable=	-32,
	libevdev_ErrorOpeningDev=	-33,
	libevdev_AccessDenied	=	-34,
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
	InputNotInitialized,
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
	PerWord = 1<<1,		///Modifies cursor and delete to work on a per-word basis (essentially holding down the Ctrl key)
	Select = 1<<0,		///Modifies cursor and other nav commands
}
/**
 * Contains basic info about the input device.
 * Child classes might also contain references to OS variables and pointers.
 */
public abstract class InputDevice {
	protected string			_name;		/// The name of the device if there's any
	/// Status flags of the device.
	/// Bits 0-7 are common, 8-15 are special to each device/interface type.
	/// Note: flags related to indicators/etc should be kept separately.
	package ushort				status;
	protected ubyte				_devNum;	/// Defines the number of the input device within the group of same types
	protected ubyte				_battP;		/// Current percentage of the battery
	protected InputDeviceType	_type;		/// Defines the type of the input device
	version (Windows) {
		package void*			hDevice;	/// Field for RawInput
	} else version (linux) {
		package libevdev*		hDevice;	/// Field for evdev
		package int				fd;
	}
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
	/**
	 * Returns the name of the device.
	 */
	public string name() @nogc @safe pure nothrow const @property {
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
	public uint[] getCapabilities() @safe nothrow;
	/**
	 * Returns all zones associated with the capability of the device.
	 * Returns null if zones are not applicable for the device's given capability.
	 */
	public uint[] getZones(uint capability) @safe nothrow;
	/**
	 * Applies a given effect.
	 * Params:
	 *   capability: The capability to be used.
	 *   zone: The zone where the effect should be used.
	 *   val: The strength of the capability (between 0.0 and 1.0).
	 *   freq: The frequency if supported, float.nan otherwise.
	 * Returns: 0 on success, or a specific error code.
	 */
	public int applyEffect(uint capability, uint zone, float val, float freq = float.nan) @trusted nothrow;
	/**
	 * Stops all haptic effects of the device.
	 * Returns: 0 on success, or a specific error code.
	 */
	public int reset() @trusted nothrow;
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
	private char* _text;
	///The amount of characters on the buffer.
	private size_t _length;
	bool		isDeadChar;
	string toString() @safe pure const {
		return "Text: \"" ~ text ~ "\" ; isDeadChar: " ~ to!string(isDeadChar); 
	}
	string text() @nogc @trusted pure nothrow const {
		string helperFunc() @nogc @system pure nothrow const {
			return cast(string)_text[0.._length];
		}
		if (!_text) return null;
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
	string toString() @safe pure const {
		return "type: " ~ to!string(type) ~ " ; amount: " ~ to!string(amount) ~ " ; flags: " ~ to!string(flags) ~ 
				" ; buttonID: " ~ to!string(buttonID);
	}
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
	int			xS;		/// Amount of horizontal scroll
	int			yS;		/// Amount of vertical scroll
	int			x;		/// X position of the cursor
	int			y;		/// Y position of the cursor
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
	byte		hScroll;/// horizontal scroll amount
	byte		vScroll;/// vertical scroll amount
	ushort		buttons;/// button vector
	int			x;		/// X position of the cursor.
	int			y;		/// Y position of the cursor.
	int			xD;		/// X amount of the motion.
	int			yD;		/// Y amount of the motion.
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
	float		xTilt;
	float		yTilt;
	float		pressure;
	float		rotation;
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
	ubyte*		data;
	size_t		length;
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
public struct ArbPtrEvent {
	void*		data;
	size_t		length;		///Length of data if applicable, zero otherwise and for
}
/**
 * Contains data generated by input devices.
 */
public struct InputEvent {
	InputDevice				source;		///Pointer to the source input device class.
	WindowH					handle;		///Window handle for GUI applications if there's any, null otherwise.
	Timestamp				timestamp;	///Timestamp for when the event have happened.
	InputEventType			type;		///Type of the input event.
	union {					// Note: New fields should be maximum 32 byte long, try to use bitpacking whenever possible.
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
		ArbPtrEvent			arbPtr;
		uint[8]				rawData;
	}

	string toString() @trusted {
		// The cast to void* is required for OSX. It will be more readable if we don't use version'ed 
		// code here. Leave as-is, unless it somehow causes problems on Windows or Linux?
		string result = "Source: " ~ (source is null ? "null" : "{" ~ source.toString ~ "}") ~ " ; Window handle: " ~ 
				to!string(cast(size_t)cast(void*)handle) ~ " ; Timestamp: " ~ 
				to!string(timestamp) ~ " ; Type: " ~ to!string(type) ~ 
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
			case InputEventType.TextCommand:
				result ~= textCmd.toString();
				break;
			default:
				result ~= rawData.to!string();
				break;
		}
		result ~= "}";
		return result;
	}
}
package struct RawGCMapping {
	ubyte type;		///Type identifier
	ubyte flags;	///Flags related to translation, e.g. resolution, hat number
	ubyte inNum;	///Input axis/button number, or hat state
	ubyte outNum;	///Output axis/button number
	this (ubyte type, ubyte flags, ubyte inNum, ubyte outnum) @safe @nogc nothrow {
		this.type = type;
		this.flags = flags;
		this.inNum = inNum;
		this.outNum = outNum;
	}
	this (string src, ubyte outNum, bool isButtonTarget = false) @safe @nogc nothrow {
		switch (src[0]) {
		case 'a':
			if (isButtonTarget) type = RawGCMappingType.AxisToButton;
			else type = RawGCMappingType.Axis;
			inNum = cast(ubyte)parseNum(src[1..$]);
			break;
		case 'b':
			type = RawGCMappingType.Button;
			inNum = cast(ubyte)parseNum(src[1..$]);
			break;
		case 'h':
			type = RawGCMappingType.Hat;
			flags = cast(ubyte)parseNum(src[1..2]);
			inNum = cast(ubyte)parseNum(src[3..$]);
			break;
		default: break;
		}
		this.outNum = outNum;
	}
}
package enum RawGCMappingType : ubyte {
	init,
	Button,
	Axis,
	Trigger,
	Hat,
	AxisToButton,
}
/**
 * Parses SDL-compatible Game Controller mapping data.
 * Params:
 *   table = Table, where the data should be read from.
 *   uniq = Unique identifier of the game controller.
 * Returns: A table for mapping, or null if mapping couldn't be found.
 */
package RawGCMapping[] parseGCM(string table, string uniq) @safe {
	import std.algorithm : countUntil;
	string[] lines = table.splitLines();
	foreach (string line ; lines) {
		string[] vals = line.split(",");
		if (vals.length > 2) {
			if (vals[0] == uniq){
				RawGCMapping[] result;
				foreach (string val ; vals) {
					sizediff_t colonIndex = countUntil(val, ":");//used to separate data identifier from the data itself
					if (colonIndex <= 0) continue;	//Safety feature for when field does not have a colon (arbitrary data?)
					switch (val[0..colonIndex]) {
					case "a", "South":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.South, true);
						break;
					case "b", "East":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.East, true);
						break;
					case "x", "West":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.West, true);
						break;
					case "y", "North":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.North, true);
						break;
					case "dpup", "DPadUp":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.DPadUp, true);
						break;
					case "dpdown", "DPadDown":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.DPadDown, true);
						break;
					case "dpleft", "DPadLeft":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.DPadLeft, true);
						break;
					case "dpright", "DPadRight":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.DPadRight, true);
						break;
					case "leftshoulder", "LeftShoulder":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.LeftShoulder, true);
						break;
					case "rightshoulder", "RightShoulder":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.RightShoulder, true);
						break;
					case "lefttrigger", "LeftTrigger":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.LeftTrigger, true);
						break;
					case "righttrigger", "RightTrigger":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.RightTrigger, true);
						break;
					case "back", "LeftNav":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.LeftNav, true);
						break;
					case "start", "RightNav":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.RightNav, true);
						break;
					case "guide", "Home":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.Home, true);
						break;
					case "leftstick", "LeftThumbstick":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.LeftThumbstick, true);
						break;
					case "rightstick", "RightThumbstick":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.RightThumbstick, true);
						break;
					case "l4", "L4":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.L4, true);
						break;
					case "r4", "R4":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.R4, true);
						break;
					case "l5", "L5":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.L5, true);
						break;
					case "r5", "R5":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.R5, true);
						break;
					case "share", "Share":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.Share, true);
						break;
					case "touchpadclick", "TouchpadClick":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.TouchpadClick, true);
						break;
					case "btnv", "Btn_V":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.Btn_V, true);
						break;
					case "btnvi", "Btn_VI":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.Btn_VI, true);
						break;
					case "leftx", "LeftThumbstickX":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerAxes.LeftThumbstickX, true);
						break;
					case "lefty", "LeftThumbstickY":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerAxes.LeftThumbstickY, true);
						break;
					case "rightx", "RightThumbstickX":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerAxes.RightThumbstickX, true);
						break;
					case "righty", "RightThumbstickY":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerAxes.RightThumbstickY, true);
						break;
					case "accelx", "AccelX":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerAxes.AccelX, true);
						break;
					case "accely", "AccelY":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerAxes.AccelY, true);
						break;
					case "accelz", "AccelZ":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerAxes.AccelZ, true);
						break;
					case "rotatex", "RotateX":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerAxes.RotateX, true);
						break;
					case "rotatey", "RotateY":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerAxes.RotateY, true);
						break;
					case "rotatez", "RotateZ":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerAxes.RotateZ, true);
						break;
					case "touchpadx", "TouchpadX":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerAxes.TouchpadX, true);
						break;
					case "touchpady", "TouchpadY":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerAxes.TouchpadY, true);
						break;
					case "rtouchpadx", "RTouchpadX":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerAxes.RTouchpadX, true);
						break;
					case "rtouchpady", "RTouchpadY":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerAxes.RTouchpadY, true);
						break;
					default:
						break;
					}
				}
				return result;
			}
		}
	}
	return null;
}
package int parseNum(string num) @nogc @safe nothrow {
	int result;
	foreach (char c ; num) result = (result * 10) + (c - '0');
	return result;
}
