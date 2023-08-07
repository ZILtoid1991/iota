module iota.controls.gamectrl;

public import iota.controls.types;

version (Windows) {
	import core.sys.windows.windows;
	import core.sys.windows.wtypes;
	import iota.controls.backend.windows;
}
/**
 * Defines standard codes for game controller buttons shared across device types.
 * Note: HID devices might not follow this standard.
 */
public enum GameControllerButtons : ubyte {
	///Initial value, or no button has been pressed.
	init,
	DPadUp,
	DPadDown,
	DPadLeft,
	DPadRight,
	///The button to the north on the right hand side of the gamepad.
	///XB: Y, PS: Triangle, N: X
	North,
	///The button to the south on the right hand side of the gamepad.
	///XB: A, PS: X, N: B
	South,
	///The button to the south on the right hand side of the gamepad.
	///XB: B, PS: Circle, N: A
	East,
	///The button to the south on the right hand side of the gamepad.
	///XB: X, PS: Square, N: Y
	West,
	///The upper-left shoulder button (usually digital)
	LeftShoulder,
	///The upper-right shoulder button (usually digital)
	RightShoulder,
	///The lower-left shoulder button (usually analog)
	LeftTrigger,
	///The lower-right shoulder button (usually analog)
	RightTrigger,
	LeftThumbstick,
	RightThumbstick,
	///The navigation button on the left hand side of the controller.
	///XB: Back, PS: Select (formerly), N: Select
	LeftNav,
	///The navigation button on the right hand side of the controller.
	///XB: Start, PS: Start (formerly)/ Option, N: Start
	RightNav,
	Home,
	Share,
}
public enum GameControllerAxes : ubyte {
	init,
	LeftThumbstickX,
	LeftThumbstickY,
	RightThumbstickX,
	RightThumbstickY,
	LeftTrigger,
	RightTrigger,
}
/**
 * Implements basic functionality common for all game controllers.
 */
abstract class GameController : InputDevice, HapticDevice {
	protected enum TriggerAsButton = 1<<8;
	/**
	 * Returns all capabilities of the haptic device.
	 */
	public abstract uint[] getCapabilities() nothrow;
	/**
	 * Returns all zones associated with the capability of the device.
	 * Returns null if zones are not applicable for the device's given capability.
	 */
	public abstract uint[] getZones(uint capability) nothrow;
	/**
	 * Applies a given effect.
	 * Params:
	 *   capability: The capability to be used.
	 *   zone: The zone where the effect should be used.
	 *   val: Either the strength of the capability (between 0.0 and 1.0), or the frequency.
	 * Returns: 0 on success, or a specific error code.
	 */
	public abstract int applyEffect(uint capability, uint zone, float val) nothrow;
	/**
	 * Stops all haptic effects of the device.
	 * Returns: 0 on success, or a specific error code.
	 */
	public abstract int reset() nothrow;
}
/**
 * Implements functionalities related to XInput devices. (Windows)
 * 
 */
version (Windows) public class XInputDevice : GameController {
	///Passed to XInputSetState.
	protected XINPUT_VIBRATION	vibr;
	///Stores info related to current and the previous state. Any events are calculated by the difference of the two.
	protected XINPUT_STATE		state, prevState;
	///Counter for properties within the controller.
	protected int				cntr;
	package this (DWORD userIndex, bool axisType) nothrow {
		XINPUT_CAPABILITIES xic;
		const DWORD result = XInputGetCapabilities(userIndex, 0, &xic);
		if (result == ERROR_SUCCESS) {
			if (axisType)
				status |= TriggerAsButton;
			//if (xic.Flags & XINPUT_CAPS.XINPUT_CAPS_FFB_SUPPORTED) 
			status |= StatusFlags.IsHapticCapable;
			
			XInputGetState(_devNum, &state);
			prevState = state;
		} else {
			status |= StatusFlags.IsInvalidated;
		}
	}
	public override string toString() const @safe pure nothrow {
		import std.conv : to;
		return "XInputDevice; DevID: " ~ devNum().to!string;
	}
	public override int poll(ref InputEvent output) @nogc nothrow {
		
		if (cntr == 0) {
			prevState = state;
			const DWORD result = XInputGetState(_devNum, &state);
			if (result != ERROR_SUCCESS) {
				status |= StatusFlags.IsInvalidated;
				return EventPollStatus.DeviceInvalidated;
			}
		}
		while (cntr < 20) {
			switch (cntr++) {
				case 0:
					if (state.Gamepad.bLeftTrigger != prevState.Gamepad.bLeftTrigger) {
						output.source = this;
						output.timestamp = getTimestamp();
						if (status & TriggerAsButton) {
							output.type = InputEventType.GCButton;
							output.button.id = GameControllerButtons.LeftTrigger;
							output.button.auxF = state.Gamepad.bLeftTrigger / 255.0;
							output.button.dir = state.Gamepad.bLeftTrigger ? 1 : 0;
							output.button.repeat = 0;
							output.button.aux = 0;
						} else {
							output.type = InputEventType.GCAxis;
							output.axis.id = GameControllerAxes.LeftTrigger;
							output.axis.val = state.Gamepad.bLeftTrigger / 255.0;
						}
						return EventPollStatus.HasMore;
					}
					break;
				case 1:
					if (state.Gamepad.bRightTrigger != prevState.Gamepad.bRightTrigger) {
						output.source = this;
						output.timestamp = getTimestamp();
						if (status & TriggerAsButton) {
							output.type = InputEventType.GCButton;
							output.button.id = GameControllerButtons.RightTrigger;
							output.button.auxF = state.Gamepad.bRightTrigger / 255.0;
							output.button.dir = state.Gamepad.bRightTrigger ? 1 : 0;
							output.button.repeat = 0;
							output.button.aux = 0;
						} else {
							output.type = InputEventType.GCAxis;
							output.axis.id = GameControllerAxes.RightTrigger;
							output.axis.val = state.Gamepad.bRightTrigger / 255.0;
						}
						return EventPollStatus.HasMore;
					}
					break;
				case 2:
					if (state.Gamepad.sThumbLX != prevState.Gamepad.sThumbLX) {
						output.source = this;
						output.timestamp = getTimestamp();
						output.type = InputEventType.GCAxis;
						output.axis.id = GameControllerAxes.LeftThumbstickX;
						output.axis.val = state.Gamepad.sThumbLX / 32_768.0;
						return EventPollStatus.HasMore;
					}
					break;
				case 3:
					if (state.Gamepad.sThumbLY != prevState.Gamepad.sThumbLY) {
						output.source = this;
						output.timestamp = getTimestamp();
						output.type = InputEventType.GCAxis;
						output.axis.id = GameControllerAxes.LeftThumbstickY;
						output.axis.val = state.Gamepad.sThumbLY / 32_768.0;
						return EventPollStatus.HasMore;
					}
					break;
				case 4:
					if (state.Gamepad.sThumbRX != prevState.Gamepad.sThumbRX) {
						output.source = this;
						output.timestamp = getTimestamp();
						output.type = InputEventType.GCAxis;
						output.axis.id = GameControllerAxes.RightThumbstickX;
						output.axis.val = state.Gamepad.sThumbRX / 32_768.0;
						return EventPollStatus.HasMore;
					}
					break;
				case 5:
					if (state.Gamepad.sThumbRY != prevState.Gamepad.sThumbRY) {
						output.source = this;
						output.timestamp = getTimestamp();
						output.type = InputEventType.GCAxis;
						output.axis.id = GameControllerAxes.RightThumbstickY;
						output.axis.val = state.Gamepad.sThumbRY / 32_768.0;
						return EventPollStatus.HasMore;
					}
					break;
				case 6:
					if ((state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_DPAD_UP) ^
							(prevState.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_DPAD_UP)) {
						output.source = this;
						output.timestamp = getTimestamp();
						output.type = InputEventType.GCButton;
						output.button.id = GameControllerButtons.DPadUp;
						output.button.dir = (state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_DPAD_UP) ? 1 : 0;
						output.button.repeat = 0;
						output.button.aux = 0;
						output.button.auxF = float.nan;
						return EventPollStatus.HasMore;
					}
					break;
				case 7:
					if ((state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_DPAD_DOWN) ^
							(prevState.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_DPAD_DOWN)) {
						output.source = this;
						output.timestamp = getTimestamp();
						output.type = InputEventType.GCButton;
						output.button.id = GameControllerButtons.DPadDown;
						output.button.dir = (state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_DPAD_DOWN) ? 1 : 0;
						output.button.repeat = 0;
						output.button.aux = 0;
						output.button.auxF = float.nan;
						return EventPollStatus.HasMore;
					}
					break;
				case 8:
					if ((state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_DPAD_LEFT) ^
							(prevState.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_DPAD_LEFT)) {
						output.source = this;
						output.timestamp = getTimestamp();
						output.type = InputEventType.GCButton;
						output.button.id = GameControllerButtons.DPadLeft;
						output.button.dir = (state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_DPAD_LEFT) ? 1 : 0;
						output.button.repeat = 0;
						output.button.aux = 0;
						output.button.auxF = float.nan;
						return EventPollStatus.HasMore;
					}
					break;
				case 9:
					if ((state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_DPAD_RIGHT) ^
							(prevState.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_DPAD_RIGHT)) {
						output.source = this;
						output.timestamp = getTimestamp();
						output.type = InputEventType.GCButton;
						output.button.id = GameControllerButtons.DPadRight;
						output.button.dir = (state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_DPAD_RIGHT) ? 1 : 0;
						output.button.repeat = 0;
						output.button.aux = 0;
						output.button.auxF = float.nan;
						return EventPollStatus.HasMore;
					}
					break;
				case 10:
					if ((state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_START) ^
							(prevState.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_START)) {
						output.source = this;
						output.timestamp = getTimestamp();
						output.type = InputEventType.GCButton;
						output.button.id = GameControllerButtons.RightNav;
						output.button.dir = (state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_START) ? 1 : 0;
						output.button.repeat = 0;
						output.button.aux = 0;
						output.button.auxF = float.nan;
						return EventPollStatus.HasMore;
					}
					break;
				case 11:
					if ((state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_BACK) ^
							(prevState.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_BACK)) {
						output.source = this;
						output.timestamp = getTimestamp();
						output.type = InputEventType.GCButton;
						output.button.id = GameControllerButtons.LeftNav;
						output.button.dir = (state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_BACK) ? 1 : 0;
						output.button.repeat = 0;
						output.button.aux = 0;
						output.button.auxF = float.nan;
						return EventPollStatus.HasMore;
					}
					break;
				case 12:
					if ((state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_LEFT_THUMB) ^
							(prevState.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_LEFT_THUMB)) {
						output.source = this;
						output.timestamp = getTimestamp();
						output.type = InputEventType.GCButton;
						output.button.id = GameControllerButtons.LeftThumbstick;
						output.button.dir = (state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_LEFT_THUMB) ? 1 : 0;
						output.button.repeat = 0;
						output.button.aux = 0;
						output.button.auxF = float.nan;
						return EventPollStatus.HasMore;
					}
					break;
				case 13:
					if ((state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_RIGHT_THUMB) ^
							(prevState.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_RIGHT_THUMB)) {
						output.source = this;
						output.timestamp = getTimestamp();
						output.type = InputEventType.GCButton;
						output.button.id = GameControllerButtons.RightThumbstick;
						output.button.dir = (state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_RIGHT_THUMB) ? 1 : 0;
						output.button.repeat = 0;
						output.button.aux = 0;
						output.button.auxF = float.nan;
						return EventPollStatus.HasMore;
					}
					break;
				case 14:
					if ((state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_LEFT_SHOULDER) ^
							(prevState.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_LEFT_SHOULDER)) {
						output.source = this;
						output.timestamp = getTimestamp();
						output.type = InputEventType.GCButton;
						output.button.id = GameControllerButtons.LeftShoulder;
						output.button.dir = (state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_LEFT_SHOULDER) ? 1 : 0;
						output.button.repeat = 0;
						output.button.aux = 0;
						output.button.auxF = float.nan;
						return EventPollStatus.HasMore;
					}
					break;
				case 15:
					if ((state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_RIGHT_SHOULDER) ^
							(prevState.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_RIGHT_SHOULDER)) {
						output.source = this;
						output.timestamp = getTimestamp();
						output.type = InputEventType.GCButton;
						output.button.id = GameControllerButtons.RightShoulder;
						output.button.dir = (state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_RIGHT_SHOULDER) ? 1 : 0;
						output.button.repeat = 0;
						output.button.aux = 0;
						output.button.auxF = float.nan;
						return EventPollStatus.HasMore;
					}
					break;
				case 16:
					if ((state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_A) ^
							(prevState.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_A)) {
						output.source = this;
						output.timestamp = getTimestamp();
						output.type = InputEventType.GCButton;
						output.button.id = GameControllerButtons.South;
						output.button.dir = (state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_A) ? 1 : 0;
						output.button.repeat = 0;
						output.button.aux = 0;
						output.button.auxF = float.nan;
						return EventPollStatus.HasMore;
					}
					break;
				case 17:
					if ((state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_B) ^
							(prevState.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_B)) {
						output.source = this;
						output.timestamp = getTimestamp();
						output.type = InputEventType.GCButton;
						output.button.id = GameControllerButtons.East;
						output.button.dir = (state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_B) ? 1 : 0;
						output.button.repeat = 0;
						output.button.aux = 0;
						output.button.auxF = float.nan;
						return EventPollStatus.HasMore;
					}
					break;
				case 18:
					if ((state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_X) ^
							(prevState.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_X)) {
						output.source = this;
						output.timestamp = getTimestamp();
						output.type = InputEventType.GCButton;
						output.button.id = GameControllerButtons.West;
						output.button.dir = (state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_X) ? 1 : 0;
						output.button.repeat = 0;
						output.button.aux = 0;
						output.button.auxF = float.nan;
						return EventPollStatus.HasMore;
					}
					break;
				case 19:
					if ((state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_Y) ^
							(prevState.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_Y)) {
						output.source = this;
						output.timestamp = getTimestamp();
						output.type = InputEventType.GCButton;
						output.button.id = GameControllerButtons.North;
						output.button.dir = (state.Gamepad.wButtons & XINPUT_BUTTONS.XINPUT_GAMEPAD_Y) ? 1 : 0;
						output.button.repeat = 0;
						output.button.aux = 0;
						output.button.auxF = float.nan;
						return EventPollStatus.HasMore;
					}
					break;
				default:
					cntr = 0;
					return EventPollStatus.Done;
			}
		}			
		cntr = 0;
		return EventPollStatus.Done;
		
	}
	/**
	 * Returns all capabilities of the haptic device.
	 */
	public override uint[] getCapabilities() nothrow {
		return [HapticDevice.Capabilities.LeftMotor, HapticDevice.Capabilities.RightMotor];
	}
	/**
	 * Returns all zones associated with the capability of the device.
	 * Returns null if zones are not applicable for the device's given capability.
	 */
	public override uint[] getZones(uint capability) nothrow {
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
	public override int applyEffect(uint capability, uint zone, float val) nothrow {
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
	public override int reset() nothrow {
		vibr.wLeftMotorSpeed = 0;
		vibr.wRightMotorSpeed = 0;
		if (XInputSetState(_devNum, &vibr) == ERROR_SUCCESS)
			return HapticDeviceStatus.AllOk;
		return HapticDeviceStatus.DeviceInvalidated;
	}
}