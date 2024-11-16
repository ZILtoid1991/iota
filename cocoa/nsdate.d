module cocoa.nsdate;

import objc.runtime;
import cocoa.foundation;

@ObjectiveC final extern(C++):
@nogc nothrow:

class NSDate {
    mixin ObjcExtend!NSObject;

nothrow @nogc:
    @selector("distantPast")
    static NSDate distantPast();
}

