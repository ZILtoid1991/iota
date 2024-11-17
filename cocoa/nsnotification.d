module cocoa.nsnotification;

import objc.runtime;
import objc.meta;

@ObjectiveC final extern(C++):
@nogc nothrow:

class NSNotification {
    mixin ObjcExtend!NSObject;

nothrow @nogc:
    @selector("object")
    NSObject object();
    
    @selector("userInfo")
    NSDictionary userInfo();
}

