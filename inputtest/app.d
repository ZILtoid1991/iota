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

mixin(IOTA_OSENTRY_CMDARGS);

int prgEntry(iota_cmd_arg_t args) {
    OSWindow inputSurface = new OSWindow("Iota input test", "inputSurface", 0, 0, 640, 480, WindowStyleIDs.Default);
    Thread.sleep(msecs(1000));
    return 0;
}