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
    OSWindow inputSurface = new OSWindow("Iota input test", "inputSurface", 0, 0, 640, 480, WindowStyleIDs.Visible | 
            WindowStyleIDs.AppWindow);
    Thread.sleep(msecs(10000));
    return 0;
}