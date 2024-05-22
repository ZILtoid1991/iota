module iota.controls;

import std.typecons;

public import iota.controls.types;
public import iota.controls.keyboard;
public import iota.controls.mouse;
public import iota.controls.system;
public import iota.controls.gamectrl;
public import iota.controls.polling;
public import iota.window.oswindow;

version (Windows) {
	import core.sys.windows.windows;
	import core.sys.windows.wtypes;
}
import core.stdc.stdlib;
import std.utf;
import std.stdio;

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
		/* if (config & ConfigFlags.gc_Enable) {
			import iota.controls.backend.windows;
			XInputEnable(256);
			for (int i ; i < 4 ; i++) {
				XInputDevice x = new XInputDevice(i, (config & ConfigFlags.gc_TriggerMode) != 0);
				if (!x.isInvalidated) {
					devList ~= x;
				}
			}
		} */
		if (osConfig & OSConfigFlags.win_RawInput) {
			const DWORD flags = 0; //= 0x00002000 | RIDEV_NOHOTKEYS;
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
			ubyte kbNum, mNum;
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
						version (iota_use_utf8) {
							m = new Mouse(toUTF8(data[0..nameRes]), mNum++, dev.hDevice);
						} else {
							m = new Mouse(toUTF32(data[0..nameRes]), mNum++, dev.hDevice);
						}
						devList ~= m;
						mouse = m;
						break;
					case RIM_TYPEKEYBOARD:
						//debug writeln("Keyboard: ", data[0..nameRes]);
						Keyboard k;
						version (iota_use_utf8) {
							k = new Keyboard(toUTF8(data[0..nameRes]), kbNum++, dev.hDevice);
						} else {
							k = new Keyboard(toUTF32(data[0..nameRes]), kbNum++, dev.hDevice);
						}
						devList ~= k;
						keyb = k;
						break;
					default:	//Must be RIM_TYPEHID
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
			}
		}
	} else {
		keyb = new Keyboard();
		mouse = new Mouse();
		mainPollingFun = &poll_x11_RegularIO;
		devList ~= keyb;
		devList ~= mouse;
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