module cocoa.nsapplication;

import cocoa.nswindow;
import cocoa.foundation;
import cocoa.nsevent;
import cocoa.nsdate;
import cocoa.nsmenu;

import objc.runtime;
@ObjectiveC final extern(C++):
@nogc nothrow:

enum NSApplicationActivationPolicy : NSInteger {
    Regular    = 0,
    Accessory  = 1,
    Prohibited = 2
}

class NSApplication {
    mixin ObjcExtend!NSObject;

nothrow @nogc:
    @selector("sharedApplication")
    static NSApplication sharedApplication();

    @selector("run")
    void run();

    @selector("terminate:")
    void terminate(NSObject sender);

    @selector("activateIgnoringOtherApps:")
    void activateIgnoringOtherApps(BOOL flag);

    @selector("setActivationPolicy:")
    BOOL setActivationPolicy(NSApplicationActivationPolicy activationPolicy);

    @selector("mainWindow")
    NSWindow mainWindow();

    @selector("windows")
    NSArray_!NSWindow windows();

    @selector("keyWindow")
    NSWindow keyWindow();

    @selector("nextEventMatchingMask:untilDate:inMode:dequeue:")
    NSEvent nextEventMatchingMask(NSUInteger mask, NSDate date, NSString mode, BOOL dequeue);

    @selector("sendEvent:")
    void sendEvent(NSEvent event);

    @selector("setMainMenu:")
    void setMainMenu(NSMenu);

    @selector("setDelegate:")
    void setDelegate(NSObject);
}

extern(D) NSApplication NSApp() @property nothrow @nogc {
    return NSApplication.sharedApplication();
}

