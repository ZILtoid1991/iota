module iota.controls.types;

public import core.time;
/*
 * If version `iota_uint_as_timestamp` is supplied, then uint will be used as the type for timestamps. If not, then 
 * MonoTime will be used instead, wuth greater resolution.
 */
version (iota_uint_as_timestamp) {
	alias Timestamp = uint;
} else {
	alias Timestamp = MonoTime;
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
	MIDI,				///If enabled, MIDI devices can function as regular input devices creating regular input events
}

public abstract class InputDevice {
	protected InputDeviceType   _type;		/// Defines the type of the input device
	protected ubyte             _devNum;	/// Defines the number of the input device
}