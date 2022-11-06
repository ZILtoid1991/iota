module iota.controls;

import std.typecons;

public import iota.controls.types;
public import iota.controls.keyboard;
public import iota.controls.mouse;
public import iota.controls.system;

version (Windows) {
	import core.sys.windows.windows;
	import core.sys.windows.wtypes;
}
import core.stdc.stdlib;
import std.utf;

///Contains all input devices, including some invalidated ones.
package static InputDevice[]    deviceList;
///Contains the polling position.
package static size_t           pollPos;

package enum IOTA_INPUTCONFIG_DEFAULT = 0;
/** 
 * Initializes the input subsystem
 * Params:
 *   config = Configuration flags ORed together.
 *   osConfig = OS-specific configuration flags ORed together.
 * Returns: 0 if everything is successful, or a specific errorcode.
 */
public int initInput(uint config = 0, uint osConfig = 0) nothrow {
	config |= IOTA_INPUTCONFIG_DEFAULT;
	System s = new System(config, osConfig);
	deviceList ~= s;
	version (Windows) {
		if (!(osConfig & OSConfigFlags.win_LegacyIO)) {
			RAWINPUTDEVICE[] rid;
			if (osConfig & OSConfigFlags.win_RawKeyboard)
				rid ~= RAWINPUTDEVICE(0x0001, 0x0006, 0x2000, null);
			if (osConfig & OSConfigFlags.win_RawMouse)
				rid ~= RAWINPUTDEVICE(0x0001, 0x0002, 0x2000, null);
			if (config & ConfigFlags.enableTouchscreen) {
				rid ~= RAWINPUTDEVICE(0x000D, 0x0004, 0x2000, null);
			}
			if (RegisterRawInputDevices(rid.ptr, cast(UINT)rid.length, cast(UINT)(RAWINPUTDEVICE.sizeof)) == FALSE) {
				return InputInitializationStatus.WindowsRawInputError;
			}
			RAWINPUTDEVICELIST[] devices;
			UINT nDevices;
			if (GetRawInputDeviceList(null, &nDevices, cast(UINT)(RAWINPUTDEVICELIST.sizeof)))
				return InputInitializationStatus.WindowsRawInputError;
			devices.length = nDevices;
			nDevices = GetRawInputDeviceList(devices.ptr, &nDevices, cast(UINT)(RAWINPUTDEVICELIST.sizeof));
			if (nDevices == cast(uint)-1)
				return InputInitializationStatus.WindowsDevicesAdded;
			ubyte kbNum, mNum;
			foreach (RAWINPUTDEVICELIST dev ; devices) {
				wchar[] data;
				data.length = 256;
				UINT nameLen = 256;
				UINT nameRes = GetRawInputDeviceInfoW(dev.hDevice, RIDI_DEVICENAME, cast(void*)data.ptr, &nameLen);
				if (nameRes == cast(UINT)-1)
					return InputInitializationStatus.WindowsRawInputError;
				switch (dev.dwType) {
					case RIM_TYPEMOUSE:
						version (iota_use_utf8) {
							s.mouseList ~= new Mouse(toUTF8(data), mNum++, dev.hDevice);
						} else {
							s.mouseList ~= new Mouse(toUTF32(data), mNum++, dev.hDevice);
						}
						break;
					case RIM_TYPEKEYBOARD:
						version (iota_use_utf8) {
							s.keybList ~= new Keyboard(toUTF8(data), kbNum++, dev.hDevice);
						} else {
							s.keybList ~= new Keyboard(toUTF32(data), kbNum++, dev.hDevice);
						}
						break;
					default:
						break;
				}
			}
			if (s.keybList.length)
				s.keyb = s.keybList[0];
			if (s.mouseList.length)
				s.mouse = s.mouseList[0];
		}
	}
	return InputInitializationStatus.AllOk;
}
/** 
 * Polls all input devices one by one.
 * Params:
 *   output = The input event is returned here.
 * Returns: 1 if there's more, 0 if all input events have been processed, or a specific error code.
 */
public int pollInputs(ref InputEvent output) nothrow {
	if (!deviceList.length) return EventPollStatus.NoDevsFound;
	if (pollPos == deviceList.length) pollPos = 0;
	int statusCode;
	while (pollPos < deviceList.length && !statusCode) {
		statusCode = deviceList[pollPos].poll(output);
		if (!statusCode) pollPos++;				//Step to next device, this one has no more events
	}
	if (statusCode != 1) return statusCode;	//There's an error code from the current input device
	return pollPos == deviceList.length ? EventPollStatus.Done : EventPollStatus.HasMore;
}
public int removeInvalidDevs() nothrow {
	
	return 0;
}