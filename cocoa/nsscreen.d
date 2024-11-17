module cocoa.nsscreen;

import objc.runtime;
import cocoa.foundation;

@ObjectiveC final extern(C++):
@nogc nothrow:

class NSScreen {
    mixin ObjcExtend!NSObject;

    @selector("mainScreen")
    static NSScreen mainScreen() nothrow @nogc;

    @selector("frame")
    CGRect frame() nothrow @nogc;
}

