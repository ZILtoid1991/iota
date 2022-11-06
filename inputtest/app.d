import std.stdio;
import std.conv : to;
import core.thread;
import iota.controls;
import iota.controls.keybscancodes;
import iota.window;
import iota.etc.osentry;

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
}

immutable usage = usageString!Options("IOTA input tester");
immutable help = helpString!Options();

int main(string[] args) {
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

	OSWindow inputSurface = new OSWindow("Iota input test", "inputSurface", 1, 1, 640, 480, WindowStyleIDs.Default);
	inputSurface.frameDrawDeleg = &inputSurface.testDraw;
	//inputSurface.maximizeWindow();
	//Thread.sleep(msecs(10_000));
	int errCode = initInput(options.configFlags, options.osconfigFlags);
	if (errCode) {
		writeln("Input initialization error! Code: ", errCode);
		return 1;
	}
	bool isRunning = true;
	while (isRunning) {
		InputEvent event;
		pollInputs(event);
		if (event.type == InputEventType.ApplExit || event.type == InputEventType.WindowClose) {
			isRunning = false;
		} else {
			writeln(event.toString());
		}
	}
	return 0;
}