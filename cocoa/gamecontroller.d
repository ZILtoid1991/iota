module cocoa.gamecontroller;

import objc.runtime;
import cocoa.foundation;

enum GCHapticsLocality {
    Left = 1,
    Right = 2
}

@ObjectiveC final extern(C++):
@nogc nothrow:

class GCController {
    mixin ObjcExtend!NSObject;

    @selector("haptics")
    GCHaptics haptics() @trusted nothrow;
}

class GCHaptics {
    mixin ObjcExtend!NSObject;

    @selector("createEngine:")
    GCHapticsEngine createEngine(NSInteger locality) @trusted nothrow;

    @selector("cancelAll")
    void cancelAll() @trusted nothrow;
}

class GCHapticsEngine {
    mixin ObjcExtend!NSObject;

    @selector("createContinuousEvent:intensity:")
    void createContinuousEvent(CGFloat intensity) @trusted nothrow;
}

