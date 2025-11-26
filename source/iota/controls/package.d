module iota.controls;

import std.typecons;

public import iota.controls.types;
public import iota.controls.keyboard;
public import iota.controls.mouse;
public import iota.controls.system;
public import iota.controls.gamectrl;
public import iota.window.oswindow;
import iota.controls.polling;
import iota.etc.charcode;
import iota.etc.stdlib;

version (Windows) {
	import core.sys.windows.windows;
	import core.sys.windows.wtypes;

} else version (OSX) {
	import cocoa.foundation;

} else {
	import iota.controls.backend.linux;
	import core.stdc.errno;

	//import core.sys.linux.fcntl;
}
import core.stdc.stdlib;
import core.atomic;
//import core.stdc.stdio;
import std.conv : to;
import std.string : toStringz, fromStringz, splitLines, split;
import std.utf;
import std.uni : toLower;
import std.stdio;

import numem;
import nulib.collections.vector;

public enum IOTA_INPUTCONFIG_MANDATORY = 0;
package uint __configFlags, __osConfigFlags;
/** 
 * Initializes the input subsystem
 * Params:
 *   config = Configuration flags ORed together.
 *   osConfig = OS-specific configuration flags ORed together.
 *   gcmTable = Game controller mapping table. Compatible with SDL's own format, but has its
 * own extensions to the format. Be noted that the table needs to be prefiltered to only 
 * contain the parts that are for the given OS. Can be null if either no game controllers
 * are being used, or XInput is being used.
 * Returns: 0 if everything is successful, or a specific errorcode.
 */
public int initInput(uint config = 0, uint osConfig = 0, string gcmTable = null) nothrow {
	config |= IOTA_INPUTCONFIG_MANDATORY;
	__configFlags = config;
	__osConfigFlags = osConfig;
	sys = nogc_new!(System)(config, osConfig);
	devList ~= cast(InputDevice)sys;
	version (Windows) {
		if (config & ConfigFlags.gc_Enable) {
			if (osConfig & OSConfigFlags.win_XInput) {
				import iota.controls.backend.windows;
				XInputEnable(256);
				for (int i ; i < 4 ; i++) {
					XInputDevice x = nogc_new!(XInputDevice)(i, (config & ConfigFlags.gc_TriggerMode) != 0);
					if (!x.isInvalidated) {
						devList ~= cast(InputDevice)x;
					} else {
						nogc_delete(x);
					}
				}
				subPollingFun = &XInputDevice.poll;
			}
			if (osConfig & OSConfigFlags.win_GameInput) {
				import iota.controls.backend.windows;
				HRESULT statusGameInput;
				version (IOTA_WINGAMEINPUT_V0) {
					if (loadGameInputDLLv0()) return InputInitializationStatus.win_GIUnsupported;
					statusGameInput = GameInputCreate(&GIGameController.gameInputHandler);
					if (statusGameInput || GIGameController.gameInputHandler is null) return InputInitializationStatus.win_GIError;
				} else {
					if (loadGameInputDLL()) return InputInitializationStatus.win_GIUnsupported;
					statusGameInput = GameInputInitialize(&IID_IGameInput, cast(void**)&GIGameController.gameInputHandler);
				}
				//Initialize event buffer
				GIGameController.pb.processedInputEvents = nu_malloca!InputEvent(256);
				GIGameController.pb.eventsModulo = 255;
				statusGameInput = GIGameController.gameInputHandler.RegisterDeviceCallback(null,
						GameInputKind.GameInputKindGamepad | GameInputKind.GameInputKindController,
						GameInputDeviceStatus.GameInputDeviceAnyStatus, GameInputEnumerationKind.GameInputBlockingEnumeration,
						&GIGameController.pb, &GIGameController.deviceCallback, &GIGameController.callbackToken);
				if (statusGameInput) return InputInitializationStatus.win_GIError;
				version (IOTA_WINGAMEINPUT_V0) {

				} else {
					statusGameInput = GIGameController.gameInputHandler.RegisterSystemButtonCallback(null,
							GameInputSystemButtons.GameInputSystemButtonGuide | GameInputSystemButtons.GameInputSystemButtonShare,
							&GIGameController.pb, &GIGameController.sysButtonCallback, &GIGameController.sysToken);
					if (statusGameInput) return InputInitializationStatus.win_GIError;
				}
				subPollingFun = &GIGameController.poll;
				GIGameController.triggerMode = (config & ConfigFlags.gc_TriggerMode) != 0;
			}
		}
		if (osConfig & OSConfigFlags.win_RawInput) {
			const DWORD flags = 0;
			if (osConfig & OSConfigFlags.win_DisableHotkeys) Keyboard.setMenuKeyDisabled(true);
			HWND handle = null;
			RAWINPUTDEVICE[] rid;
			rid ~= RAWINPUTDEVICE(0x0001, 0x0006, flags, handle);
			rid ~= RAWINPUTDEVICE(0x0001, 0x0007, flags, handle);
			rid ~= RAWINPUTDEVICE(0x0001, 0x0002, flags, handle);
			rid ~= RAWINPUTDEVICE(0x0001, 0x0003, flags, handle);
			if (config & ConfigFlags.enableTouchscreen) rid ~= RAWINPUTDEVICE(0x000D, 0x0004, 0, handle);
			if (config & ConfigFlags.gc_Enable) {
				import iota.controls.backend.windows;
				//XInputEnable(256);
				if (osConfig & OSConfigFlags.win_RawInputGC) {
					rid ~= RAWINPUTDEVICE(0x0001, 0x0005, flags, handle);
					rid ~= RAWINPUTDEVICE(0x0001, 0x0004, flags, handle);
					rid ~= RAWINPUTDEVICE(0x0001, 0x0008, flags, handle);
				}
			}
			if (RegisterRawInputDevices(rid.ptr, cast(UINT)rid.length, cast(UINT)(RAWINPUTDEVICE.sizeof)) == FALSE) {
				return InputInitializationStatus.win_RawInputError;
			}
			RAWINPUTDEVICELIST[] devices;
			UINT nDevices;
			if (GetRawInputDeviceList(null, &nDevices, cast(UINT)(RAWINPUTDEVICELIST.sizeof)))
				return InputInitializationStatus.win_RawInputError;
			devices.length = nDevices;
			nDevices = GetRawInputDeviceList(devices.ptr, &nDevices, cast(UINT)(RAWINPUTDEVICELIST.sizeof));
			if (nDevices == cast(uint)-1)
				return InputInitializationStatus.win_DevicesAdded;
			ubyte kbNum, mNum, gcNum;
			foreach (RAWINPUTDEVICELIST dev ; devices) {
				wchar[512] data;
				//data.length = 512;
				UINT nameLen = 512;
				UINT nameRes = GetRawInputDeviceInfoW(dev.hDevice, RIDI_DEVICENAME, cast(void*)data.ptr, &nameLen);
				//HANDLE hdevice = dev.hDevice;
				if (nameRes == cast(UINT)-1)
					return InputInitializationStatus.win_RawInputError;
				switch (dev.dwType) {
					case RIM_TYPEMOUSE:
						Mouse m;
						m = nogc_new!(Mouse)(fromUTF16toUTF8(cast(wstring)data[0..nameRes]), mNum++, dev.hDevice);
						devList ~= cast(InputDevice)m;
						mouse = m;
						break;
					case RIM_TYPEKEYBOARD:
						Keyboard k;
						k = nogc_new!(Keyboard)(fromUTF16toUTF8(cast(wstring)data[0..nameRes]), kbNum++, dev.hDevice);
						devList ~= cast(InputDevice)k;
						keyb = k;
						break;
					default:	//Must be RIM_TYPEHID
						try {
							RawGCMapping[] mapping = parseGCM(gcmTable, null);
							if (mapping.length) {
								devList ~= cast(InputDevice)nogc_new!(RawInputGameController)(fromUTF16toUTF8(cast(wstring)data[0..nameRes]),
										gcNum++, dev.hDevice, mapping);
							}
						} catch (Exception e) {
							debug writeln(e);
						}

						break;
				}
				//if (keyb is null) keyb = new Keyboard();
				//if (mouse is null) mouse = new Mouse();
				mainPollingFun = &poll_win_RawInput;
			}
		} else {
			keyb = nogc_new!(Keyboard)();
			mouse = nogc_new!(Mouse)();
			devList ~= cast(InputDevice)keyb;
			devList ~= cast(InputDevice)mouse;
			mainPollingFun = &poll_win_LegacyIO;

		}
	} else version(OSX) {
		keyb = nogc_new!Keyboard();
		mouse = nogc_new!Mouse();
		mainPollingFun = &poll_osx;
		devList ~= cast(InputDevice)keyb;
		devList ~= cast(InputDevice)mouse;
	} else {
		if (osConfig & OSConfigFlags.libevdev_enable) {
			try {
				import std.file : dirEntries, SpanMode, DirEntry;
				import std.algorithm;
				auto devPaths = dirEntries("/dev/input/", SpanMode.shallow);
				ubyte keybCnrt, mouseCnrt, gcCnrt;
				foreach (DirEntry entry ; devPaths) {
					if (!entry.isDir && entry.name[$-4..$] != "mice") {
						auto ntStr = toStringz(entry);
						//writeln(fromStringz(ntStr));
						int fd = open(ntStr, O_NONBLOCK | (osConfig & OSConfigFlags.libevdev_writeenable) ? O_RDWR : O_READONLY);
						if (fd < 0) {
							// writeln(fromStringz(ntStr), " could not be opened!");
							continue;
						}
						libevdev* dev;
						if (libevdev_new_from_fd(fd, &dev) < 0) {
							close(fd);
							continue;
							//return InputInitializationStatus.libevdev_ErrorOpeningDev;
						}
						string name = fromCSTR(libevdev_get_name(dev));
						string nameLC = toLower(entry);
						//Try to detect device type from name
						if (canFind(nameLC, "keyboard", "keypad")) {
							devList ~= cast(InputDevice)nogc_new!Keyboard(name, keybCnrt++, fd, dev);
						} else if (canFind(nameLC, "mouse", "trackball")) {
							devList ~= cast(InputDevice)nogc_new!Mouse(name, mouseCnrt++, fd, dev);
						} else if (/+canFind(nameLC, "js") && +/(config & ConfigFlags.gc_Enable)) {	//Likely a game controller, let's check the supplied table if exists
							string uniqueID = cast(string)fromStringz(libevdev_get_uniq(dev));
							RawGCMapping[] mapping;
							if (gcmTable) mapping = parseGCM(gcmTable, uniqueID);
							if (!mapping) nogc_copy(mapping, defaultGCmapping);
							devList ~= nogc_new!RawInputGameController(name, gcCnrt++, fd, dev, mapping);
						} else {
							libevdev_free(dev);
							close(fd);
						}
						// writeln(fromStringz(ntStr), " has been opened");
					}
				}
				//if (!(keybCnrt + mouseCnrt + gcCnrt)) return InputInitializationStatus.libevdev_AccessDenied;
				subPollingFun = &poll_evdev;

			} catch (Exception e) {
				//debug writeln(e);
				return InputInitializationStatus.libevdev_ErrorOpeningDev;
			}
		} /+else {
			mainPollingFun = &poll_x11_RegularIO;
		}+/
		keyb = nogc_new!Keyboard();
		mouse = nogc_new!Mouse();
		mainPollingFun = &poll_x11_RegularIO;
		devList ~= cast(InputDevice)keyb;
		devList ~= cast(InputDevice)mouse;

	}
	return InputInitializationStatus.AllOk;
}
version (Windows) {
	// TODO: Make game controllers work though rawinput, as an option
	package const RawGCMapping[] defaultGCmapping = [];
} else version (OSX) {

	package const RawGCMapping[] defaultGCmapping = [];
} else {
	package const RawGCMapping[] defaultGCmapping = [
		RawGCMapping(RawGCMappingType.Button, 0, EvdevGamepadButtons.SOUTH, GameControllerButtons.South),
		RawGCMapping(RawGCMappingType.Button, 0, EvdevGamepadButtons.EAST, GameControllerButtons.East),
		RawGCMapping(RawGCMappingType.Button, 0, EvdevGamepadButtons.C, GameControllerButtons.Btn_V),
		RawGCMapping(RawGCMappingType.Button, 0, EvdevGamepadButtons.NORTH, GameControllerButtons.North),
		RawGCMapping(RawGCMappingType.Button, 0, EvdevGamepadButtons.WEST, GameControllerButtons.West),
		RawGCMapping(RawGCMappingType.Button, 0, EvdevGamepadButtons.Z, GameControllerButtons.Btn_VI),
		RawGCMapping(RawGCMappingType.Button, 0, EvdevGamepadButtons.TL, GameControllerButtons.LeftShoulder),
		RawGCMapping(RawGCMappingType.Button, 0, EvdevGamepadButtons.TR, GameControllerButtons.RightShoulder),
		RawGCMapping(RawGCMappingType.Button, 0, EvdevGamepadButtons.TL2, GameControllerButtons.LeftTrigger),
		RawGCMapping(RawGCMappingType.Button, 0, EvdevGamepadButtons.TR2, GameControllerButtons.RightTrigger),
		RawGCMapping(RawGCMappingType.Button, 0, EvdevGamepadButtons.SELECT, GameControllerButtons.LeftNav),
		RawGCMapping(RawGCMappingType.Button, 0, EvdevGamepadButtons.START, GameControllerButtons.RightNav),
		RawGCMapping(RawGCMappingType.Button, 0, EvdevGamepadButtons.MODE, GameControllerButtons.Home),
		RawGCMapping(RawGCMappingType.Button, 0, EvdevGamepadButtons.THUMBL, GameControllerButtons.LeftThumbstick),
		RawGCMapping(RawGCMappingType.Button, 0, EvdevGamepadButtons.THUMBR, GameControllerButtons.RightThumbstick),
		RawGCMapping(RawGCMappingType.Button, 0, 0x13F, GameControllerButtons.Share),	//???

		RawGCMapping(RawGCMappingType.Hat, GameControllerButtons.DPadDown, EvdevAbsAxes.HAT0X, GameControllerButtons.DPadUp),
		RawGCMapping(RawGCMappingType.Hat, GameControllerButtons.DPadLeft,EvdevAbsAxes.HAT0Y,GameControllerButtons.DPadRight),

		RawGCMapping(RawGCMappingType.Axis, 0, EvdevAbsAxes.X, GameControllerAxes.LeftThumbstickX),
		RawGCMapping(RawGCMappingType.Axis, 0, EvdevAbsAxes.Y, GameControllerAxes.LeftThumbstickY),
		RawGCMapping(RawGCMappingType.Trigger, GameControllerButtons.LeftTrigger, EvdevAbsAxes.Z,
				GameControllerAxes.LeftTrigger),
		RawGCMapping(RawGCMappingType.Axis, 0, EvdevAbsAxes.RX, GameControllerAxes.RightThumbstickX),
		RawGCMapping(RawGCMappingType.Axis, 0, EvdevAbsAxes.RY, GameControllerAxes.RightThumbstickY),
		RawGCMapping(RawGCMappingType.Trigger, GameControllerButtons.RightTrigger, EvdevAbsAxes.RZ,
				GameControllerAxes.RightTrigger),
	];
	package InputDeviceType getEvdevDeviceType(int fd) @nogc nothrow {
		return InputDeviceType.init;
	}
}
/**
 * Goes through all the devices in the list, then removes them from the lists.
 * Returns: 0 on success, or a specific error code.
 */
public int removeInvalidatedDevices() @nogc nothrow {
	try {
		int numRemovedDevices;
		for (int i ; i < devList.length ; i++) {
			if (devList[i].isInvalidated) {
				devList[i].nogc_delete();
				numRemovedDevices++;
				for (int j = i ; j + 1 < devList.length ; j++) {
					devList[j] = devList[j + 1];
				}
			}
		}
		if (numRemovedDevices) devList.resize(devList.length - numRemovedDevices);
	} catch (NuException e) {
		e.free();
		return -1;
	} catch (Exception e) {
		return -2;
	}
	return 0;
}
/**
 * Checks for new devices and initializes them.
 * Returns: Zero, or a specific error code if it was unsuccessful.
 * Bugs: Does not work with XInput at the moment.
 */
public int checkForNewDevices() @nogc nothrow {
	version (Windows) {
		import iota.controls.backend.windows;
		if ((__configFlags & ConfigFlags.gc_Enable) && (__osConfigFlags & OSConfigFlags.win_XInput)) {
			for (int i ; i < 4 ; i++) {
				if (XInputDevice.ctrlList[i] !is null) {
					if (!XInputDevice.ctrlList[i].isInvalidated) continue;
				}
				XINPUT_CAPABILITIES xic;
				const DWORD result = XInputGetCapabilities(i, 0, &xic);
				if (result == ERROR_SUCCESS) {
					InputDevice x = nogc_new!XInputDevice(1, (__configFlags & ConfigFlags.gc_TriggerMode) != 0);
					if (!x.isInvalidated) devList ~= cast(InputDevice)x;
				}
			}
		}
	}
	return 0;
}
