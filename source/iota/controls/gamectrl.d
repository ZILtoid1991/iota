module iota.controls.gamectrl;

public import iota.controls.types;

version (Windows) {
	import core.sys.windows.windows;
	import core.sys.windows.wtypes;
	import iota.controls.backend.windows;
	import iota.controls : RawGCMapping, RawGCMappingType;
}
/**
 * Defines standard codes for game controller buttons shared across device types.
 * Note: HID devices might not always follow this standard.
 */
public enum GameControllerButtons : ubyte {
	///Initial value, or no button has been pressed.
	init,
	DPadUp,
	DPadDown,
	DPadLeft,
	DPadRight,
	///The button to the north on the right hand side of the gamepad.
	///XB: Y, PS: ∆, N: X
	North,
	///The button to the south on the right hand side of the gamepad.
	///XB: A, PS: X, N: B
	South,
	///The button to the east on the right hand side of the gamepad.
	///XB: B, PS: O, N: A
	East,
	///The button to the west on the right hand side of the gamepad.
	///XB: X, PS: ▯, N: Y
	West,
	///The upper-left shoulder button (usually digital)
	LeftShoulder,
	///The upper-right shoulder button (usually digital)
	RightShoulder,
	///The lower-left shoulder button (usually analog), or a pedal
	LeftTrigger,
	///The lower-right shoulder button (usually analog), or a pedal
	RightTrigger,
	LeftThumbstick,
	RightThumbstick,
	///The navigation button on the left hand side of the controller.
	///XB: Back, PS: Select (formerly), N: Select
	LeftNav,
	///The navigation button on the right hand side of the controller.
	///XB: Start, PS: Start (formerly)/ Option, N: Start
	RightNav,
	TouchpadClick,
	Home,
	Share,
	///Paddle buttons
	L4,
	R4,
	L5,
	R5,
	///5th face button if present
	Btn_V,
	///6th face button if present
	Btn_VI
}
///Defines potential POV hat states as bitflags.
public enum POVHatStates : ubyte {
	N			=	0x01,
	W			=	0x02,
	S			=	0x04,
	E			=	0x08,
	NE			=	0x09,
	NW			=	0x03,
	SE			=	0x0C,
	SW			=	0x06,
}
///Defines game controller axes.
public enum GameControllerAxes : ubyte {
	init,
	///X axis of the left thumbstick, but is also used for joystick X and steering wheel
	LeftThumbstickX,
	///Y axis of the right thumbstick, but is also used for joystick Y
	LeftThumbstickY,
	RightThumbstickX,
	RightThumbstickY,
	LeftTrigger,
	RightTrigger,
	///Accelerometer X, Y, and Z values
	AccelX,
	AccelY,
	AccelZ,
	///Rotation X, Y, and Z values
	RotateX,
	RotateY,
	RotateZ,
	TouchpadX,
	TouchpadY,
	RTouchpadX,
	RTouchpadY,
}
/**
 * Implements basic functionality common for all game controllers.
 */
abstract class GameController : InputDevice, HapticDevice {
	protected enum TriggerAsButton = 1<<8;
	/**
	 * Returns all capabilities of the haptic device.
	 */
	public abstract uint[] getCapabilities() @safe nothrow;
	/**
	 * Returns all zones associated with the capability of the device.
	 * Returns null if zones are not applicable for the device's given capability.
	 */
	public abstract uint[] getZones(uint capability) @safe nothrow;
	/**
	 * Applies a given effect.
	 * Params:
	 *   capability: The capability to be used.
	 *   zone: The zone where the effect should be used.
	 *   val: Either the strength of the capability (between 0.0 and 1.0), or the frequency.
	 * Returns: 0 on success, or a specific error code.
	 */
	public abstract int applyEffect(uint capability, uint zone, float val, float freq = float.nan) nothrow;
	/**
	 * Stops all haptic effects of the device.
	 * Returns: 0 on success, or a specific error code.
	 */
	public abstract int reset() nothrow;
}
/**
 * Game controller class meant to be used with RawInput and libendev.
 */
public class RawInputGameController : GameController {
	package RawGCMapping[] mapping;
	version (Windows) {
		package this(string _name, ubyte _devNum, HANDLE devHandle, RawGCMapping[] mapping) nothrow {
			this._name = _name;
			this._devNum = _devNum;
			this.hDevice = devHandle;
			this.mapping = mapping;
			_type = InputDeviceType.GameController;
			status |= StatusFlags.IsConnected;
		}
	} else {
		package this(string _name, ubyte _devNum, int fd, libevdev* hDevice, RawGCMapping[] mapping) {
			this._name = _name;
			this._devNum = _devNum;
			this.fd = fd;
			this.hDevice = hDevice;
			this.mapping = mapping;
			_type = InputDeviceType.GameController;
			status |= StatusFlags.IsConnected;
		}
	}
	override public uint[] getCapabilities() @safe nothrow {
		return null; // TODO: implement
	}

	override public uint[] getZones(uint capability) @safe nothrow {
		return null; // TODO: implement
	}

	override public int applyEffect(uint capability, uint zone, float val, float freq = float.nan) @trusted nothrow {
		return int.init; // TODO: implement
	}

	override public int reset() @trusted nothrow {
		return int.init; // TODO: implement
	}

}
/**
 * Implements functionalities related to XInput game controller devices. (Windows)
 */
version (Windows) public class XInputDevice : GameController {
	///Passed to XInputSetState.
	protected XINPUT_VIBRATION	vibr;
	///Stores info related to current and the previous state. Any events are calculated by the difference of the two.
	protected XINPUT_STATE		state, prevState;
	///Counter for properties within the controller.
	package static int			cntr;
	package static int			devC;
	package static XInputDevice[4]	ctrlList;
	package this (DWORD userIndex, bool axisType) nothrow {
		XINPUT_CAPABILITIES xic;
		const DWORD result = XInputGetCapabilities(userIndex, 0, &xic);
		if (result == ERROR_SUCCESS && ctrlList[userIndex] is null) {
			if (axisType)
				status |= TriggerAsButton;
			//if (xic.Flags & XINPUT_CAPS.XINPUT_CAPS_FFB_SUPPORTED) 
			status |= StatusFlags.IsHapticCapable;
			XInputGetState(_devNum, &state);
			prevState = state;
			_devNum = cast(ubyte)userIndex;
			ctrlList[userIndex] = this;
		} else {
			status |= StatusFlags.IsInvalidated;
		}
	}
	public override string toString() const @safe pure nothrow {
		import std.conv : to;
		return "{XInputDevice; DevID: " ~ devNum().to!string ~ "}";
	}
	package static int poll(ref InputEvent output) @system @nogc nothrow {
		while (devC < ctrlList.length) {
			XInputDevice dev = ctrlList[devC];
			if (dev is null) {
				devC++;
				continue;
			}
			if (dev.isInvalidated) {
				devC++;
				ctrlList[devC] = null;
				continue;
			}
			if (cntr == 0) {
				dev.prevState = dev.state;
				const DWORD result = XInputGetState(dev.devNum, &dev.state);
				if (result != ERROR_SUCCESS) {
					dev.status |= StatusFlags.IsInvalidated;
					output.source = dev;
					output.type = InputEventType.DeviceRemoved;
					return EventPollStatus.HasMore;
				}
			}
			while (cntr < 20) {
				switch (cntr++) {
					case 0:
 						if (dev.state.Gamepad.bLeftTrigger != dev.prevState.Gamepad.bLeftTrigger) {
							if (dev.status & TriggerAsButton) {
								output.button.id = GameControllerButtons.LeftTrigger;
								output.button.auxF = dev.state.Gamepad.bLeftTrigger / 255.0;
								output.button.dir = dev.state.Gamepad.bLeftTrigger ? 1 : 0;
								goto case 257;
							} else {
								output.axis.id = GameControllerAxes.LeftTrigger;
								output.axis.val = dev.state.Gamepad.bLeftTrigger / 255.0;
								goto case 256;
							}
						}
						break;
					case 1:
						if (dev.state.Gamepad.bRightTrigger != dev.prevState.Gamepad.bRightTrigger) {
							if (dev.status & TriggerAsButton) {
								output.button.id = GameControllerButtons.RightTrigger;
								output.button.auxF = dev.state.Gamepad.bRightTrigger / 255.0;
								output.button.dir = dev.state.Gamepad.bRightTrigger ? 1 : 0;
								goto case 257;
							} else {
								output.axis.id = GameControllerAxes.RightTrigger;
								output.axis.val = dev.state.Gamepad.bRightTrigger / 255.0;
								goto case 256;
							}
						}
						break;
					case 2:
						if (dev.state.Gamepad.sThumbLX != dev.prevState.Gamepad.sThumbLX) {
							output.axis.id = GameControllerAxes.LeftThumbstickX;
							output.axis.val = dev.state.Gamepad.sThumbLX / 32_768.0;
							goto case 256;
						}
						break;
					case 3:
						if (dev.state.Gamepad.sThumbLY != dev.prevState.Gamepad.sThumbLY) {
							output.axis.id = GameControllerAxes.LeftThumbstickY;
							output.axis.val = dev.state.Gamepad.sThumbLY / 32_768.0;
							goto case 256;
						}
						break;
					case 4:
						if (dev.state.Gamepad.sThumbRX != dev.prevState.Gamepad.sThumbRX) {
							output.axis.id = GameControllerAxes.RightThumbstickX;
							output.axis.val = dev.state.Gamepad.sThumbRX / 32_768.0;
							goto case 256;
						}
						break;
					case 5:
						if (dev.state.Gamepad.sThumbRY != dev.prevState.Gamepad.sThumbRY) {
							output.axis.id = GameControllerAxes.RightThumbstickY;
							output.axis.val = dev.state.Gamepad.sThumbRY / 32_768.0;
							goto case 256;
						}
						break;
					case 6:
						if ((dev.state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_DPAD_UP) ^
								(dev.prevState.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_DPAD_UP)) {
							output.button.id = GameControllerButtons.DPadUp;
							output.button.dir = (dev.state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_DPAD_UP) ? 1 : 0;
							goto case 255;
						}
						break;
					case 7:
						if ((dev.state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_DPAD_DOWN) ^
								(dev.prevState.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_DPAD_DOWN)) {
							output.button.id = GameControllerButtons.DPadDown;
							output.button.dir = (dev.state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_DPAD_DOWN) ? 1 : 0;
							goto case 255;
						}
						break;
					case 8:
						if ((dev.state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_DPAD_LEFT) ^
								(dev.prevState.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_DPAD_LEFT)) {
							output.button.id = GameControllerButtons.DPadLeft;
							output.button.dir = (dev.state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_DPAD_LEFT) ? 1 : 0;
							goto case 255;
						}
						break;
					case 9:
						if ((dev.state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_DPAD_RIGHT) ^
								(dev.prevState.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_DPAD_RIGHT)) {
							output.button.id = GameControllerButtons.DPadRight;
							output.button.dir = (dev.state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_DPAD_RIGHT) ? 1 : 0;
							goto case 255;
						}
						break;
					case 10:
						if ((dev.state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_START) ^
								(dev.prevState.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_START)) {
							output.button.id = GameControllerButtons.RightNav;
							output.button.dir = (dev.state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_START) ? 1 : 0;
							goto case 255;
						}
						break;
					case 11:
						if ((dev.state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_BACK) ^
								(dev.prevState.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_BACK)) {
							output.button.id = GameControllerButtons.LeftNav;
							output.button.dir = (dev.state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_BACK) ? 1 : 0;
							goto case 255;
						}
						break;
					case 12:
						if ((dev.state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_LEFT_THUMB) ^
								(dev.prevState.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_LEFT_THUMB)) {
							output.button.id = GameControllerButtons.LeftThumbstick;
							output.button.dir = (dev.state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_LEFT_THUMB) ? 1 : 0;
							goto case 255;
						}
						break;
					case 13:
						if ((dev.state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_RIGHT_THUMB) ^
								(dev.prevState.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_RIGHT_THUMB)) {
							output.button.id = GameControllerButtons.RightThumbstick;
							output.button.dir = (dev.state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_RIGHT_THUMB) ? 1 : 0;
							goto case 255;
						}
						break;
					case 14:
						if ((dev.state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_LEFT_SHOULDER) ^
								(dev.prevState.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_LEFT_SHOULDER)) {
							output.button.id = GameControllerButtons.LeftShoulder;
							output.button.dir = (dev.state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_LEFT_SHOULDER) ? 1 : 0;
							goto case 255;
						}
						break;
					case 15:
						if ((dev.state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_RIGHT_SHOULDER) ^
								(dev.prevState.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_RIGHT_SHOULDER)) {
							output.button.id = GameControllerButtons.RightShoulder;
							output.button.dir = (dev.state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_RIGHT_SHOULDER) ? 1 : 0;
							goto case 255;
						}
						break;
					case 16:
						if ((dev.state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_A) ^
								(dev.prevState.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_A)) {
							output.button.id = GameControllerButtons.South;
							output.button.dir  = (dev.state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_A) ? 1 : 0;
							goto case 255;
						}
						break;
					case 17:
						if ((dev.state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_B) ^
								(dev.prevState.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_B)) {
							output.button.id = GameControllerButtons.East;
							output.button.dir = (dev.state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_B) ? 1 : 0;
							goto case 255;
						}
						break;
					case 18:
						if ((dev.state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_X) ^
								(dev.prevState.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_X)) {
							output.button.id = GameControllerButtons.West;
							output.button.dir = (dev.state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_X) ? 1 : 0;
							goto case 255;
						}
						break;
					case 19:
						if ((dev.state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_Y) ^
								(dev.prevState.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_Y)) {
							output.button.id = GameControllerButtons.North;
							output.button.dir = (dev.state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_Y) ? 1 : 0;
							goto case 255;
						}
						break;
					case 20:
						devC++;
						cntr = 0;
						output.type = InputEventType.init;
						return EventPollStatus.HasMore;
					case 255:	//Button events global
						output.type = InputEventType.GCButton;
						output.button.repeat = 0;
						output.button.aux = 0;
						output.button.auxF = float.nan;
						goto case 384;
					case 256:	//Axis of any kind
						output.type = InputEventType.GCAxis;
						goto case 384;
					case 257:	//Triggers when handled as buttons
						output.type = InputEventType.GCButton;
						output.button.repeat = 0;
						output.button.aux = 0;
						goto case 384;
					case 384:	//All event commons
						output.source = dev;
						output.timestamp = getTimestamp();
						return EventPollStatus.HasMore;
					default:
						break;
				}
			}
			devC++;
			//cntr = 0;
		}
		cntr = 0;
		devC = 0;
		return EventPollStatus.Done;
		
	}
	/**
	 * Returns all capabilities of the haptic device.
	 */
	public override uint[] getCapabilities() @safe nothrow {
		return [HapticDevice.Capabilities.LeftMotor, HapticDevice.Capabilities.RightMotor];
	}
	/**
	 * Returns all zones associated with the capability of the device.
	 * Returns null if zones are not applicable for the device's given capability.
	 */
	public override uint[] getZones(uint capability) @safe nothrow {
		return null;
	}
	/**
	 * Applies a given effect.
	 * Params:
	 *   capability: The capability to be used.
	 *   zone: The zone where the effect should be used.
	 *   val: Either the strength of the capability (between 0.0 and 1.0), or the frequency.
	 * Returns: 0 on success, or a specific error code.
	 */
	public override int applyEffect(uint capability, uint zone, float val, float freq = float.nan) @trusted nothrow {
		switch (capability) {
			case HapticDevice.Capabilities.LeftMotor:
				if (val < 0.0 || val > 1.0)
					return HapticDeviceStatus.OutOfRange;
				vibr.wLeftMotorSpeed = cast(ushort)(val * ushort.max);
				if (XInputSetState(_devNum, &vibr) == ERROR_SUCCESS)
					return HapticDeviceStatus.AllOk;
				return HapticDeviceStatus.DeviceInvalidated;
			case HapticDevice.Capabilities.RightMotor:
				if (val < 0.0 || val > 1.0)
					return HapticDeviceStatus.OutOfRange;
				vibr.wRightMotorSpeed = cast(ushort)(val * ushort.max);
				if (XInputSetState(_devNum, &vibr) == ERROR_SUCCESS)
					return HapticDeviceStatus.AllOk;
				return HapticDeviceStatus.DeviceInvalidated;
			default:
				return HapticDeviceStatus.UnsupportedCapability;
		}
	}
	/**
	 * Stops all haptic effects of the device.
	 * Returns: 0 on success, or a specific error code.
	 */
	public override int reset() @trusted nothrow {
		vibr.wLeftMotorSpeed = 0;
		vibr.wRightMotorSpeed = 0;
		if (XInputSetState(_devNum, &vibr) == ERROR_SUCCESS)
			return HapticDeviceStatus.AllOk;
		return HapticDeviceStatus.DeviceInvalidated;
	}
}