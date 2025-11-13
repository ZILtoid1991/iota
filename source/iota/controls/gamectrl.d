module iota.controls.gamectrl;

public import iota.controls.types;
// import iota.controls;

version (Windows) {
	import core.sys.windows.windows;
	import core.sys.windows.wtypes;
	import iota.controls.backend.windows;
} else version(OSX) {
    import cocoa.gamecontroller;
} else {
	import iota.controls.backend.linux;
}
/**
 * Defines standard codes for game controller buttons shared across device types.
 * Note: HID devices might not always follow this standard.
 */
public enum GameControllerButtons : ubyte {
	///Initial value, or no button has been pressed.
	none,
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
	///5th face button (C) if present
	Btn_V,
	///6th face button (Z) if present
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
	none,
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
public enum GameControllerLabels : ubyte {
	unknown,
	Nr0,
	Nr1,
	Nr2,
	Nr3,
	Nr4,
	Nr5,
	Nr6,
	Nr7,
	Nr8,
	Nr9,
	LtrA,
	LtrB,
	LtrC,
	LtrD,
	LtrE,
	LtrF,
	LtrG,
	LtrH,
	LtrI,
	LtrJ,
	LtrK,
	LtrL,
	LtrM,
	LtrN,
	LtrO,
	LtrP,
	LtrQ,
	LtrR,
	LtrS,
	LtrT,
	LtrU,
	LtrV,
	LtrW,
	LtrX,
	LtrY,
	LtrZ,
	SymSquare,
	SymCircle,
	SymCross,
	SymTriange,
	SymPlus,
	SymMinus,
	SymBrand,
	SymHome,
	SymStar,
	LblStart,
	LblSelect,
	LblBack,
	LblView,
	LblOption,
	LblRun,
	L1,
	L2,
	L3,
	L4,
	L5,
	R1,
	R2,
	R3,
	R4,
	R5,
	LB,
	LT,
	LSB,
	RB,
	RT,
	RSB,
	DPadUp,
	DPadDown,
	DPadLeft,
	DPadRight,
}
/**
 * Implements basic functionality common for all game controllers.
 */
abstract class GameController : InputDevice, HapticDevice {
	protected enum TriggerAsButton = 1<<8;
	protected float hapticGain = 1.0;
	/**
	 * Returns all capabilities of the haptic device.
	 */
	public abstract const(uint)[] getCapabilities() @safe nothrow;
	/**
	 * Returns all zones associated with the capability of the device.
	 * Returns null if zones are not applicable for the device's given capability.
	 */
	public abstract const(uint)[] getZones(uint capability) @safe nothrow;
	/**
	 * Applies a given effect.
	 * Params:
	 *   capability: The capability to be used.
	 *   zone: The zone where the effect should be used.
	 *   val: Either the strength of the capability (between 0.0 and 1.0), or the frequency.
	 * Returns: 0 on success, or a specific error code.
	 */
	public abstract int applyEffect(uint capability, uint zone, float val, float freq = float.nan) @trusted nothrow;
	/**
	 * Applies an envelop-style effect with variable
	 * Params:
	 *   capability = The capability to be used.
	 *   zone = The zone where the effect should be used.
	 *   stages = The stages of the envelop effect. 1: Attack stage, 2: Sustain stage, 3: Release stage
	 *   repeatCount = The count of repeats for this effect. 0 means the effect is played only once
	 *   repeatDelay = The delay between each repeats.
	 * Returns: 0 on success, or a specific error code.
	 */
	public int applyEnvelopEffect(uint capability, uint zone, HapticEnvelopStage[3] stages, uint repeatCount = 0,
			Duration repeatDelay = msecs(0)) @trusted nothrow {
		return -10;
	}
	/**
	 * Sets te maximum of all haptic effects.
	 * Params:
	 *   val = The gain to be set. 0.0 disables all haptic effects.
	 * Returns: 0 on success, or a specific error code.
	 */
	public int setMaximumGain(float val = 1.0) @trusted nothrow {
		hapticGain = val;
		return 0;
	}
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
		this(string _name, ubyte _devNum, HANDLE devHandle, RawGCMapping[] mapping) @nogc nothrow {
			this._name = _name;
			this._devNum = _devNum;
			this.hDevice = devHandle;
			this.mapping = mapping;
			_type = InputDeviceType.GameController;
			status |= StatusFlags.IsConnected;
		}
	} else version (linux) {
		int[8] hatStatus;
		this(string _name, ubyte _devNum, int fd, libevdev* hDevice, RawGCMapping[] mapping) @nogc nothrow {
			this._name = _name;
			this._devNum = _devNum;
			this.fd = fd;
			this.hDevice = hDevice;
			this.mapping = mapping;
			_type = InputDeviceType.GameController;
			status |= StatusFlags.IsConnected;
		}
	}
	override public const(uint)[] getCapabilities() @safe nothrow {
		return null; // TODO: implement
	}

	override public const(uint)[] getZones(uint capability) @safe nothrow {
		return null; // TODO: implement
	}

	override public int applyEffect(uint capability, uint zone, float val, float freq = float.nan) @trusted nothrow {
		return int.init; // TODO: implement
	}

	override public int reset() @trusted nothrow {
		return int.init; // TODO: implement
	}

}

version (Windows) {
	/**
	 * Implements functionalities related to XInput game controller devices. (Windows)
	 */
	public class XInputDevice : GameController {
		///Passed to XInputSetState.
		protected XINPUT_VIBRATION	vibr;
		///Stores info related to current and the previous state. Any events are calculated by the difference of the two.
		protected XINPUT_STATE		state, prevState;
		///Counter for properties within the controller.
		package static int			cntr;
		package static int			devC;
		package static XInputDevice[4]	ctrlList;
		this (DWORD userIndex, bool axisType) @nogc nothrow {
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
		// public override string toString() const @safe pure nothrow {
		// 	import std.conv : to;
		// 	return "{XInputDevice; DevID: " ~ devNum().to!string ~ "}";
		// }
		package static int poll(out InputEvent output) @system @nogc nothrow {
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
		public override const(uint)[] getCapabilities() @safe nothrow {
			static const(uint)[] result = [HapticDevice.Capabilities.LeftMotor, HapticDevice.Capabilities.RightMotor];
			return result;
		}
		/**
		* Returns all zones associated with the capability of the device.
		* Returns null if zones are not applicable for the device's given capability.
		*/
		public override const(uint)[] getZones(uint capability) @safe nothrow {
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
					vibr.wLeftMotorSpeed = cast(ushort)(val * hapticGain * ushort.max);
					if (XInputSetState(_devNum, &vibr) == ERROR_SUCCESS)
						return HapticDeviceStatus.AllOk;
					return HapticDeviceStatus.DeviceInvalidated;
				case HapticDevice.Capabilities.RightMotor:
					if (val < 0.0 || val > 1.0)
						return HapticDeviceStatus.OutOfRange;
					vibr.wRightMotorSpeed = cast(ushort)(val * hapticGain * ushort.max);
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

	public class GIGameController : GameController {
		package static IGameInput gameInputHandler;
		// package static IGameInputReading reading;
		package static InputEvent[] processedInputEvents;
		package static uint eventsIn;		///Position of events going in
		package static uint eventsOut;		///Position of events going out
		package static uint eventsModulo;	///Max number of events in buffer minus one
		package static GameInputCallbackToken callbackToken, sysToken;
		package static GIGameController[16] references;
		package static ubyte currCtrl = 0;
		package static ubyte allCtrls = 0;
		package static byte pollCntr = 0;
		package static bool triggerMode;
		extern (Windows) static void deviceCallback(GameInputCallbackToken callbackToken, void* context,
				IGameInputDevice device, ulong timestamp, uint currentStatus, uint previousStatus) @nogc nothrow {
			if ((currentStatus & GameInputDeviceStatus.GameInputDeviceConnected) != 0) {	//Device connected
				for (int i ; i < allCtrls ; i++) {
					if (references[i].deviceHandle is device) {

					}
				}
				import numem;
				references[allCtrls] = nogc_new!GIGameController(device);
				processedInputEvents[eventsOut & eventsModulo].timestamp = getTimestamp();
				processedInputEvents[eventsOut & eventsModulo].type = InputEventType.DeviceAdded;
				processedInputEvents[eventsOut & eventsModulo].source = references[allCtrls];
				import iota.controls.polling;
				devList ~= cast(InputDevice)references[allCtrls];
				eventsOut++;
				allCtrls++;
				debug {
					import core.stdc.stdio;
					printf("%i;%x \n", allCtrls, cast(void*)references[allCtrls-1]);
				}
			} else if ((previousStatus & GameInputDeviceStatus.GameInputDeviceConnected) != 0) {	//Device disconnected
				for (int i ; i < allCtrls ; i++) {
					if (references[i].deviceHandle is device) {
						references[i].status |= InputDevice.StatusFlags.IsInvalidated;
						processedInputEvents[eventsOut & eventsModulo].timestamp = getTimestamp();
						processedInputEvents[eventsOut & eventsModulo].type = InputEventType.DeviceRemoved;
						processedInputEvents[eventsOut & eventsModulo].source = references[i];
						eventsOut++;
						return;
					}
				}
			}
		}
		extern (Windows) static void sysButtonCallback(GameInputCallbackToken callbackToken, void* context,
		IGameInputDevice device, ulong timestamp, uint currentState, uint previousState) @nogc nothrow {
			for (int i ; i < allCtrls ; i++) {
				if (references[i].deviceHandle is device) {
					if ((currentState ^ previousState) == GameInputSystemButtons.GameInputSystemButtonGuide) {
						processedInputEvents[eventsOut & eventsModulo].timestamp = getTimestamp();
						processedInputEvents[eventsOut & eventsModulo].type = InputEventType.GCButton;
						processedInputEvents[eventsOut & eventsModulo].source = references[i];
						processedInputEvents[eventsOut & eventsModulo].button.id = GameControllerButtons.Home;
						processedInputEvents[eventsOut & eventsModulo].button.dir =
								(currentState & GameInputSystemButtons.GameInputSystemButtonGuide) != 0;
						processedInputEvents[eventsOut & eventsModulo].button.auxF = float.nan;
						processedInputEvents[eventsOut & eventsModulo].button.aux = 0;
						eventsOut++;
					}
					if ((currentState ^ previousState) == GameInputSystemButtons.GameInputSystemButtonShare) {
						processedInputEvents[eventsOut & eventsModulo].timestamp = getTimestamp();
						processedInputEvents[eventsOut & eventsModulo].type = InputEventType.GCButton;
						processedInputEvents[eventsOut & eventsModulo].source = references[i];
						processedInputEvents[eventsOut & eventsModulo].button.id = GameControllerButtons.Share;
						processedInputEvents[eventsOut & eventsModulo].button.dir =
								(currentState & GameInputSystemButtons.GameInputSystemButtonShare) != 0;
						processedInputEvents[eventsOut & eventsModulo].button.auxF = float.nan;
						processedInputEvents[eventsOut & eventsModulo].button.aux = 0;
						eventsOut++;
					}
					return;
				}
			}
		}
		static int poll(out InputEvent output) @system @nogc nothrow {
			void deviceEventCommons() @nogc nothrow {
				output.source = references[currCtrl];
				output.timestamp = getTimestamp();
			}
			if (eventsIn < eventsOut) {
				output = processedInputEvents[eventsIn & eventsModulo];
				eventsIn++;
				return 1;
			}
			if (currCtrl >= allCtrls) {
				currCtrl = 0;
				pollCntr = 0;
				for (int i ; i < allCtrls ; i++) {
					GIGameController gc = references[i];
					IGameInputReading reading;
					HRESULT st = gameInputHandler.GetCurrentReading(GameInputKind.GameInputKindGamepad, gc.deviceHandle, &reading);
					gc.prevState = gc.state;
					reading.GetGamepadState(&gc.state);
					reading.Release();
				}
			}
			while (currCtrl < allCtrls) {
				while (pollCntr < 20) {
					switch (pollCntr++) {
					case 0:
						if (references[currCtrl].state.leftThumbstickX != references[currCtrl].prevState.leftThumbstickX) {
							deviceEventCommons();
							output.type = InputEventType.GCAxis;
							output.axis.id = GameControllerAxes.LeftThumbstickX;
							// output.axis.raw = references[currCtrl].state.leftThumbstickX;
							output.axis.val = references[currCtrl].state.leftThumbstickX;
							return 1;
						}
						break;
					case 1:
						if (references[currCtrl].state.leftThumbstickY != references[currCtrl].prevState.leftThumbstickY) {
							deviceEventCommons();
							output.type = InputEventType.GCAxis;
							output.axis.id = GameControllerAxes.LeftThumbstickY;
							// output.axis.raw = references[currCtrl].state.leftThumbstickY;
							output.axis.val = references[currCtrl].state.leftThumbstickY;
							return 1;
						}
						break;
					case 2:
						if (references[currCtrl].state.rightThumbstickX != references[currCtrl].prevState.rightThumbstickX) {
							deviceEventCommons();
							output.type = InputEventType.GCAxis;
							output.axis.id = GameControllerAxes.RightThumbstickX;
							// output.axis.raw = references[currCtrl].state.rightThumbstickX;
							output.axis.val = references[currCtrl].state.rightThumbstickX;
							return 1;
						}
						break;
					case 3:
						if (references[currCtrl].state.rightThumbstickY != references[currCtrl].prevState.rightThumbstickY) {
							deviceEventCommons();
							output.type = InputEventType.GCAxis;
							output.axis.id = GameControllerAxes.RightThumbstickY;
							// output.axis.raw = references[currCtrl].state.rightThumbstickY;
							output.axis.val = references[currCtrl].state.rightThumbstickY;
						}
						return 1;
					case 4:
						if (references[currCtrl].state.leftTrigger != references[currCtrl].prevState.leftTrigger) {
							deviceEventCommons();
							if (triggerMode) {
								output.type = InputEventType.GCButton;
								output.button.id = GameControllerButtons.LeftTrigger;
								output.button.dir = references[currCtrl].state.leftTrigger != 0.0;
								output.button.auxF = references[currCtrl].state.leftTrigger;
							} else {
								output.type = InputEventType.GCAxis;
								output.axis.id = GameControllerAxes.LeftTrigger;
								output.axis.val = references[currCtrl].state.leftTrigger;
							}
							return 1;
						}
						break;
					case 5:
						if (references[currCtrl].state.rightTrigger != references[currCtrl].prevState.rightTrigger) {
							deviceEventCommons();
							if (triggerMode) {
								output.type = InputEventType.GCButton;
								output.button.id = GameControllerButtons.RightTrigger;
								output.button.dir = references[currCtrl].state.rightTrigger != 0.0;
								output.button.auxF = references[currCtrl].state.rightTrigger;
							} else {
								output.type = InputEventType.GCAxis;
								output.axis.id = GameControllerAxes.RightTrigger;
								output.axis.val = references[currCtrl].state.rightTrigger;
							}
							return 1;
						}
						break;
					case 6:
						if ((references[currCtrl].state.buttons ^ references[currCtrl].prevState.buttons) ==
								GameInputGamepadButtons.GameInputGamepadDPadUp) {
							deviceEventCommons();
							output.type = InputEventType.GCButton;
							output.button.id = GameControllerButtons.DPadUp;
							output.button.dir = (references[currCtrl].state.buttons & GameInputGamepadButtons.GameInputGamepadDPadUp) != 0;
							return 1;
						}
						break;
					case 7:
						if ((references[currCtrl].state.buttons ^ references[currCtrl].prevState.buttons) ==
								GameInputGamepadButtons.GameInputGamepadDPadDown) {
							deviceEventCommons();
							output.type = InputEventType.GCButton;
							output.button.id = GameControllerButtons.DPadDown;
							output.button.dir = (references[currCtrl].state.buttons & GameInputGamepadButtons.GameInputGamepadDPadDown) != 0;
							return 1;
						}
						break;
					case 8:
						if ((references[currCtrl].state.buttons ^ references[currCtrl].prevState.buttons) ==
								GameInputGamepadButtons.GameInputGamepadDPadLeft) {
							deviceEventCommons();
							output.type = InputEventType.GCButton;
							output.button.id = GameControllerButtons.DPadLeft;
							output.button.dir = (references[currCtrl].state.buttons & GameInputGamepadButtons.GameInputGamepadDPadLeft) != 0;
							return 1;
						}
						break;
					case 9:
						if ((references[currCtrl].state.buttons ^ references[currCtrl].prevState.buttons) ==
								GameInputGamepadButtons.GameInputGamepadDPadRight) {
							deviceEventCommons();
							output.type = InputEventType.GCButton;
							output.button.id = GameControllerButtons.DPadRight;
							output.button.dir =(references[currCtrl].state.buttons & GameInputGamepadButtons.GameInputGamepadDPadRight) != 0;
							return 1;
						}
						break;
					case 10:
						if ((references[currCtrl].state.buttons ^ references[currCtrl].prevState.buttons) ==
								GameInputGamepadButtons.GameInputGamepadA) {
							deviceEventCommons();
							output.type = InputEventType.GCButton;
							output.button.id = GameControllerButtons.South;
							output.button.dir = (references[currCtrl].state.buttons & GameInputGamepadButtons.GameInputGamepadA) != 0;
							return 1;
						}
						break;
					case 11:
						if ((references[currCtrl].state.buttons ^ references[currCtrl].prevState.buttons) ==
								GameInputGamepadButtons.GameInputGamepadB) {
							deviceEventCommons();
							output.type = InputEventType.GCButton;
							output.button.id = GameControllerButtons.East;
							output.button.dir = (references[currCtrl].state.buttons & GameInputGamepadButtons.GameInputGamepadB) != 0;
							return 1;
						}
						break;
					case 12:
						if ((references[currCtrl].state.buttons ^ references[currCtrl].prevState.buttons) ==
								GameInputGamepadButtons.GameInputGamepadX) {
							deviceEventCommons();
							output.type = InputEventType.GCButton;
							output.button.id = GameControllerButtons.West;
							output.button.dir = (references[currCtrl].state.buttons & GameInputGamepadButtons.GameInputGamepadX) != 0;
							return 1;
						}
						break;
					case 13:
						if ((references[currCtrl].state.buttons ^ references[currCtrl].prevState.buttons) ==
								GameInputGamepadButtons.GameInputGamepadY) {
							deviceEventCommons();
							output.type = InputEventType.GCButton;
							output.button.id = GameControllerButtons.North;
							output.button.dir = (references[currCtrl].state.buttons & GameInputGamepadButtons.GameInputGamepadY) != 0;
							return 1;
						}
						break;
					case 14:
						if ((references[currCtrl].state.buttons ^ references[currCtrl].prevState.buttons) ==
								GameInputGamepadButtons.GameInputGamepadLeftShoulder) {
							deviceEventCommons();
							output.type = InputEventType.GCButton;
							output.button.id = GameControllerButtons.LeftShoulder;
							output.button.dir = (references[currCtrl].state.buttons & GameInputGamepadButtons.GameInputGamepadLeftShoulder)
									!= 0;
							return 1;
						}
						break;
					case 15:
						if ((references[currCtrl].state.buttons ^ references[currCtrl].prevState.buttons) ==
								GameInputGamepadButtons.GameInputGamepadRightShoulder) {
							deviceEventCommons();
							output.type = InputEventType.GCButton;
							output.button.id = GameControllerButtons.RightShoulder;
							output.button.dir = (references[currCtrl].state.buttons & GameInputGamepadButtons.GameInputGamepadRightShoulder)
									!= 0;
							return 1;
						}
						break;
					case 16:
						if ((references[currCtrl].state.buttons ^ references[currCtrl].prevState.buttons) ==
								GameInputGamepadButtons.GameInputGamepadLeftThumbstick) {
							deviceEventCommons();
							output.type = InputEventType.GCButton;
							output.button.id = GameControllerButtons.LeftThumbstick;
							output.button.dir = (references[currCtrl].state.buttons & GameInputGamepadButtons.GameInputGamepadLeftThumbstick)
									!= 0;
							return 1;
						}
						break;
					case 17:
						if ((references[currCtrl].state.buttons ^ references[currCtrl].prevState.buttons) ==
								GameInputGamepadButtons.GameInputGamepadRightThumbstick) {
							deviceEventCommons();
							output.type = InputEventType.GCButton;
							output.button.id = GameControllerButtons.RightThumbstick;
							output.button.dir = (references[currCtrl].state.buttons &
									GameInputGamepadButtons.GameInputGamepadRightThumbstick) != 0;
							return 1;
						}
						break;
					case 18:
						if ((references[currCtrl].state.buttons ^ references[currCtrl].prevState.buttons) ==
								GameInputGamepadButtons.GameInputGamepadView) {
							deviceEventCommons();
							output.type = InputEventType.GCButton;
							output.button.id = GameControllerButtons.LeftNav;
							output.button.dir = (references[currCtrl].state.buttons & GameInputGamepadButtons.GameInputGamepadView)
									!= 0;
							return 1;
						}
						break;
					case 19:
						if ((references[currCtrl].state.buttons ^ references[currCtrl].prevState.buttons) ==
								GameInputGamepadButtons.GameInputGamepadMenu) {
							deviceEventCommons();
							output.type = InputEventType.GCButton;
							output.button.id = GameControllerButtons.RightNav;
							output.button.dir = (references[currCtrl].state.buttons & GameInputGamepadButtons.GameInputGamepadMenu)
									!= 0;
							return 1;
						}
						break;
					default:
						// currCtrl++;
						break;
					}
				}
				pollCntr = 0;
				currCtrl++;
			}
			//currCtrl = 0;
			return 0;
		}
		shared static ~this() {
			if (gameInputHandler) {
				gameInputHandler.Release();
			}
			import numem;
			nu_freea(processedInputEvents);
		}
		package IGameInputDevice deviceHandle;
		package GameInputGamepadState state, prevState;
		package GameInputRumbleParams rumbleParams;
		this(IGameInputDevice deviceHandle) @trusted @nogc nothrow {
			this.deviceHandle = deviceHandle;
			this.deviceHandle.AddRef();
			rumbleParams = GameInputRumbleParams(0.0, 0.0, 0.0, 0.0);
			state = GameInputGamepadState(0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
			prevState = GameInputGamepadState(0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
			status |= StatusFlags.IsHapticCapable; // TODO: Detect haptic capabilities!
		}
		~this() @nogc nothrow {
			this.deviceHandle.Release();
		}
		public override const(uint)[] getCapabilities() @safe nothrow {
			static const(uint)[] result = [HapticDevice.Capabilities.LeftMotor, HapticDevice.Capabilities.RightMotor,
					HapticDevice.Capabilities.TriggerRumble];
			return result;
		}
		public override const(uint)[] getZones(uint capability) @safe nothrow {
			if (capability == HapticDevice.Capabilities.TriggerRumble) {
				static const(uint)[] result = [HapticDevice.Zones.Left, HapticDevice.Zones.Right];
				return result;
			}
			return null;
		}
		/**
		 * Applies a simple effect.
		 * Params:
		 *   capability: The capability to be used.
		 *   zone: The zone where the effect should be used.
		 *   val: The strength of the capability (between 0.0 and 1.0).
		 *   freq: The frequency if supported, float.nan otherwise.
		 * Returns: 0 on success, or a specific error code.
		 * Note: Has an automatic timeout on certain API.
		 */
		public override int applyEffect(uint capability, uint zone, float val, float freq = float.nan) @nogc @trusted
			nothrow {
			if (deviceHandle is null) return HapticDeviceStatus.DeviceInvalidated;
			switch (capability) {
			case HapticDevice.Capabilities.LeftMotor:
				if (val < 0.0 || val > 1.0) return HapticDeviceStatus.OutOfRange;
				rumbleParams.lowFrequency = val * hapticGain;
				break;
			case HapticDevice.Capabilities.RightMotor:
				if (val < 0.0 || val > 1.0) return HapticDeviceStatus.OutOfRange;
				rumbleParams.highFrequency = val * hapticGain;
				break;
			case HapticDevice.Capabilities.TriggerRumble:
				if (val < 0.0 || val > 1.0) return HapticDeviceStatus.OutOfRange;
				switch (zone) {
				case HapticDevice.Zones.Left:
					rumbleParams.leftTrigger = val * hapticGain;
					break;
				case HapticDevice.Zones.Right:
					rumbleParams.rightTrigger = val * hapticGain;
					break;
				default: return HapticDeviceStatus.UnsupportedZone;
				}
				break;
			default: return HapticDeviceStatus.UnsupportedCapability;
			}
			deviceHandle.SetRumbleState(&rumbleParams);
			return HapticDeviceStatus.AllOk;
		}
		/**
		* Stops all haptic effects of the device.
		* Returns: 0 on success, or a specific error code.
		*/
		public override int reset() @nogc @trusted nothrow {
			rumbleParams.highFrequency = 0.0;
			rumbleParams.lowFrequency = 0.0;
			rumbleParams.leftTrigger = 0.0;
			rumbleParams.rightTrigger = 0.0;
			if (deviceHandle is null) return HapticDeviceStatus.DeviceInvalidated;
			deviceHandle.SetRumbleState(&rumbleParams);
			return HapticDeviceStatus.AllOk;
		}
	}
} else version (OSX) {
	public class GCGameController : GameController {
		protected GCController* controller;

		public override const(uint)[] getCapabilities() @safe nothrow {
			if (controller.haptics)
				return [HapticDevice.Capabilities.LeftMotor, HapticDevice.Capabilities.RightMotor];
			return null;
		}

		public override const(uint)[] getZones(uint capability) @safe nothrow {
			return null;
		}

   	    public override int applyEffect(uint capability, uint zone, float val, float freq = float.nan)
				@trusted nothrow {
			if (!controller.haptics)
				return HapticDeviceStatus.UnsupportedCapability;

			if (val < 0.0 || val > 1.0)
				return HapticDeviceStatus.OutOfRange;

			switch (capability) {
				case HapticDevice.Capabilities.LeftMotor:
					controller.haptics.createEngine(GCHapticsLocality.Left).createContinuousEvent(val);
					return HapticDeviceStatus.AllOk;
				case HapticDevice.Capabilities.RightMotor:
					controller.haptics.createEngine(GCHapticsLocality.Right).createContinuousEvent(val);
					return HapticDeviceStatus.AllOk;
				default:
					return HapticDeviceStatus.UnsupportedCapability;
			}
		}

		public override int reset() @trusted nothrow {
			if (controller.haptics) {
				controller.haptics.cancelAll();
				return HapticDeviceStatus.AllOk;
			}
			return HapticDeviceStatus.UnsupportedCapability;
		}
	}
}
