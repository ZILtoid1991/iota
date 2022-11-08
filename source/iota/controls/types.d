module iota.controls.types;

public import iota.window.oswindow;
import std.conv : to;
import std.bitmanip : bitfields;
/*
 * If `iota_hi_prec_timestamp` is supplied as a version identifier, then MonoTime will be used for timestamps, 
 * otherwise uint will be used.
 *
 * However it's not ensured that higher precision will be actually provided, or that it'll be useful.
 */
version (iota_hi_prec_timestamp) {
	public import core.time;
	alias Timestamp = MonoTime;
} else {
	alias Timestamp = uint;
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
	GCButton,
	GCAxis,
	GCHat,
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

	Insert,

	NewLine,	///Shift + Enter
	NewPara,	///Enter
	
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
}
/** 
 * Operating system specific flags
 */
public enum OSConfigFlags : uint {
	///Enables raw input under Windows for more capabilities.
	win_RawInput				=	1 << 0,
	///Uses the older Wintab over other options.
	win_Wintab					=	1 << 1,
	///Enables raw handling of mouse input data in Windows.
	///This enables differentiating between multiple mice and overriding OS sensitivity settings.
	win_RawMouse				=	1 << 2,
	///Enables raw handling of keyboard input data in Windows.
	///This enables diffetentiating between multiple keyboard devices.
	win_RawKeyboard				=	1 << 3,
}
/** 
 * Defines return codes for the `iota.controls.initInput` function.
 */
public enum InputInitializationStatus {
	AllOk					=	0,
	win_RawInputError		=	-1,
	win_DevicesAdded		=	-2,
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
	protected ushort			status;
	/**
	 * Defines common status codes
	 */
	public enum StatusFlags : ushort {
		IsConnected		=	1<<0,			///Set if device is connected
		IsInvalidated	=	1<<1,			///Set if device is invalidated (disconnected, etc.)
		HasBattery		=	1<<2,			///Set if device has a battery
		IsAnalog		=	1<<3,			///Set if device has analog capabilities
		IsVirtual		=	1<<4,			///Set if device is emulated/virtual (e.g. on-screen keyboard)
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
	/** 
	 * Polls the device for events.
	 * Params:
	 *   output = InputEvents outputted by the 
	 * Returns: 1 if there's still events to be polled, 0 if no events left. Other values are error codes.
	 */
	public abstract int poll(ref InputEvent output) nothrow;
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
				to!string(id) ~ " ; ";
	}
}
/** 
 * Defines the contents of a text input data.
 *
 * Version label `iota_use_utf8` will make the middleware to convert text input to UTF8 on non-UTF8 systems, leaving
 * it out will make UTF32 as the standard
 */
public struct TextInputEvent {
	version (iota_use_utf8)
		static enum CHARS_PER_PACKAGE = 16;
	else
		static enum CHARS_PER_PACKAGE = 4;
	///The characters 
	io_chr_t[CHARS_PER_PACKAGE] text;
	mixin(bitfields!(
			bool, "isClipboard",	1,	///True if the text input originates from a clipboard event.
			uint, "language",		31	///Input language code
	));
	//bool		isClipboard;///True if the text input originates from a clipboard event.
	string toString() @safe pure const {
		return "Text: \"" ~ to!string(text) ~ "\" isClipboard: " ~ to!string(isClipboard) ~ " ; "; 
	}
}
/** 
 * Defines text editing command events that could happen during a text input.
 */
public struct TextCommandEvent {
	TextCommandType	type;	///The type of the text editing event.
	int			amount;		///Amount of the event + direction, if applicable.
	uint		flags;		///Extra flags for text edit events.
}
/**
 * Defines an axis event.
 * Per-axis IDs are being used.
 */
public struct AxisEvent {
	uint		id;		///Identifier number of the axis.
	float		val;	///Current value of the axis (either -1.0 to 1.0 or 0.0 to 1.0)
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
	int			x;		///X position of the cursor
	int			y;		///Y position of the cursor
	int			xD;		///X amount of the motion
	int			yD;		///Y amount of the motion
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
		PenEvent			pen;
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
			default:
				break;
		}
		result ~= "}";
		return result;
	}
}