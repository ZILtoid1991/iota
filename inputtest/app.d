import std.stdio;
import std.conv : to;
import iota.controls;
import iota.controls.keybscancodes;
import iota.etc.window;
version (Windows) {
    import core.sys.windows.windows;
}

void main(string[] args) {
    int status = initInput();
    if (status)
        return;
    auto x = createWindow("Test", 5, 5, 500, 100, null);
    if (!x) {
        writeln("Window wasn't created!");
        version (Windows) {
            //wchar[128] errMsg;
            auto errcode = GetLastError();
            writeln(errcode);
            //FormatMessageW(FORMAT_MESSAGE_ARGUMENT_ARRAY, null, GetLastError(), 0, errMsg.ptr, errMsg.length, null);
            //writeln(errMsg);
        }
        return;
    }
    do {
        InputEvent ie;
        status = pollInputs(ie);
        if (status == 1) {
            writeln(ie.toString());
            if (ie.type == InputEventType.WindowClose || ie.type == InputEventType.ApplExit)
                return;
        }
    } while (true);
}