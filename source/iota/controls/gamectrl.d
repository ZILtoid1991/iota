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
public enum GameControllerButtons {
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
	LeftShoulder,
	RightShoulder,
	LeftTrigger,
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
/**
 * Implements basic functionality common for all game controllers.
 */
abstract class GameController : InputDevice {
	
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
	protected enum TriggerAsButton = 1<<8;
	package this (DWORD userIndex, bool axisType) {
		XINPUT_CAPABILITIES xic;
		const DWORD result = XInputGetCapabilities(userIndex, 0, &xic);
		if (result == ERROR_SUCCESS) {
			if (axisType)
				status |= TriggerAsButton;
			if (xic.Flags & XINPUT_CAPS.XINPUT_CAPS_FFB_SUPPORTED) {

			}
		} else {
			status |= StatusFlags.IsInvalidated;
		}
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
		if (cntr < 0) {
			while (cntr < 0) {
				switch (cntr) {
					case 0:
						if (state.Gamepad.bLeftTrigger != prevState.Gamepad.bLeftTrigger) {
							output.source = this;
							if (status & TriggerAsButton) {
								output.type = InputEventType.GCButton;
								//output.button.id = 
							} else {

							}
						}
						break;
					default:
						break;
				}
				cntr++;
			}
			return EventPollStatus.Done;
		} else {
			cntr = 0;
			return EventPollStatus.Done;
		}
	}
}