module iota.controls;

import std.typecons;

public import iota.controls.types;
public import iota.controls.keyboard;
public import iota.controls.mouse;
public import iota.controls.system;
public import iota.controls.gamectrl;
public import iota.controls.polling : mainPollingFun, keyb, mouse, sys, devList;
public import iota.window.oswindow;

version (Windows) {
	import core.sys.windows.windows;
	import core.sys.windows.wtypes;
} else version (OSX) {
	import cocoa.foundation;
	import iota.controls.polling : poll_osx;
} else {
	import iota.controls.backend.linux;
	import core.stdc.errno;
	//import core.sys.linux.fcntl;
}
import core.stdc.stdlib;
//import core.stdc.stdio;
import std.conv : to;
import std.string : toStringz, fromStringz, splitLines, split;
import std.utf;
import std.uni : toLower;
import std.stdio;

static this() {
    version(Windows) {
        mainPollingFun = &poll_win_LegacyIO;
    } else version(OSX) {
        mainPollingFun = &poll_osx;
    } else {
        mainPollingFun = &poll_x11_RegularIO;
    }
}


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
	sys = new System(config, osConfig);
	devList ~= sys;
	version (Windows) {
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
				if (osConfig & OSConfigFlags.win_XInput) {
					import iota.controls.backend.windows;
					XInputEnable(256);
					for (int i ; i < 4 ; i++) {
						XInputDevice x = new XInputDevice(i, (config & ConfigFlags.gc_TriggerMode) != 0);
						if (!x.isInvalidated) {
							devList ~= x;
						}
					}
					subPollingFun = &XInputDevice.poll;
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
						//debug writeln("Mouse: ", data[0..nameRes]);
						Mouse m;
						m = new Mouse(toUTF8(data[0..nameRes]), mNum++, dev.hDevice);
						devList ~= m;
						mouse = m;
						break;
					case RIM_TYPEKEYBOARD:
						//debug writeln("Keyboard: ", data[0..nameRes]);
						Keyboard k;
						k = new Keyboard(toUTF8(data[0..nameRes]), kbNum++, dev.hDevice);
						devList ~= k;
						keyb = k;
						break;
					default:	//Must be RIM_TYPEHID
						try {
							RawGCMapping[] mapping = parseGCM(gcmTable, toUTF8(data[0..nameRes]));
							if (mapping.length) {
								devList ~= new RawInputGameController(toUTF8(data[0..nameRes]), gcNum++, dev.hDevice, mapping);
							}
						} catch (Exception e) {}
						//debug writeln("Other device: ", data[0..nameRes]);	//For now, just print whatever name we get.
						break;
				}
				//if (keyb is null) keyb = new Keyboard();
				//if (mouse is null) mouse = new Mouse();
				mainPollingFun = &poll_win_RawInput;
			}
		} else {
			keyb = new Keyboard();
			mouse = new Mouse();
			devList ~= keyb;
			devList ~= mouse;
			mainPollingFun = &poll_win_LegacyIO;
			if (config & ConfigFlags.gc_Enable) {
				import iota.controls.backend.windows;
				XInputEnable(256);
				for (int i ; i < 4 ; i++) {
					XInputDevice x = new XInputDevice(i, (config & ConfigFlags.gc_TriggerMode) != 0);
					if (!x.isInvalidated) {
						devList ~= x;
					}
				}
				subPollingFun = &XInputDevice.poll;
			}
		}
	} else version(OSX) {
	    keyb = new Keyboard();
	    mouse = new Mouse();
	    mainPollingFun = &poll_osx;
	    devList ~= keyb;
	    devList ~= mouse;
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
							continue;
							//if (errno == 13) return InputInitializationStatus.libevdev_AccessDenied;
							//return InputInitializationStatus.libevdev_ErrorOpeningDev;
						}
						libevdev* dev;
						if (libevdev_new_from_fd(fd, &dev) < 0) {
							close(fd);
							continue;
							//return InputInitializationStatus.libevdev_ErrorOpeningDev;
						}
						string name = cast(string)fromStringz(libevdev_get_name(dev));
						uint typeID = libevdev_has_event_type(dev, EV_SYN);
						typeID |= libevdev_has_event_type(dev, EV_KEY)<<0x01;
						typeID |= libevdev_has_event_type(dev, EV_REL)<<0x02;
						typeID |= libevdev_has_event_type(dev, EV_ABS)<<0x03;
						typeID |= libevdev_has_event_type(dev, EV_MSC)<<0x04;
						typeID |= libevdev_has_event_type(dev, EV_SW)<<0x05;
						typeID |= libevdev_has_event_type(dev, EV_LED)<<0x11;
						typeID |= libevdev_has_event_type(dev, EV_SND)<<0x12;
						typeID |= libevdev_has_event_type(dev, EV_REP)<<0x14;
						typeID |= libevdev_has_event_type(dev, EV_FF)<<0x15;
						typeID |= libevdev_has_event_type(dev, EV_PWR)<<0x16;
						typeID |= libevdev_has_event_type(dev, EV_FF_STATUS)<<0x17;
						string nameLC = toLower(name);
						//Try to detect device type from name
						if (canFind(nameLC, "keyboard", "keypad")) {
							devList ~= new Keyboard(name, keybCnrt++, fd, dev);
						} else if (canFind(nameLC, "mouse", "trackball")) {
							devList ~= new Mouse(name, mouseCnrt++, fd, dev);
						} else if (canFind(entry.name(), "js")) {	//Likely a game controller, let's check the supplied table if exists
							string uniqueID = cast(string)fromStringz(libevdev_get_uniq(dev));
							RawGCMapping[] mapping;
							if (gcmTable) mapping = parseGCM(gcmTable, uniqueID);
							if (!mapping) mapping = defaultGCmapping.dup;
							devList ~= new RawInputGameController(name, gcCnrt++, fd, dev, mapping);
						} else {
							libevdev_free(dev);
							close(fd);
						}
					}
				}
				//if (!(keybCnrt + mouseCnrt + gcCnrt)) return InputInitializationStatus.libevdev_AccessDenied;
				subPollingFun = &poll_evdev;
			} catch (Exception e) {
				//debug writeln(e);
				return InputInitializationStatus.libevdev_ErrorOpeningDev;
			}
		} //else {
		keyb = new Keyboard();
		mouse = new Mouse();
		mainPollingFun = &poll_x11_RegularIO;
		devList ~= keyb;
		devList ~= mouse;
		//}
	}
	return InputInitializationStatus.AllOk;
}
version (Windows) {
	package const RawGCMapping[] defaultGCmapping = [];
} else version (OSX) {
} else {
	package const RawGCMapping[] defaultGCmapping = [
		RawGCMapping(RawGCMappingType.Button, 0, 0, GameControllerButtons.South),
		RawGCMapping(RawGCMappingType.Button, 0, 1, GameControllerButtons.East),
		RawGCMapping(RawGCMappingType.Button, 0, 2, GameControllerButtons.Btn_V),
		RawGCMapping(RawGCMappingType.Button, 0, 3, GameControllerButtons.North),
		RawGCMapping(RawGCMappingType.Button, 0, 4, GameControllerButtons.West),
		RawGCMapping(RawGCMappingType.Button, 0, 5, GameControllerButtons.Btn_VI),
		RawGCMapping(RawGCMappingType.Button, 0, 6, GameControllerButtons.LeftShoulder),
		RawGCMapping(RawGCMappingType.Button, 0, 7, GameControllerButtons.RightShoulder),
		RawGCMapping(RawGCMappingType.Button, 0, 8, GameControllerButtons.LeftTrigger),
		RawGCMapping(RawGCMappingType.Button, 0, 9, GameControllerButtons.RightTrigger),
		RawGCMapping(RawGCMappingType.Button, 0, 10, GameControllerButtons.LeftNav),
		RawGCMapping(RawGCMappingType.Button, 0, 11, GameControllerButtons.RightNav),
		RawGCMapping(RawGCMappingType.Button, 0, 12, GameControllerButtons.Home),
		RawGCMapping(RawGCMappingType.Button, 0, 13, GameControllerButtons.LeftThumbstick),
		RawGCMapping(RawGCMappingType.Button, 0, 14, GameControllerButtons.RightThumbstick),
		RawGCMapping(RawGCMappingType.Button, 0, 15, GameControllerButtons.Share),	//???

		RawGCMapping(RawGCMappingType.Hat, 1, 16, GameControllerButtons.DPadLeft),
		RawGCMapping(RawGCMappingType.Hat, 2, 16, GameControllerButtons.DPadRight),
		RawGCMapping(RawGCMappingType.Hat, 1, 17, GameControllerButtons.DPadDown),
		RawGCMapping(RawGCMappingType.Hat, 2, 17, GameControllerButtons.DPadUp),

		RawGCMapping(RawGCMappingType.Axis, 0, 0, GameControllerAxes.LeftThumbstickX),
		RawGCMapping(RawGCMappingType.Axis, 0, 1, GameControllerAxes.LeftThumbstickY),
		RawGCMapping(RawGCMappingType.Axis, 0, 2, GameControllerAxes.LeftTrigger),
		RawGCMapping(RawGCMappingType.Axis, 0, 3, GameControllerAxes.RightThumbstickX),
		RawGCMapping(RawGCMappingType.Axis, 0, 4, GameControllerAxes.RightThumbstickY),
		RawGCMapping(RawGCMappingType.Axis, 0, 5, GameControllerAxes.RightTrigger),
	];
}

public int removeInvalidatedDevices() {
	for (int i ; i < devList.length ; i++) {
		if (devList[i].isInvalidated) {
			devList = devList[0..i] ~ devList[i + 1..$];
		}
	}
	return 0;
}
/**
 * Checks for new devices and initializes them.
 * Returns: Zero, or a specific error code if it was unsuccessful.
 * Bugs: Does not work with XInput at the moment.
 */
public int checkForNewDevices() {
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
					InputDevice x = new XInputDevice(1, (__configFlags & ConfigFlags.gc_TriggerMode) != 0);
					if (!x.isInvalidated) devList ~= x;
				}
			}
		}
	}
	return 0;
}
