module iota.controls;

import std.typecons;

public import iota.controls.types;
public import iota.controls.keyboard;
public import iota.controls.mouse;
public import iota.controls.system;
public import iota.controls.gamectrl;
public import iota.controls.polling;

version (Windows) {
	import core.sys.windows.windows;
	import core.sys.windows.wtypes;
}
import core.stdc.stdlib;
import std.utf;

public enum IOTA_INPUTCONFIG_MANDATORY = 0;
/** 
 * Initializes the input subsystem
 * Params:
 *   config = Configuration flags ORed together.
 *   osConfig = OS-specific configuration flags ORed together.
 * Returns: 0 if everything is successful, or a specific errorcode.
 */
public int initInput(uint config = 0, uint osConfig = 0) nothrow {
	config |= IOTA_INPUTCONFIG_MANDATORY;
	sys = new System(config, osConfig);
	devList ~= sys;
	version (Windows) {
		if (config & ConfigFlags.gc_Enable) {
			import iota.controls.backend.windows;
			XInputEnable(256);
			for (int i ; i < 4 ; i++) {
				XInputDevice x = new XInputDevice(i, (config & ConfigFlags.gc_TriggerMode) != 0);
				if (!x.isInvalidated) {
					devList ~= x;
				}
			}
		}
		if (osConfig & OSConfigFlags.win_RawInput) {
			RAWINPUTDEVICE[] rid;
			rid ~= RAWINPUTDEVICE(0x0001, 0x0006, 0, null);
			rid ~= RAWINPUTDEVICE(0x0001, 0x0002, 0, null);
			if (config & ConfigFlags.enableTouchscreen) {
				rid ~= RAWINPUTDEVICE(0x000D, 0x0004, 0x2000, null);
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
			ubyte kbNum, mNum;
			foreach (RAWINPUTDEVICELIST dev ; devices) {
				wchar[] data;
				data.length = 256;
				UINT nameLen = 256;
				UINT nameRes = GetRawInputDeviceInfoW(dev.hDevice, RIDI_DEVICENAME, cast(void*)data.ptr, &nameLen);
				//HANDLE hdevice = dev.hDevice;
				if (nameRes == cast(UINT)-1)
					return InputInitializationStatus.win_RawInputError;
				switch (dev.dwType) {
					case RIM_TYPEMOUSE:
						version (iota_use_utf8) {
							devList ~= mouse = new Mouse(toUTF8(data[0..nameRes]), mNum++, dev.hDevice);
						} else {
							devList ~= mouse = new Mouse(toUTF32(data[0..nameRes]), mNum++, dev.hDevice);
						}
						break;
					case RIM_TYPEKEYBOARD:
						version (iota_use_utf8) {
							devList ~= keyb = new Keyboard(toUTF8(data[0..nameRes]), kbNum++, dev.hDevice);
						} else {
							devList ~= keyb = new Keyboard(toUTF32(data[0..nameRes]), kbNum++, dev.hDevice);
						}
						break;
					default:
						break;
				}
				if (keyb is null) keyb = new Keyboard();
				if (mouse is null) mouse = new Mouse();
				mainPollingFun = &poll_win_RawInput;
			}
		} else {
			keyb = new Keyboard();
			mouse = new Mouse();
			mainPollingFun = &poll_win_LegacyIO;
		}
	}
	return InputInitializationStatus.AllOk;
}
public int removeInvalidatedDevices() {
	for (int i ; i < devList.length ; i++) {
		if (devList[i].isInvalidated) {
			devList = devList[0..i] ~ devList[i + 1..$];
		}
	}
	return 0;
}