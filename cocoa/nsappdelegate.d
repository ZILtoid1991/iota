module cocoa.nsappdelegate;

import objc.meta : selector, ObjcExtend, ObjectiveC;
import objc.runtime;
import cocoa.foundation;
import cocoa.nsapplication;
import cocoa.nswindow;
import cocoa.nsnotification;

@ObjectiveC extern(C++):
@nogc nothrow:

interface NSApplicationDelegate {
}

@ObjectiveC final extern(C++):
class AppDelegate {
    mixin ObjcExtend!NSObject;

    static AppDelegate alloc() @selector("alloc") nothrow @nogc;
    AppDelegate initialize() @selector("init");

    void applicationDidFinishLaunching(NSNotification notification) @selector("applicationDidFinishLaunching:");
    BOOL applicationShouldTerminateAfterLastWindowClosed(NSApplication sender) @selector("applicationShouldTerminateAfterLastWindowClosed:");
}

