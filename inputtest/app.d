import std.stdio;
import std.conv : to;
import core.thread;
import iota.controls;
import iota.controls.keybscancodes;
import iota.window;

import darg;

version (Windows) {
	import core.sys.windows.windows;
}

struct Options {
	@Option("config", "c")
	@Help("Sets initInput's configflags to the given value.")
	uint configFlags;

	@Option("osconfig", "o")
	@Help("Sets initInput's OS configflags to the given value.")
	uint osconfigFlags;

	@Option("rumbletest", "r")
	@Help("Enables rumble test for XInput devices.")
	int rumbletest;
}

immutable usage = usageString!Options("IOTA input tester");
immutable help = helpString!Options();

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

	OSWindow inputSurface = 
			new OSWindow("Iota input test", "inputSurface", -1, -1, 640, 480, WindowCfgFlags.IgnoreMenuKey);
	//inputSurface.drawDeleg = &inputSurface.testDraw;
	//inputSurface.maximizeWindow();
	//Thread.sleep(msecs(10_000));
	int errCode = initInput(options.configFlags, options.osconfigFlags);
	if (errCode) {
		writeln("Input initialization error! Code: ", errCode, /* " OSCode: ", GetLastError() */);
		return 1;
	}
	writeln(devList);
	bool isRunning = true;
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
			}
			writeln(event.toString());
		}
		Thread.sleep(dur!"msecs"(10));
	}
	return 0;
}