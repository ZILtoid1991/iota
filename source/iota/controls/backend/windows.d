module iota.controls.backend.windows;
//Contains XInput bindings
version (Windows):

import nulib.system.win32.windows;
import nulib.system.win32.wtypes;
import nulib.system.win32.basetyps;
import core.stdc.stdint;
import iota.etc.backend_windows;
import nulib.system.com.unk;


@nogc nothrow:

struct XINPUT_BATTERY_INFORMATION {
	BYTE BatteryType;
	BYTE BatteryLevel;
}

enum XINPUT_BATTERY_TYPE : BYTE {
	BATTERY_TYPE_DISCONNECTED,
	BATTERY_TYPE_WIRED,
	BATTERY_TYPE_ALKALINE,
	BATTERY_TYPE_NIMH,
	BATTERY_TYPE_UNKNOWN
}

enum XINPUT_BATTERY_LEVEL : BYTE {
	BATTERY_LEVEL_EMPTY,
	BATTERY_LEVEL_LOW,
	BATTERY_LEVEL_MEDIUM,
	BATTERY_LEVEL_FULL
}

struct XINPUT_CAPABILITIES {
	BYTE				Type;
	BYTE				SubType;
	WORD				Flags;
	XINPUT_GAMEPAD		Gamepad;
	XINPUT_VIBRATION	Vibration;
}

enum XINPUT_DEVTYPE : BYTE {
	XINPUT_DEVSUBTYPE_UNKNOWN = 0x00,
	XINPUT_DEVTYPE_GAMEPAD = 0x01,
	XINPUT_DEVSUBTYPE_GAMEPAD = XINPUT_DEVTYPE_GAMEPAD,
	XINPUT_DEVSUBTYPE_WHEEL = 0x02,
	XINPUT_DEVSUBTYPE_ARCADE_STICK = 0x03,
	XINPUT_DEVSUBTYPE_FLIGHT_STICK = 0x04,
	XINPUT_DEVSUBTYPE_DANCE_PAD = 0x05,
	XINPUT_DEVSUBTYPE_GUITAR = 0x06,
	XINPUT_DEVSUBTYPE_GUITAR_ALTERNATE = 0x07,
	XINPUT_DEVSUBTYPE_DRUM_KIT = 0x08,
	XINPUT_DEVSUBTYPE_GUITAR_BASS = 0x0B,
	XINPUT_DEVSUBTYPE_ARCADE_PAD = 0x13,
}

enum XINPUT_CAPS : WORD {
	XINPUT_CAPS_VOICE_SUPPORTED = 0x0004,
	XINPUT_CAPS_FFB_SUPPORTED = 0x0001,
	XINPUT_CAPS_WIRELESS = 0x0002,
	XINPUT_CAPS_PMD_SUPPORTED = 0x0008,
	XINPUT_CAPS_NO_NAVIGATION = 0x0010,
}

struct XINPUT_VIBRATION {
	WORD wLeftMotorSpeed;
	WORD wRightMotorSpeed;
}

struct XINPUT_STATE {
	DWORD			dwPacketNumber;
	XINPUT_GAMEPAD	Gamepad;
}

struct XINPUT_GAMEPAD {
	WORD	wButtons;
	BYTE	bLeftTrigger;
	BYTE	bRightTrigger;
	SHORT	sThumbLX;
	SHORT	sThumbLY;
	SHORT	sThumbRX;
	SHORT	sThumbRY;
}

enum XINPUT_BUTTONS : WORD {
	XINPUT_GAMEPAD_DPAD_UP			= 0x0001,
	XINPUT_GAMEPAD_DPAD_DOWN		= 0x0002,
	XINPUT_GAMEPAD_DPAD_LEFT		= 0x0004,
	XINPUT_GAMEPAD_DPAD_RIGHT		= 0x0008,
	XINPUT_GAMEPAD_START			= 0x0010,
	XINPUT_GAMEPAD_BACK				= 0x0020,
	XINPUT_GAMEPAD_LEFT_THUMB		= 0x0040,
	XINPUT_GAMEPAD_RIGHT_THUMB		= 0x0080,
	XINPUT_GAMEPAD_LEFT_SHOULDER	= 0x0100,
	XINPUT_GAMEPAD_RIGHT_SHOULDER	= 0x0200,
	XINPUT_GAMEPAD_A				= 0x1000,
	XINPUT_GAMEPAD_B				= 0x2000,
	XINPUT_GAMEPAD_X				= 0x4000,
	XINPUT_GAMEPAD_Y				= 0x8000,
}

struct XINPUT_KEYSTROKE {
	WORD	VirtualKey;
	WCHAR	Unicode;
	WORD	Flags;
	BYTE	UserIndex;
	BYTE	HidCode;
}

enum XINPUT_VK : WORD {
	VK_PAD_A = 0x5800,
	VK_PAD_B = 0x5801,
	VK_PAD_X = 0x5802,
	VK_PAD_Y = 0x5803,
	VK_PAD_RSHOULDER = 0x5804,
	VK_PAD_LSHOULDER = 0x5805,
	VK_PAD_LTRIGGER = 0x5806,
	VK_PAD_RTRIGGER = 0x5807,

	VK_PAD_DPAD_UP = 0x5810,
	VK_PAD_DPAD_DOWN = 0x5811,
	VK_PAD_DPAD_LEFT = 0x5812,
	VK_PAD_DPAD_RIGHT = 0x5813,
	VK_PAD_START = 0x5814,
	VK_PAD_BACK = 0x5815,
	VK_PAD_LTHUMB_PRESS = 0x5816,
	VK_PAD_RTHUMB_PRESS = 0x5817,

	VK_PAD_LTHUMB_UP = 0x5820,
	VK_PAD_LTHUMB_DOWN = 0x5821,
	VK_PAD_LTHUMB_RIGHT = 0x5822,
	VK_PAD_LTHUMB_LEFT = 0x5823,
	VK_PAD_LTHUMB_UPLEFT = 0x5824,
	VK_PAD_LTHUMB_UPRIGHT = 0x5825,
	VK_PAD_LTHUMB_DOWNRIGHT = 0x5826,
	VK_PAD_LTHUMB_DOWNLEFT = 0x5827,

	VK_PAD_RTHUMB_UP = 0x5830,
	VK_PAD_RTHUMB_DOWN = 0x5831,
	VK_PAD_RTHUMB_RIGHT = 0x5832,
	VK_PAD_RTHUMB_LEFT = 0x5833,
	VK_PAD_RTHUMB_UPLEFT = 0x5834,
	VK_PAD_RTHUMB_UPRIGHT = 0x5835,
	VK_PAD_RTHUMB_DOWNRIGHT = 0x5836,
	VK_PAD_RTHUMB_DOWNLEFT = 0x5837,
}

public extern(Windows) {
	void XInputEnable(BOOL enable);
	DWORD XInputGetAudioDeviceIds(DWORD  dwUserIndex, LPWSTR pRenderDeviceId, UINT* pRenderCount, LPWSTR pCaptureDeviceId, 
			UINT *pCaptureCount);
	DWORD XInputGetBatteryInformation(DWORD dwUserIndex, BYTE devType, XINPUT_BATTERY_INFORMATION* pBatteryInformation);
	DWORD XInputGetCapabilities(DWORD dwUserIndex, DWORD dwFlags, XINPUT_CAPABILITIES* pCapabilities);
	DWORD XInputGetState(DWORD dwUserIndex, XINPUT_STATE* pState);
	DWORD XInputSetState(DWORD dwUserIndex, XINPUT_VIBRATION* pVibration);
}
// GameInput API begins

extern(Windows):

struct APP_LOCAL_DEVICE_ID {
	BYTE[32] value;
}
HRESULT GameInputCreate(IGameInput* gameInput);
alias GameInputCallbackToken = ulong;
enum GameInputKind
{
	GameInputKindUnknown = 0x00000000,
	GameInputKindRawDeviceReport = 0x00000001,
	GameInputKindControllerAxis   = 0x00000002,
	GameInputKindControllerButton = 0x00000004,
	GameInputKindControllerSwitch = 0x00000008,
	GameInputKindController = 0x0000000E,
	GameInputKindKeyboard = 0x00000010,
	GameInputKindMouse = 0x00000020,
	GameInputKindTouch = 0x00000100,
	GameInputKindMotion = 0x00001000,
	GameInputKindArcadeStick = 0x00010000,
	GameInputKindFlightStick = 0x00020000,
	GameInputKindGamepad = 0x00040000,
	GameInputKindRacingWheel = 0x00080000,
	GameInputKindUiNavigation = 0x01000000
}
version (IOTA_WINGAMEINPUT_V0) {
	const IID IID_IGameInput = makeGuid!"11BE2A7E-4254-445A-9C09-FFC40F006918";
	interface IGameInput : IUnknown {
	extern(Windows) @nogc nothrow:
		uint64_t GetCurrentTimestamp();
		HRESULT GetCurrentReading(GameInputKind inputKind, IGameInputDevice device, IGameInputReading* reading);
		HRESULT GetNextReading(IGameInputReading referenceReading, GameInputKind inputKind, IGameInputDevice device,
				IGameInputReading* reading);
		HRESULT GetPreviousReading(IGameInputReading referenceReading, GameInputKind inputKind, IGameInputDevice device,
				IGameInputReading* reading);
		HRESULT GetTemporalReading(uint64_t timestamp, IGameInputDevice device, IGameInputReading* reading); //Note: This function is not yet implemented.
		HRESULT RegisterReadingCallback(IGameInputDevice device, GameInputKind inputKind, float analogThreshold,
				void* context, GameInputReadingCallback callbackFunc, GameInputCallbackToken* callbackToken);
		HRESULT RegisterDeviceCallback(IGameInputDevice device, GameInputKind inputKind, uint statusFilter,
				GameInputEnumerationKind enumerationKind, void* context, GameInputDeviceCallback callbackFunc,
				GameInputCallbackToken* callbackToken);
		HRESULT RegisterGuideButtonCallback(IGameInputDevice device, void* context, GameInputGuideButtonCallback callbackFunc,
				GameInputCallbackToken* callbackToken);	//Warning: Deprecated, use system button callback instead!
		HRESULT RegisterKeyboardLayoutCallback(IGameInputDevice device, void* context,
				GameInputKeyboardLayoutCallback callbackFunc, GameInputCallbackToken* callbackToken);
		void StopCallback(GameInputCallbackToken callbackToken);
		bool UnregisterCallback(GameInputCallbackToken callbackToken, uint64_t timeoutInMicroseconds);
		HRESULT CreateDispatcher(IGameInputDispatcher* dispatcher);
		HRESULT CreateAggregateDevice(GameInputKind inputKind, IGameInputDevice* device); //Note: This function is not yet implemented.
		HRESULT FindDeviceFromId(const APP_LOCAL_DEVICE_ID* value, IGameInputDevice* device);
		HRESULT FindDeviceFromObject(IUnknown value, IGameInputDevice* device);
		HRESULT FindDeviceFromPlatformHandle(HANDLE value, IGameInputDevice* device);
		HRESULT FindDeviceFromPlatformString(LPCWSTR value, IGameInputDevice* device);
		HRESULT EnableOemDeviceSupport(uint16_t vendorId, uint16_t productId, uint8_t interfaceNumber,
				uint8_t collectionNumber);
		void SetFocusPolicy(uint policy);
		//HRESULT RegisterSystemButtonCallback(IGameInputDevice* device, uint buttonFilter, void* context,
		//		GameInputSystemButtonCallback callbackFunc, GameInputCallbackToken* callbackToken);
	}

	const IID IID_IGameInputDevice = makeGuid!"31DD86FB-4C1B-408A-868F-439B3CD47125";
	interface IGameInputDevice : IUnknown {
	extern(Windows) @nogc nothrow:
		GameInputDeviceInfo* GetDeviceInfo();
		GameInputDeviceStatus GetDeviceStatus();
		void GetBatteryState(GameInputBatteryState* state);	//Note: This function is not yet implemented.
		HRESULT CreateForceFeedbackEffect(uint32_t motorIndex, const(GameInputForceFeedbackParams)* params,
				IGameInputForceFeedbackEffect* effect);
		bool IsForceFeedbackMotorPoweredOn(uint32_t motorIndex);
		void SetForceFeedbackMotorGain(uint32_t motorIndex, float masterGain);
		HRESULT SetHapticMotorState(uint32_t motorIndex, const GameInputHapticFeedbackParams* params);//Note: This function is not yet implemented.
		void SetRumbleState(const(GameInputRumbleParams)* params);
		void SetInputSynchronizationState(bool enabled);
		void SendInputSynchronizationHint();
		void PowerOff(); //Note: This function is not yet implemented.
		HRESULT CreateRawDeviceReport(uint32_t reportId, GameInputRawDeviceReportKind reportKind,
				IGameInputRawDeviceReport* report);	//Note: This function is not yet implemented.
		HRESULT GetRawDeviceFeature(uint32_t reportId, IGameInputRawDeviceReport* report); //Note: This function is not yet implemented.
		HRESULT SetRawDeviceFeature(IGameInputRawDeviceReport report);//Note: This function is not yet implemented.
		HRESULT SendRawDeviceOutput(IGameInputRawDeviceReport report);	//Note: This function is not yet implemented.
		HRESULT ExecuteRawDeviceIoControl(uint32_t controlCode, size_t inputBufferSize, const(void)* inputBuffer,
				size_t outputBufferSize, void* outputBuffer, size_t* outputSize);	//Note: This function is not yet implemented.
		bool AcquireExclusiveRawDeviceAccess(uint64_t timeoutInMicroseconds);	//Note: This function is not yet implemented.
		void ReleaseExclusiveRawDeviceAccess();//Note: This function is not yet implemented.
	}
} else {
	const IID IID_IGameInput = makeGuid!"40FFB7E4-6150-407A-B439-132BADC08D2D";
	interface IGameInput : IUnknown {
	extern(Windows) @nogc nothrow:
		uint64_t GetCurrentTimestamp();
		HRESULT GetCurrentReading(GameInputKind inputKind, IGameInputDevice device, IGameInputReading* reading);
		HRESULT GetNextReading(IGameInputReading referenceReading, GameInputKind inputKind, IGameInputDevice device,
				IGameInputReading* reading);
		HRESULT GetPreviousReading(IGameInputReading referenceReading, GameInputKind inputKind, IGameInputDevice device,
				IGameInputReading* reading);
		HRESULT GetTemporalReading(uint64_t timestamp, IGameInputDevice device, IGameInputReading* reading); //Note: This function is not yet implemented.
		HRESULT RegisterReadingCallback(IGameInputDevice device, GameInputKind inputKind, float analogThreshold,
				void* context, GameInputReadingCallback callbackFunc, GameInputCallbackToken* callbackToken);
		HRESULT RegisterDeviceCallback(IGameInputDevice device, GameInputKind inputKind, uint statusFilter,
				GameInputEnumerationKind enumerationKind, void* context, GameInputDeviceCallback callbackFunc,
				GameInputCallbackToken* callbackToken);
		HRESULT RegisterSystemButtonCallback(IGameInputDevice* device, uint buttonFilter, void* context,
				GameInputSystemButtonCallback callbackFunc, GameInputCallbackToken* callbackToken);
		// HRESULT RegisterGuideButtonCallback(IGameInputDevice device, void* context, GameInputGuideButtonCallback callbackFunc,
				// GameInputCallbackToken* callbackToken);	//Warning: Deprecated, use system button callback instead!
		HRESULT RegisterKeyboardLayoutCallback(IGameInputDevice device, void* context,
				GameInputKeyboardLayoutCallback callbackFunc, GameInputCallbackToken* callbackToken);
		void StopCallback(GameInputCallbackToken callbackToken);
		bool UnregisterCallback(GameInputCallbackToken callbackToken, uint64_t timeoutInMicroseconds);
		HRESULT CreateDispatcher(IGameInputDispatcher* dispatcher);
		HRESULT CreateAggregateDevice(GameInputKind inputKind, IGameInputDevice* device); //Note: This function is not yet implemented.
		HRESULT FindDeviceFromId(const APP_LOCAL_DEVICE_ID* value, IGameInputDevice* device);
		HRESULT FindDeviceFromObject(IUnknown value, IGameInputDevice* device);
		HRESULT FindDeviceFromPlatformHandle(HANDLE value, IGameInputDevice* device);
		HRESULT FindDeviceFromPlatformString(LPCWSTR value, IGameInputDevice* device);
		HRESULT EnableOemDeviceSupport(uint16_t vendorId, uint16_t productId, uint8_t interfaceNumber,
				uint8_t collectionNumber);
		void SetFocusPolicy(uint policy);
	}
	const IID IID_IGameInputDevice = makeGuid!"B169652A-4A32-40D7-9FA9-905997952516";
	interface IGameInputDevice : IUnknown {
	extern(Windows) @nogc nothrow:
		GameInputDeviceInfo* GetDeviceInfo();
		uint GetDeviceStatus();
		HRESULT CreateForceFeedbackEffect(uint32_t motorIndex, const(GameInputForceFeedbackParams)* params,
				IGameInputForceFeedbackEffect* effect);
		bool IsForceFeedbackMotorPoweredOn(uint32_t motorIndex);
		void SetForceFeedbackMotorGain(uint32_t motorIndex, float masterGain);
		void SetRumbleState(const(GameInputRumbleParams)* params);
	}
}
struct GameInputRumbleParams {
	float lowFrequency;
	float highFrequency;
	float leftTrigger;
	float rightTrigger;
}
struct GameInputForceFeedbackConditionParams {
	GameInputForceFeedbackMagnitude magnitude;
	float							positiveCoefficient;
	float							negativeCoefficient;
	float							maxPositiveMagnitude;
	float							maxNegativeMagnitude;
	float							deadZone;
	float							bias;
}
struct GameInputTouchState {
	uint64_t touchId;
	uint32_t sensorIndex;
	float positionX;
	float positionY;
	float pressure;
	float proximity;
	float contactRectTop;
	float contactRectLeft;
	float contactRectRight;
	float contactRectBottom;
}
struct GameInputUiNavigationState {
	uint buttons;
}
enum GameInputFeedbackEffectState {
	GameInputFeedbackStopped = 0,
	GameInputFeedbackRunning = 1,
	GameInputFeedbackPaused  = 2
}
struct GameInputBatteryState {
	float chargeRate;
	float maxChargeRate;
	float remainingCapacity;
	float fullChargeCapacity;
	GameInputBatteryStatus status;
}
struct GameInputHapticFeedbackParams {
	uint32_t waveformIndex;
	uint64_t duration;
	float intensity;
	uint32_t playCount;
	uint64_t repeatDelay;
}
enum GameInputBatteryStatus {
	GameInputBatteryUnknown = -1,
	GameInputBatteryNotPresent = 0,
	GameInputBatteryDischarging = 1,
	GameInputBatteryIdle = 2,
	GameInputBatteryCharging = 3
}
enum GameInputSystemButtons {
	GameInputSystemButtonNone  = 0x00000000,
	GameInputSystemButtonGuide = 0x00000001,
	GameInputSystemButtonShare = 0x00000002
}
struct GameInputForceFeedbackParams {
	GameInputForceFeedbackEffectKind kind;
	union
	{
		GameInputForceFeedbackConstantParams constant;
		GameInputForceFeedbackRampParams ramp;
		GameInputForceFeedbackPeriodicParams sineWave;
		GameInputForceFeedbackPeriodicParams squareWave;
		GameInputForceFeedbackPeriodicParams triangleWave;
		GameInputForceFeedbackPeriodicParams sawtoothUpWave;
		GameInputForceFeedbackPeriodicParams sawtoothDownWave;
		GameInputForceFeedbackConditionParams spring;
		GameInputForceFeedbackConditionParams friction;
		GameInputForceFeedbackConditionParams damper;
		GameInputForceFeedbackConditionParams inertia;
	}
}
struct GameInputForceFeedbackConstantParams {
	GameInputForceFeedbackEnvelope envelope;
	GameInputForceFeedbackMagnitude magnitude;
}
struct GameInputForceFeedbackRampParams {
	GameInputForceFeedbackEnvelope envelope;
	GameInputForceFeedbackMagnitude startMagnitude;
	GameInputForceFeedbackMagnitude endMagnitude;
}
struct GameInputForceFeedbackPeriodicParams {
	GameInputForceFeedbackEnvelope envelope;
	GameInputForceFeedbackMagnitude magnitude;
	float frequency;
	float phase;
	float bias;
}
struct GameInputForceFeedbackEnvelope {
	uint64_t attackDuration;
	uint64_t sustainDuration;
	uint64_t releaseDuration;
	float attackGain;
	float sustainGain;
	float releaseGain;
	uint32_t playCount;
	uint64_t repeatDelay;
}
struct GameInputForceFeedbackMagnitude {
	float linearX;
	float linearY;
	float linearZ;
	float angularX;
	float angularY;
	float angularZ;
	float normal;
}
enum GameInputForceFeedbackEffectKind
{
	GameInputForceFeedbackConstant = 0,
	GameInputForceFeedbackRamp = 1,
	GameInputForceFeedbackSineWave = 2,
	GameInputForceFeedbackSquareWave = 3,
	GameInputForceFeedbackTriangleWave = 4,
	GameInputForceFeedbackSawtoothUpWave = 5,
	GameInputForceFeedbackSawtoothDownWave = 6,
	GameInputForceFeedbackSpring = 7,
	GameInputForceFeedbackFriction = 8,
	GameInputForceFeedbackDamper = 9,
	GameInputForceFeedbackInertia = 10
}
version (IOTA_WINGAMEINPUT_V0) {
	const IID IID_IGameInputForceFeedbackEffect = makeGuid!"51BDA05E-F742-45D9-B085-9444AE48381D";
	interface IGameInputForceFeedbackEffect : IUnknown {
	extern(Windows) @nogc nothrow:
		void GetDevice(IGameInputDevice* device);
		uint32_t GetMotorIndex();
		float GetGain();
		void SetGain(float gain);
		void GetParams(GameInputForceFeedbackParams* params);
		bool SetParams(const(GameInputForceFeedbackParams)* params);
		GameInputFeedbackEffectState GetState();
		void SetState(GameInputFeedbackEffectState state);
	}
	const IID IID_IGameInputDispatcher = makeGuid!"415EED2E-98CB-42C2-8F28-B94601074E31";
	interface IGameInputDispatcher : IUnknown {
	extern(Windows) @nogc nothrow:
		bool Dispatch(uint64_t quotaInMicroseconds);
		HRESULT OpenWaitHandle(HANDLE* waitHandle);
	}
	const IID IID_IGameInputReading = makeGuid!"2156947A-E1FA-4DE0-A30B-D812931DBD8D";
	interface IGameInputReading : IUnknown {
	extern(Windows) @nogc nothrow:
		GameInputKind GetInputKind();
		uint64_t GetSequenceNumber(GameInputKind inputKind);
		uint64_t GetTimestamp();
		void GetDevice(IGameInputDevice* device);
		bool GetRawReport(IGameInputRawDeviceReport* report);	//Note: This function is not yet implemented.
		uint32_t GetControllerAxisCount();
		uint32_t GetControllerAxisState(uint32_t stateArrayCount, float* stateArray);
		uint32_t GetControllerButtonCount();
		uint32_t GetControllerButtonState(uint32_t stateArrayCount, bool* stateArray);
		uint32_t GetControllerSwitchCount();
		uint32_t GetControllerSwitchState(uint32_t stateArrayCount, GameInputSwitchPosition* stateArray);
		uint32_t GetKeyCount();
		uint32_t GetKeyState(uint32_t stateArrayCount, GameInputKeyState* stateArray);
		bool GetMouseState(GameInputMouseState* state);
		uint32_t GetTouchCount();
		uint32_t GetTouchState(uint32_t stateArrayCount, GameInputTouchState* stateArray);
		bool GetMotionState(GameInputMotionState* state);
		bool GetArcadeStickState(GameInputArcadeStickState* state);
		bool GetFlightStickState(GameInputFlightStickState* state);
		bool GetGamepadState(GameInputGamepadState* state);
		bool GetRacingWheelState(GameInputRacingWheelState* state);
		bool GetUiNavigationState(GameInputUiNavigationState* state);
	}
} else {
	const IID IID_IGameInputForceFeedbackEffect = makeGuid!"51BDA05E-F742-45D9-B085-9444AE48381D";
	interface IGameInputForceFeedbackEffect : IUnknown {
	extern(Windows) @nogc nothrow:
		void GetDevice(IGameInputDevice* device);
		uint32_t GetMotorIndex();
		float GetGain();
		void SetGain(float gain);
		void GetParams(GameInputForceFeedbackParams* params);
		bool SetParams(const(GameInputForceFeedbackParams)* params);
		GameInputFeedbackEffectState GetState();
		void SetState(GameInputFeedbackEffectState state);
	}
	const IID IID_IGameInputDispatcher = makeGuid!"415EED2E-98CB-42C2-8F28-B94601074E31";
	interface IGameInputDispatcher : IUnknown {
	extern(Windows) @nogc nothrow:
		bool Dispatch(uint64_t quotaInMicroseconds);
		HRESULT OpenWaitHandle(HANDLE* waitHandle);
	}
	const IID IID_IGameInputReading = makeGuid!"86318E60-0B3C-40D6-BEFA-C62F2D952724";
	interface IGameInputReading : IUnknown {
	extern(Windows) @nogc nothrow:
		GameInputKind GetInputKind();
		uint64_t GetTimestamp();
		void GetDevice(IGameInputDevice* device);
		uint32_t GetControllerAxisCount();
		uint32_t GetControllerAxisState(uint32_t stateArrayCount, float* stateArray);
		uint32_t GetControllerButtonCount();
		uint32_t GetControllerButtonState(uint32_t stateArrayCount, bool* stateArray);
		uint32_t GetControllerSwitchCount();
		uint32_t GetControllerSwitchState(uint32_t stateArrayCount, GameInputSwitchPosition* stateArray);
		uint32_t GetKeyCount();
		uint32_t GetKeyState(uint32_t stateArrayCount, GameInputKeyState* stateArray);
		bool GetMouseState(GameInputMouseState* state);
		uint32_t GetTouchCount();
		uint32_t GetTouchState(uint32_t stateArrayCount, GameInputTouchState* stateArray);
		bool GetMotionState(GameInputMotionState* state);
		bool GetArcadeStickState(GameInputArcadeStickState* state);
		bool GetFlightStickState(GameInputFlightStickState* state);
		bool GetGamepadState(GameInputGamepadState* state);
		bool GetRacingWheelState(GameInputRacingWheelState* state);
		bool GetUiNavigationState(GameInputUiNavigationState* state);
	}
}
alias GameInputDeviceCallback = extern(Windows) void function(GameInputCallbackToken callbackToken, void* context,
		IGameInputDevice device, uint64_t timestamp, uint currentStatus, uint previousStatus) @nogc nothrow;
alias GameInputGuideButtonCallback = extern(Windows) void function(GameInputCallbackToken callbackToken, void* context,
		IGameInputDevice device, uint64_t timestamp, bool isPressed) @nogc nothrow;
alias GameInputSystemButtonCallback = void function(GameInputCallbackToken callbackToken, void* context,
		IGameInputDevice device, uint64_t timestamp, uint currentState, uint previousState) @nogc nothrow;
alias GameInputKeyboardLayoutCallback = void function(GameInputCallbackToken callbackToken, void* context,
		IGameInputDevice device, uint64_t timestamp, uint32_t currentLayout, uint32_t previousLayout) @nogc nothrow;
alias GameInputReadingCallback = void function(GameInputCallbackToken callbackToken, void* context,
		IGameInputReading reading, bool hasOverrunOccurred) @nogc nothrow;
struct GameInputArcadeStickState {
	uint buttons;
}
enum GameInputFocusPolicy {
    GameInputDefaultFocusPolicy = 0x00000000,
    GameInputDisableBackgroundInput = 0x00000001,
    GameInputExclusiveForegroundInput = 0x00000002,
    GameInputDisableBackgroundGuideButton   = 0x00000004,
    GameInputExclusiveForegroundGuideButton = 0x00000008,
    GameInputDisableBackgroundShareButton   = 0x00000010,
    GameInputExclusiveForegroundShareButton = 0x00000020
}
enum GameInputArcadeStickButtons {
	GameInputArcadeStickNone = 0x00000000,
	GameInputArcadeStickMenu = 0x00000001,
	GameInputArcadeStickView = 0x00000002,
	GameInputArcadeStickUp = 0x00000004,
	GameInputArcadeStickDown = 0x00000008,
	GameInputArcadeStickLeft = 0x00000010,
	GameInputArcadeStickRight = 0x00000020,
	GameInputArcadeStickAction1 = 0x00000040,
	GameInputArcadeStickAction2 = 0x00000080,
	GameInputArcadeStickAction3 = 0x00000100,
	GameInputArcadeStickAction4 = 0x00000200,
	GameInputArcadeStickAction5 = 0x00000400,
	GameInputArcadeStickAction6 = 0x00000800,
	GameInputArcadeStickSpecial1 = 0x00001000,
	GameInputArcadeStickSpecial2 = 0x00002000
}
enum GameInputSwitchPosition {
	GameInputSwitchCenter = 0,
	GameInputSwitchUp = 1,
	GameInputSwitchUpRight = 2,
	GameInputSwitchRight = 3,
	GameInputSwitchDownRight = 4,
	GameInputSwitchDown = 5,
	GameInputSwitchDownLeft = 6,
	GameInputSwitchLeft = 7,
	GameInputSwitchUpLeft = 8
}
struct GameInputFlightStickState {
	uint buttons;
	GameInputSwitchPosition hatSwitch;
	float roll;
	float pitch;
	float yaw;
	float throttle;
}
enum GameInputFlightStickButtons {
	GameInputFlightStickNone = 0x00000000,
	GameInputFlightStickMenu = 0x00000001,
	GameInputFlightStickView = 0x00000002,
	GameInputFlightStickFirePrimary = 0x00000004,
	GameInputFlightStickFireSecondary = 0x00000008
}
enum GameInputGamepadButtons {
	GameInputGamepadNone = 0x00000000,
	GameInputGamepadMenu = 0x00000001,
	GameInputGamepadView = 0x00000002,
	GameInputGamepadA = 0x00000004,
	GameInputGamepadB = 0x00000008,
	GameInputGamepadX = 0x00000010,
	GameInputGamepadY = 0x00000020,
	GameInputGamepadDPadUp = 0x00000040,
	GameInputGamepadDPadDown = 0x00000080,
	GameInputGamepadDPadLeft = 0x00000100,
	GameInputGamepadDPadRight = 0x00000200,
	GameInputGamepadLeftShoulder = 0x00000400,
	GameInputGamepadRightShoulder = 0x00000800,
	GameInputGamepadLeftThumbstick = 0x00001000,
	GameInputGamepadRightThumbstick = 0x00002000
}
struct GameInputGamepadState {
	uint buttons;
	float leftTrigger;
	float rightTrigger;
	float leftThumbstickX;
	float leftThumbstickY;
	float rightThumbstickX;
	float rightThumbstickY;
}
struct GameInputKeyState {
	uint32_t scanCode;
	uint32_t codePoint;
	uint8_t virtualKey;
	bool isDeadKey;
}
struct GameInputMotionInfo {
	float maxAcceleration;
	float maxAngularVelocity;
	float maxMagneticFieldStrength;
}
struct GameInputDeviceInfo {
	uint32_t infoSize;
	uint16_t vendorId;
	uint16_t productId;
	uint16_t revisionNumber;
	uint8_t interfaceNumber;
	uint8_t collectionNumber;
	GameInputUsage usage;
	GameInputVersion hardwareVersion;
	GameInputVersion firmwareVersion;
	APP_LOCAL_DEVICE_ID deviceId;
	APP_LOCAL_DEVICE_ID deviceRootId;
	GameInputDeviceFamily deviceFamily;
	uint capabilities;
	GameInputKind supportedInput;
	uint supportedRumbleMotors;
	uint32_t inputReportCount;
	uint32_t outputReportCount;
	uint32_t featureReportCount;
	uint32_t controllerAxisCount;
	uint32_t controllerButtonCount;
	uint32_t controllerSwitchCount;
	uint32_t touchPointCount;
	uint32_t touchSensorCount;
	uint32_t forceFeedbackMotorCount;
	uint32_t hapticFeedbackMotorCount;
	uint32_t deviceStringCount;
	uint32_t deviceDescriptorSize;
	const(GameInputRawDeviceReportInfo)* inputReportInfo;
	const(GameInputRawDeviceReportInfo)* outputReportInfo;
	const(GameInputRawDeviceReportInfo)* featureReportInfo;
	const(GameInputControllerAxisInfo)* controllerAxisInfo;
	const(GameInputControllerButtonInfo)* controllerButtonInfo;
	const(GameInputControllerSwitchInfo)* controllerSwitchInfo;
	const(GameInputKeyboardInfo)* keyboardInfo;
	const(GameInputMouseInfo)* mouseInfo;
	const(GameInputTouchSensorInfo)* touchSensorInfo;
	const(GameInputMotionInfo)* motionInfo;
	const(GameInputArcadeStickInfo)* arcadeStickInfo;
	const(GameInputFlightStickInfo)* flightStickInfo;
	const(GameInputGamepadInfo)* gamepadInfo;
	const(GameInputRacingWheelInfo)* racingWheelInfo;
	const(GameInputUiNavigationInfo)* uiNavigationInfo;
	const(GameInputForceFeedbackMotorInfo)* forceFeedbackMotorInfo;
	const(GameInputHapticFeedbackMotorInfo)* hapticFeedbackMotorInfo;
	const(GameInputString)* displayName;
	const(GameInputString)* deviceStrings;
	const(void)* deviceDescriptorData;
}
struct GameInputControllerAxisInfo {
	GameInputKind mappedInputKinds;
	GameInputLabel label;
	bool isContinuous;
	bool isNonlinear;
	bool isQuantized;
	bool hasRestValue;
	float restValue;
	uint64_t resolution;
	uint16_t legacyDInputIndex;
	uint16_t legacyHidIndex;
	uint32_t rawReportIndex;
	const(GameInputRawDeviceReportInfo)* inputReport;
	const(GameInputRawDeviceReportItemInfo)* inputReportItem;
}
struct GameInputControllerButtonInfo {
	GameInputKind mappedInputKinds;
	GameInputLabel label;
	uint16_t legacyDInputIndex;
	uint16_t legacyHidIndex;
	uint32_t rawReportIndex;
	const(GameInputRawDeviceReportInfo)* inputReport;
	const(GameInputRawDeviceReportItemInfo)* inputReportItem;
}
struct GameInputControllerSwitchInfo {
	GameInputKind mappedInputKinds;
	GameInputLabel label;
	GameInputLabel[9] positionLabels;
	GameInputSwitchKind kind;
	uint16_t legacyDInputIndex;
	uint16_t legacyHidIndex;
	uint32_t rawReportIndex;
	const(GameInputRawDeviceReportInfo)* inputReport;
	const(GameInputRawDeviceReportItemInfo)* inputReportItem;
}
struct GameInputKeyboardInfo {
	GameInputKeyboardKind kind;
	uint32_t layout;
	uint32_t keyCount;
	uint32_t functionKeyCount;
	uint32_t maxSimultaneousKeys;
	uint32_t platformType;
	uint32_t platformSubtype;
	const(GameInputString)* nativeLanguage;
}
struct GameInputMouseInfo {
	uint supportedButtons;
	uint32_t sampleRate;
	uint32_t sensorDpi;
	bool hasWheelX;
	bool hasWheelY;
}
struct GameInputTouchSensorInfo {
	GameInputKind mappedInputKinds;
	GameInputLabel label;
	GameInputLocation location;
	uint32_t locationId;
	uint64_t resolutionX;
	uint64_t resolutionY;
	GameInputTouchShape shape;
	float aspectRatio;
	float orientation;
	float physicalWidth;
	float physicalHeight;
	float maxPressure;
	float maxProximity;
	uint32_t maxTouchPoints;
}
struct GameInputArcadeStickInfo {
	GameInputLabel menuButtonLabel;
	GameInputLabel viewButtonLabel;
	GameInputLabel stickUpLabel;
	GameInputLabel stickDownLabel;
	GameInputLabel stickLeftLabel;
	GameInputLabel stickRightLabel;
	GameInputLabel actionButton1Label;
	GameInputLabel actionButton2Label;
	GameInputLabel actionButton3Label;
	GameInputLabel actionButton4Label;
	GameInputLabel actionButton5Label;
	GameInputLabel actionButton6Label;
	GameInputLabel specialButton1Label;
	GameInputLabel specialButton2Label;
}
struct GameInputFlightStickInfo {
	GameInputLabel menuButtonLabel;
	GameInputLabel viewButtonLabel;
	GameInputLabel firePrimaryButtonLabel;
	GameInputLabel fireSecondaryButtonLabel;
	GameInputSwitchKind hatSwitchKind;
}
struct GameInputGamepadInfo {
	GameInputLabel menuButtonLabel;
	GameInputLabel viewButtonLabel;
	GameInputLabel aButtonLabel;
	GameInputLabel bButtonLabel;
	GameInputLabel xButtonLabel;
	GameInputLabel yButtonLabel;
	GameInputLabel dpadUpLabel;
	GameInputLabel dpadDownLabel;
	GameInputLabel dpadLeftLabel;
	GameInputLabel dpadRightLabel;
	GameInputLabel leftShoulderButtonLabel;
	GameInputLabel rightShoulderButtonLabel;
	GameInputLabel leftThumbstickButtonLabel;
	GameInputLabel rightThumbstickButtonLabel;
}
struct GameInputRacingWheelInfo {
	GameInputLabel menuButtonLabel;
	GameInputLabel viewButtonLabel;
	GameInputLabel previousGearButtonLabel;
	GameInputLabel nextGearButtonLabel;
	GameInputLabel dpadUpLabel;
	GameInputLabel dpadDownLabel;
	GameInputLabel dpadLeftLabel;
	GameInputLabel dpadRightLabel;
	bool hasClutch;
	bool hasHandbrake;
	bool hasPatternShifter;
	int32_t minPatternShifterGear;
	int32_t maxPatternShifterGear;
	float maxWheelAngle;
}
struct GameInputUiNavigationInfo {
	GameInputLabel menuButtonLabel;
	GameInputLabel viewButtonLabel;
	GameInputLabel acceptButtonLabel;
	GameInputLabel cancelButtonLabel;
	GameInputLabel upButtonLabel;
	GameInputLabel downButtonLabel;
	GameInputLabel leftButtonLabel;
	GameInputLabel rightButtonLabel;
	GameInputLabel contextButton1Label;
	GameInputLabel contextButton2Label;
	GameInputLabel contextButton3Label;
	GameInputLabel contextButton4Label;
	GameInputLabel pageUpButtonLabel;
	GameInputLabel pageDownButtonLabel;
	GameInputLabel pageLeftButtonLabel;
	GameInputLabel pageRightButtonLabel;
	GameInputLabel scrollUpButtonLabel;
	GameInputLabel scrollDownButtonLabel;
	GameInputLabel scrollLeftButtonLabel;
	GameInputLabel scrollRightButtonLabel;
	GameInputLabel guideButtonLabel;
}
struct GameInputForceFeedbackMotorInfo {
	uint supportedAxes;
	GameInputLocation location;
	uint32_t locationId;
	uint32_t maxSimultaneousEffects;
	bool isConstantEffectSupported;
	bool isRampEffectSupported;
	bool isSineWaveEffectSupported;
	bool isSquareWaveEffectSupported;
	bool isTriangleWaveEffectSupported;
	bool isSawtoothUpWaveEffectSupported;
	bool isSawtoothDownWaveEffectSupported;
	bool isSpringEffectSupported;
	bool isFrictionEffectSupported;
	bool isDamperEffectSupported;
	bool isInertiaEffectSupported;
}
struct GameInputHapticFeedbackMotorInfo {
	GameInputRumbleMotors mappedRumbleMotor;
	GameInputLocation location;
	uint32_t locationId;
	uint32_t waveformCount;
	const(GameInputHapticWaveformInfo)* waveformInfo;
}
struct GameInputHapticWaveformInfo {
	GameInputUsage usage;
	bool isDurationSupported;
	bool isIntensitySupported;
	bool isRepeatSupported;
	bool isRepeatDelaySupported;
	uint64_t defaultDuration;
}
struct GameInputVersion {
	uint16_t major;
	uint16_t minor;
	uint16_t build;
	uint16_t revision;
}
enum GameInputFeedbackAxes
{
	GameInputFeedbackAxisNone = 0x00000000,
	GameInputFeedbackAxisLinearX = 0x00000001,
	GameInputFeedbackAxisLinearY = 0x00000002,
	GameInputFeedbackAxisLinearZ = 0x00000004,
	GameInputFeedbackAxisAngularX = 0x00000008,
	GameInputFeedbackAxisAngularY = 0x00000010,
	GameInputFeedbackAxisAngularZ = 0x00000020,
	GameInputFeedbackAxisNormal = 0x00000040
}
enum GameInputTouchShape {
	GameInputTouchShapeUnknown = -1,
	GameInputTouchShapePoint = 0,
	GameInputTouchShape1DLinear = 1,
	GameInputTouchShape1DRadial = 2,
	GameInputTouchShape1DIrregular = 3,
	GameInputTouchShape2DRectangular = 4,
	GameInputTouchShape2DElliptical = 5,
	GameInputTouchShape2DIrregular = 6
}
enum GameInputLocation {
	GameInputLocationUnknown = -1,
	GameInputLocationChassis = 0,
	GameInputLocationDisplay = 1,
	GameInputLocationAxis = 2,
	GameInputLocationButton = 3,
	GameInputLocationSwitch = 4,
	GameInputLocationKey = 5,
	GameInputLocationTouchPad = 6
}
enum GameInputKeyboardKind {
	GameInputUnknownKeyboard = -1,
	GameInputAnsiKeyboard = 0,
	GameInputIsoKeyboard = 1,
	GameInputKsKeyboard = 2,
	GameInputAbntKeyboard = 3,
	GameInputJisKeyboard = 4
}
enum GameInputDeviceFamily {
	GameInputFamilyVirtual = -1,
	GameInputFamilyAggregate = 0,
	GameInputFamilyXboxOne = 1,
	GameInputFamilyXbox360 = 2,
	GameInputFamilyHid = 3,
	GameInputFamilyI8042 = 4
}
enum GameInputSwitchKind {
	GameInputUnknownSwitchKind = -1,
	GameInput2WaySwitch = 0,
	GameInput4WaySwitch = 1,
	GameInput8WaySwitch = 2
}
enum GameInputDeviceCapabilities {
	GameInputDeviceCapabilityNone = 0x00000000,
	GameInputDeviceCapabilityAudio = 0x00000001,
	GameInputDeviceCapabilityPluginModule = 0x00000002,
	GameInputDeviceCapabilityPowerOff = 0x00000004,
	GameInputDeviceCapabilitySynchronization = 0x00000008,
	GameInputDeviceCapabilityWireless = 0x00000010
}
enum GameInputRumbleMotors {
	GameInputRumbleNone = 0x00000000,
	GameInputRumbleLowFrequency = 0x00000001,
	GameInputRumbleHighFrequency = 0x00000002,
	GameInputRumbleLeftTrigger = 0x00000004,
	GameInputRumbleRightTrigger = 0x00000008
}
enum GameInputLabel
{
    GameInputLabelUnknown = -1,
    GameInputLabelNone = 0,
    GameInputLabelXboxGuide = 1,
    GameInputLabelXboxBack = 2,
    GameInputLabelXboxStart = 3,
    GameInputLabelXboxMenu = 4,
    GameInputLabelXboxView = 5,
    GameInputLabelXboxA = 7,
    GameInputLabelXboxB = 8,
    GameInputLabelXboxX = 9,
    GameInputLabelXboxY = 10,
    GameInputLabelXboxDPadUp = 11,
    GameInputLabelXboxDPadDown = 12,
    GameInputLabelXboxDPadLeft = 13,
    GameInputLabelXboxDPadRight = 14,
    GameInputLabelXboxLeftShoulder = 15,
    GameInputLabelXboxLeftTrigger = 16,
    GameInputLabelXboxLeftStickButton = 17,
    GameInputLabelXboxRightShoulder = 18,
    GameInputLabelXboxRightTrigger = 19,
    GameInputLabelXboxRightStickButton = 20,
    GameInputLabelXboxPaddle1 = 21,
    GameInputLabelXboxPaddle2 = 22,
    GameInputLabelXboxPaddle3 = 23,
    GameInputLabelXboxPaddle4 = 24,
    GameInputLabelLetterA = 25,
    GameInputLabelLetterB = 26,
    GameInputLabelLetterC = 27,
    GameInputLabelLetterD = 28,
    GameInputLabelLetterE = 29,
    GameInputLabelLetterF = 30,
    GameInputLabelLetterG = 31,
    GameInputLabelLetterH = 32,
    GameInputLabelLetterI = 33,
    GameInputLabelLetterJ = 34,
    GameInputLabelLetterK = 35,
    GameInputLabelLetterL = 36,
    GameInputLabelLetterM = 37,
    GameInputLabelLetterN = 38,
    GameInputLabelLetterO = 39,
    GameInputLabelLetterP = 40,
    GameInputLabelLetterQ = 41,
    GameInputLabelLetterR = 42,
    GameInputLabelLetterS = 43,
    GameInputLabelLetterT = 44,
    GameInputLabelLetterU = 45,
    GameInputLabelLetterV = 46,
    GameInputLabelLetterW = 47,
    GameInputLabelLetterX = 48,
    GameInputLabelLetterY = 49,
    GameInputLabelLetterZ = 50,
    GameInputLabelNumber0 = 51,
    GameInputLabelNumber1 = 52,
    GameInputLabelNumber2 = 53,
    GameInputLabelNumber3 = 54,
    GameInputLabelNumber4 = 55,
    GameInputLabelNumber5 = 56,
    GameInputLabelNumber6 = 57,
    GameInputLabelNumber7 = 58,
    GameInputLabelNumber8 = 59,
    GameInputLabelNumber9 = 60,
    GameInputLabelArrowUp = 61,
    GameInputLabelArrowUpRight = 62,
    GameInputLabelArrowRight = 63,
    GameInputLabelArrowDownRight = 64,
    GameInputLabelArrowDown = 65,
    GameInputLabelArrowDownLLeft = 66,
    GameInputLabelArrowLeft = 67,
    GameInputLabelArrowUpLeft = 68,
    GameInputLabelArrowUpDown = 69,
    GameInputLabelArrowLeftRight = 70,
    GameInputLabelArrowUpDownLeftRight = 71,
    GameInputLabelArrowClockwise = 72,
    GameInputLabelArrowCounterClockwise = 73,
    GameInputLabelArrowReturn = 74,
    GameInputLabelIconBranding = 75,
    GameInputLabelIconHome = 76,
    GameInputLabelIconMenu = 77,
    GameInputLabelIconCross = 78,
    GameInputLabelIconCircle = 79,
    GameInputLabelIconSquare = 80,
    GameInputLabelIconTriangle = 81,
    GameInputLabelIconStar = 82,
    GameInputLabelIconDPadUp = 83,
    GameInputLabelIconDPadDown = 84,
    GameInputLabelIconDPadLeft = 85,
    GameInputLabelIconDPadRight = 86,
    GameInputLabelIconDialClockwise = 87,
    GameInputLabelIconDialCounterClockwise = 88,
    GameInputLabelIconSliderLeftRight = 89,
    GameInputLabelIconSliderUpDown = 90,
    GameInputLabelIconWheelUpDown = 91,
    GameInputLabelIconPlus = 92,
    GameInputLabelIconMinus = 93,
    GameInputLabelIconSuspension = 94,
    GameInputLabelHome = 95,
    GameInputLabelGuide = 96,
    GameInputLabelMode = 97,
    GameInputLabelSelect = 98,
    GameInputLabelMenu = 99,
    GameInputLabelView = 100,
    GameInputLabelBack = 101,
    GameInputLabelStart = 102,
    GameInputLabelOptions = 103,
    GameInputLabelShare = 104,
    GameInputLabelUp = 105,
    GameInputLabelDown = 106,
    GameInputLabelLeft = 107,
    GameInputLabelRight = 108,
    GameInputLabelLB = 109,
    GameInputLabelLT = 110,
    GameInputLabelLSB = 111,
    GameInputLabelL1 = 112,
    GameInputLabelL2 = 113,
    GameInputLabelL3 = 114,
    GameInputLabelRB = 115,
    GameInputLabelRT = 116,
    GameInputLabelRSB = 117,
    GameInputLabelR1 = 118,
    GameInputLabelR2 = 119,
    GameInputLabelR3 = 120,
    GameInputLabelP1 = 121,
    GameInputLabelP2 = 122,
    GameInputLabelP3 = 123,
    GameInputLabelP4 = 124
}
struct GameInputMotionState {
	float accelerationX;
	float accelerationY;
	float accelerationZ;
	float angularVelocityX;
	float angularVelocityY;
	float angularVelocityZ;
	float magneticFieldX;
	float magneticFieldY;
	float magneticFieldZ;
	float orientationW;
	float orientationX;
	float orientationY;
	float orientationZ;
	GameInputMotionAccuracy accelerometerAccuracy;
	GameInputMotionAccuracy gyroscopeAccuracy;
	GameInputMotionAccuracy magnetometerAccuracy;
	GameInputMotionAccuracy orientationAccuracy;
}
enum GameInputMotionAccuracy {
	GameInputMotionAccuracyUnknown = -1,
	GameInputMotionUnavailable = 0,
	GameInputMotionUnreliable = 1,
	GameInputMotionApproximate = 2,
	GameInputMotionAccurate = 3
}
struct GameInputMouseState {
	uint buttons;
	int64_t positionX;
	int64_t positionY;
	int64_t wheelX;
	int64_t wheelY;
}
enum GameInputMouseButtons {
	GameInputMouseNone = 0x00000000,
	GameInputMouseLeftButton = 0x00000001,
	GameInputMouseRightButton = 0x00000002,
	GameInputMouseMiddleButton = 0x00000004,
	GameInputMouseButton4 = 0x00000008,
	GameInputMouseButton5 = 0x00000010,
	GameInputMouseWheelTiltLeft = 0x00000020,
	GameInputMouseWheelTiltRight = 0x00000040
}
struct GameInputRacingWheelState {
	uint buttons;
	int32_t patternShifterGear;
	float wheel;
	float throttle;
	float brake;
	float clutch;
	float handbrake;
}
enum GameInputRacingWheelButtons {
	GameInputRacingWheelNone = 0x00000000,
	GameInputRacingWheelMenu = 0x00000001,
	GameInputRacingWheelView = 0x00000002,
	GameInputRacingWheelPreviousGear = 0x00000004,
	GameInputRacingWheelNextGear = 0x00000008,
	GameInputRacingWheelDpadUp = 0x00000010,
	GameInputRacingWheelDpadDown = 0x00000020,
	GameInputRacingWheelDpadLeft = 0x00000040,
	GameInputRacingWheelDpadRight = 0x00000080
}
const IID IID_IGameInputRawDeviceReport = makeGuid!"61F08CF1-1FFC-40CA-A2B8-E1AB8BC5B6DC";
interface IGameInputRawDeviceReport : IUnknown {	//Note: this interface is not yet implemented
extern(Windows) @nogc nothrow:
	void GetDevice(IGameInputDevice* device);
	GameInputRawDeviceReportInfo* GetReportInfo();
	size_t GetRawDataSize();
	size_t GetRawData(size_t bufferSize, void* buffer);
	bool SetRawData(size_t bufferSize, const(void)* buffer);
	bool GetItemValue(uint32_t itemIndex, int64_t* value);
	bool SetItemValue(uint32_t itemIndex, int64_t value);
	bool ResetItemValue(uint32_t itemIndex);
	bool ResetAllItems();
}
struct GameInputRawDeviceReportInfo {
	GameInputRawDeviceReportKind kind;
	uint32_t id;
	uint32_t size;
	uint32_t itemCount;
	const(GameInputRawDeviceReportItemInfo)* items;
}
enum GameInputRawDeviceReportKind {
	GameInputRawInputReport = 0,
	GameInputRawOutputReport = 1,
	GameInputRawFeatureReport = 2
}
struct GameInputRawDeviceReportItemInfo {
	uint32_t bitOffset;
	uint32_t bitSize;
	int64_t logicalMin;
	int64_t logicalMax;
	double physicalMin;
	double physicalMax;
	GameInputRawDevicePhysicalUnitKind physicalUnits;
	uint32_t rawPhysicalUnits;
	int32_t rawPhysicalUnitsExponent;
	GameInputRawDeviceReportItemFlags flags;
	uint32_t usageCount;
	const(GameInputUsage)* usages;
	const(GameInputRawDeviceItemCollectionInfo)* collection;
	const(GameInputString)* itemString;
}
enum GameInputRawDevicePhysicalUnitKind {
	GameInputPhysicalUnitUnknown = -1,
	GameInputPhysicalUnitNone = 0,
	GameInputPhysicalUnitTime = 1,
	GameInputPhysicalUnitFrequency = 2,
	GameInputPhysicalUnitLength = 3,
	GameInputPhysicalUnitVelocity = 4,
	GameInputPhysicalUnitAcceleration = 5,
	GameInputPhysicalUnitMass = 6,
	GameInputPhysicalUnitMomentum = 7,
	GameInputPhysicalUnitForce = 8,
	GameInputPhysicalUnitPressure = 9,
	GameInputPhysicalUnitAngle = 10,
	GameInputPhysicalUnitAngularVelocity = 11,
	GameInputPhysicalUnitAngularAcceleration = 12,
	GameInputPhysicalUnitAngularMass = 13,
	GameInputPhysicalUnitAngularMomentum = 14,
	GameInputPhysicalUnitAngularTorque = 15,
	GameInputPhysicalUnitElectricCurrent = 16,
	GameInputPhysicalUnitElectricCharge = 17,
	GameInputPhysicalUnitElectricPotential = 18,
	GameInputPhysicalUnitEnergy = 19,
	GameInputPhysicalUnitPower = 20,
	GameInputPhysicalUnitTemperature = 21,
	GameInputPhysicalUnitLuminousIntensity = 22,
	GameInputPhysicalUnitLuminousFlux = 23,
	GameInputPhysicalUnitIlluminance = 24
}
enum GameInputRawDeviceReportItemFlags {
	GameInputDefaultItem = 0x00000000,
	GameInputConstantItem = 0x00000001,
	GameInputArrayItem = 0x00000002,
	GameInputRelativeItem = 0x00000004,
	GameInputWraparoundItem = 0x00000008,
	GameInputNonlinearItem = 0x00000010,
	GameInputStableItem = 0x00000020,
	GameInputNullableItem = 0x00000040,
	GameInputVolatileItem = 0x00000080,
	GameInputBufferedItem = 0x00000100
}
struct GameInputUsage {
	uint16_t page;
	uint16_t id;
}
struct GameInputRawDeviceItemCollectionInfo {
	GameInputRawDeviceItemCollectionKind kind;
	uint32_t childCount;
	uint32_t siblingCount;
	uint32_t usageCount;
	const(GameInputUsage)* usages;
	const(GameInputRawDeviceItemCollectionInfo)* parent;
	const(GameInputRawDeviceItemCollectionInfo)* firstSibling;
	const(GameInputRawDeviceItemCollectionInfo)* previousSibling;
	const(GameInputRawDeviceItemCollectionInfo)* nextSibling;
	const(GameInputRawDeviceItemCollectionInfo)* lastSibling;
	const(GameInputRawDeviceItemCollectionInfo)* firstChild;
	const(GameInputRawDeviceItemCollectionInfo)* lastChild;
}
struct GameInputString {
	uint32_t sizeInBytes;
	uint32_t codePointCount;
	const(char)* data;
}
enum GameInputDeviceStatus {
	GameInputDeviceNoStatus = 0x00000000,
	GameInputDeviceConnected = 0x00000001,
	GameInputDeviceInputEnabled = 0x00000002,
	GameInputDeviceOutputEnabled = 0x00000004,
	GameInputDeviceRawIoEnabled = 0x00000008,
	GameInputDeviceAudioCapture = 0x00000010,
	GameInputDeviceAudioRender = 0x00000020,
	GameInputDeviceSynchronized = 0x00000040,
	GameInputDeviceWireless = 0x00000080,
	GameInputDeviceUserIdle = 0x00100000,
	GameInputDeviceAnyStatus = 0x00FFFFFF
}
enum GameInputEnumerationKind {
	GameInputNoEnumeration = 0,
	GameInputAsyncEnumeration = 1,
	GameInputBlockingEnumeration = 2
}

enum GameInputUiNavigationButtons {
	GameInputUiNavigationNone = 0x00000000,
	GameInputUiNavigationMenu = 0x00000001,
	GameInputUiNavigationView = 0x00000002,
	GameInputUiNavigationAccept = 0x00000004,
	GameInputUiNavigationCancel = 0x00000008,
	GameInputUiNavigationUp = 0x00000010,
	GameInputUiNavigationDown = 0x00000020,
	GameInputUiNavigationLeft = 0x00000040,
	GameInputUiNavigationRight = 0x00000080,
	GameInputUiNavigationContext1 = 0x00000100,
	GameInputUiNavigationContext2 = 0x00000200,
	GameInputUiNavigationContext3 = 0x00000400,
	GameInputUiNavigationContext4 = 0x00000800,
	GameInputUiNavigationPageUp = 0x00001000,
	GameInputUiNavigationPageDown = 0x00002000,
	GameInputUiNavigationPageLeft = 0x00004000,
	GameInputUiNavigationPageRight = 0x00008000,
	GameInputUiNavigationScrollUp = 0x00010000,
	GameInputUiNavigationScrollDown = 0x00020000,
	GameInputUiNavigationScrollLeft = 0x00040000,
	GameInputUiNavigationScrollRight = 0x00080000
}

enum GameInputRawDeviceItemCollectionKind {
	GameInputUnknownItemCollection = -1,
	GameInputPhysicalItemCollection = 0,
	GameInputApplicationItemCollection = 1,
	GameInputLogicalItemCollection = 2,
	GameInputReportItemCollection = 3,
	GameInputNamedArrayItemCollection = 4,
	GameInputUsageSwitchItemCollection = 5,
	GameInputUsageModifierItemCollection = 6
}

enum GameInputErrorCodes {
	E_GAME_MISSING_GAME_CONFIG 	=									0x87e5001F,
	E_GAMERUNTIME_NOT_INITIALIZED =									0x89240100,
	E_GAMERUNTIME_DLL_NOT_FOUND =									0x89240101,
	E_GAMERUNTIME_VERSION_MISMATCH =								0x89240102,
	E_GAMERUNTIME_WINDOW_NOT_FOREGROUND	=							0x89240103,
	E_GAMERUNTIME_SUSPENDED =										0x89240104,
	E_GAMERUNTIME_UNINITIALIZE_ACTIVEOBJECTS 	=					0x89240105,
	E_GAMERUNTIME_MULTIPLAYER_NOT_CONFIGURED 	=					0x89240106,
	E_GAMERUNTIME_OPTIONS_MISMATCH 	=								0x89240109,
	E_GAMERUNTIME_OPTIONS_NOT_SUPPORTED =							0x8924010A,
	E_GAMERUNTIME_GAMECONFIG_BAD_FORMAT =							0x8924010B,
	E_GAMERUNTIME_INVALID_HANDLE 	=								0x8924010C,
	E_GAMEUSER_MAX_USERS_ADDED 	=									0x89245100,
	E_GAMEUSER_SIGNED_OUT 	=										0x89245101,
	E_GAMEUSER_RESOLVE_USER_ISSUE_REQUIRED 	=						0x89245102,
	E_GAMEUSER_DEFERRAL_NOT_AVAILABLE 	=							0x89245103,
	E_GAMEUSER_USER_NOT_FOUND 	=									0x89245104,
	E_GAMEUSER_NO_TOKEN_REQUIRED 	=								0x89245105,
	E_GAMEUSER_NO_DEFAULT_USER 	=									0x89245106,
	E_GAMEUSER_FAILED_TO_RESOLVE 	=								0x89245107,
	E_GAMEUSER_NO_TITLE_ID 	=										0x89245108,
	E_GAMEUSER_UNKNOWN_GAME_IDENTITY 	=							0x89245109,
	E_GAMEUSER_NO_PACKAGE_IDENTITY 	=								0x89245110,
	E_GAMEUSER_FAILED_TO_GET_TOKEN 	=								0x89245111,
	E_GAMEUSER_INVALID_APP_CONFIGURATION 	=						0x89245112,
	E_GAMEUSER_MALFORMED_MSAAPPID 	=								0x89245113,
	E_GAMEUSER_INCONSISTENT_MSAAPPID_AND_TITLEID =					0x89245114,
	E_GAMEPACKAGE_APP_NOT_PACKAGED 	=								0x89245200,
	E_GAMEPACKAGE_NO_INSTALLED_LANGUAGES 	=						0x89245201,
	E_GAMEPACKAGE_NO_STORE_ID 	=									0x89245202,
	E_GAMEPACKAGE_INVALID_SELECTOR 	=								0x89245203,
	E_GAMEPACKAGE_DOWNLOAD_REQUIRED 	=							0x89245204,
	E_GAMEPACKAGE_NO_TAG_CHANGE 	=								0x89245205,
	E_GAMEPACKAGE_DLC_NOT_SUPPORTED 	=							0x89245206,
	E_GAMEPACKAGE_DUPLICATE_ID_VALUES 	=							0x89245207,
	E_GAMEPACKAGE_NO_PACKAGE_IDENTIFIER 	=						0x89245208,
	E_GAMEPACKAGE_CONFIG_NO_ROOT_NODE 	=							0x89245209,
	E_GAMEPACKAGE_CONFIG_ZERO_VERSION 	=							0x8924520A,
	E_GAMEPACKAGE_CONFIG_NO_MSAAPPID_NOTITLEID 	=					0x8924520B,
	E_GAMEPACKAGE_CONFIG_DEPRECATED_PC_ENTRIES 	=					0x8924520C,
	E_GAMEPACKAGE_CONFIG_SUM_REQUIRES_MSAAPPID 	=					0x8924520D,
	E_GAMEPACKAGE_CONFIG_NO_CODE_CLOUD_SAVES_REQUIRES_MSAAPPID 	=	0x8924520E,
	E_GAMEPACKAGE_CONFIG_MSAAPPID_OR_TITLEID_IS_DEFAULT 	=		0x8924520F,
	E_GAMESTORE_LICENSE_ACTION_NOT_APPLICABLE_TO_PRODUCT 	=		0x89245300,
	E_GAMESTORE_NETWORK_ERROR 	=									0x89245301,
	E_GAMESTORE_SERVER_ERROR 	=									0x89245302,
	E_GAMESTORE_INSUFFICIENT_QUANTITY 	=							0x89245303,
	E_GAMESTORE_ALREADY_PURCHASED 	=								0x89245304,
	E_GAMESTREAMING_NOT_INITIALIZED 	=							0x89245400,
	E_GAMESTREAMING_CLIENT_NOT_CONNECTED 	=						0x89245401,
	E_GAMESTREAMING_NO_DATA 	=									0x89245402,
	E_GAMESTREAMING_NO_DATACENTER 	=								0x89245403,
	E_GAMESTREAMING_NOT_STREAMING_CONTROLLER 	=					0x89245404,
}
