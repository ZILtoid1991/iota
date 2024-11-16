import std.stdio;
import std.conv : to;
import std.file : readText;
import core.thread;
import iota.controls;
import iota.controls.keybscancodes;
import iota.window;

import darg;

version (Windows) {
	import core.sys.windows.windows;
} else version(OSX) {
	import cocoa;
	import metal;
	import iota.controls.polling : poll;
}

struct Options {
	@Option("config", "c")
	@Help("Sets initInput's configflags to the given value.")
	uint configFlags;

	@Option("osconfig", "o")
	@Help("Sets initInput's OS configflags to the given value.")
	uint osconfigFlags;

	@Option("rumbletest", "r")
	@Help("Enables rumble test for game controller devices.")
	int rumbletest;

	@Option("textinputtest", "t")
	@Help("Enables text input for testing.")
	int textinputtest;

	@Option("mappingSrc", "s")
	@Help("Sets the game controller mapping table source.")
	string mappingSrc;
}

immutable usage = usageString!Options("IOTA input tester");
immutable help = helpString!Options();

const(ubyte)[] iconData = cast(const(ubyte)[])import("icon");

void printDeviceList() {
    version(OSX) {
        auto devList = MTLCopyAllDevices();
        writeln("Number of devices: ", devList.count);
        for (NSUInteger i = 0; i < devList.count; i++) {
            auto device = cast(MTLDevice)devList.objectAtIndex(i);
            writeln("  Device ", i, ": ", device.name.toString);
        }
    }
    else {
		writeln(devList);
    }
}

int main(string[] args) {
	//initWindow_ext();
	Options options;

	try {
		options = parseArgs!Options(args[1..$]);
	} catch (ArgParseError e) {
		writeln(e);
		writeln(usage);
		return 1;
	} catch (ArgParseHelp e) {
		writeln(usage);
		writeln(help);
		return 0;
	}
	string mappingSrc;
	if (options.mappingSrc) mappingSrc = readText(options.mappingSrc);

	OSWindow inputSurface;
	try {
		inputSurface =
			new OSWindow("Iota input test", "inputSurface", -1, -1, 640, 480, WindowCfgFlags.IgnoreMenuKey,
			new WindowBitmap(32, 32, iconData.dup));
	} catch (WindowCreationException e) {
		writeln(e);
		return 1;
	}
	int errCode = initInput(options.configFlags, options.osconfigFlags);
	if (errCode) {
		writeln("Input initialization error! Code: ", errCode, /* " OSCode: ", GetLastError() */);
		return 1;
	}
	printDeviceList();
	bool isRunning = true;
	keyb.setTextInput(options.textinputtest == 1);
	while (isRunning) {
		InputEvent event;
		poll(event);
		if (event.type == InputEventType.ApplExit || event.type == InputEventType.WindowClose) {
			isRunning = false;
		} else if (event.type != InputEventType.init) {
			if (event.type == InputEventType.GCButton && event.source.isHapticCapable && options.rumbletest) {
				if (event.button.id == GameControllerButtons.LeftTrigger) {
					HapticDevice hd = cast(HapticDevice)event.source;
					hd.applyEffect(HapticDevice.Capabilities.LeftMotor, 0, event.button.auxF);
				}
				if (event.button.id == GameControllerButtons.RightTrigger) {
					HapticDevice hd = cast(HapticDevice)event.source;
					hd.applyEffect(HapticDevice.Capabilities.RightMotor, 0, event.button.auxF);
				}
			} else if (event.type == InputEventType.Keyboard) {
				switch (event.button.id) {
				case ScanCode.A:
					inputSurface.setCursor(StandardCursors.Arrow);
					break;
				case ScanCode.B:
					inputSurface.setCursor(StandardCursors.TextSelect);
					break;
				case ScanCode.C:
					inputSurface.setCursor(StandardCursors.Busy);
					break;
				case ScanCode.D:
					inputSurface.setCursor(StandardCursors.PrecisionSelect);
					break;
				case ScanCode.E:
					inputSurface.setCursor(StandardCursors.AltSelect);
					break;
				case ScanCode.F:
					inputSurface.setCursor(StandardCursors.ResizeTopLeft);
					break;
				case ScanCode.G:
					inputSurface.setCursor(StandardCursors.ResizeTopRight);
					break;
				case ScanCode.H:
					inputSurface.setCursor(StandardCursors.ResizeBottomLeft);
					break;
				case ScanCode.I:
					inputSurface.setCursor(StandardCursors.ResizeBottomRight);
					break;
				case ScanCode.J:
					inputSurface.setCursor(StandardCursors.ResizeLeft);
					break;
				case ScanCode.K:
					inputSurface.setCursor(StandardCursors.ResizeRight);
					break;
				case ScanCode.L:
					inputSurface.setCursor(StandardCursors.ResizeTop);
					break;
				case ScanCode.M:
					inputSurface.setCursor(StandardCursors.ResizeBottom);
					break;
				case ScanCode.N:
					inputSurface.setCursor(StandardCursors.Move);
					break;
				case ScanCode.O:
					inputSurface.setCursor(StandardCursors.Forbidden);
					break;
				case ScanCode.P:
					inputSurface.setCursor(StandardCursors.Hand);
					break;
				case ScanCode.Q:
					inputSurface.setCursor(StandardCursors.WaitArrow);
					break;
				case ScanCode.R:
					inputSurface.setCursor(StandardCursors.HelpSelect);
					break;
				case ScanCode.S:
					inputSurface.setCursor(StandardCursors.LocationSelect);
					break;
				case ScanCode.T:
					inputSurface.setCursor(StandardCursors.PersonSelect);
					break;
				case ScanCode.U:
					inputSurface.setCursor(StandardCursors.ResizeHoriz);
					break;
				case ScanCode.V:
					inputSurface.setCursor(StandardCursors.ResizeVert);
					break;
				case ScanCode.F5:
					checkForNewDevices();
					printDeviceList();
					break;
				default: break;
				}
			} else if (event.type == InputEventType.DeviceRemoved) {
				removeInvalidatedDevices();
				printDeviceList();
			} else if (event.type == InputEventType.DeviceAdded) {
				checkForNewDevices();
				printDeviceList();
			}
			writeln(event.toString());
		}
		Thread.sleep(dur!"msecs"(10));
	}
	destroy(inputSurface);
	return 0;
}
