import std.stdio;
import std.conv : to;
import core.thread;
import iota.controls;
import iota.controls.keybscancodes;
import iota.window;
import iota.etc.osentry;

version (Windows) {
	import core.sys.windows.windows;
}

int main(string[] args) {
	OSWindow inputSurface = new OSWindow("Iota input test", "inputSurface", 1, 1, 640, 480, WindowStyleIDs.Default);
	//inputSurface.maximizeWindow();
	//Thread.sleep(msecs(10_000));
	initInput();
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