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
    OSWindow inputSurface = new OSWindow("Iota input test", "inputSurface", 640, 480, 640, 480, WindowStyleIDs.Default | 
            WindowStyleIDs.AppWindow);
    Thread.sleep(msecs(10_000));
    initInput();
    bool isRunning = true;
    while (isRunning) {
        InputEvent event;
        pollInputs(event);
        if (event.type == InputEventType.ApplExit) {
            isRunning = false;
        } else {
            writeln(event.toString());
        }
    }
    return 0;
}