module iota.controls.gamectrl;

public import iota.controls.types;

version (Windows) {
	import core.sys.windows.windows;
	import core.sys.windows.wtypes;
	import iota.controls.backend.windows;
}

abstract class GameController : InputDevice {
	
}

version (Windows) public class XInputDevice : GameController {
	protected XINPUT_VIBRATION	vibr;
	protected XINPUT_STATE		state, prevState;
	protected int				cntr;
	protected enum TriggerAsButton = 1<<8;
	public this (DWORD userIndex, bool axisType) {
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