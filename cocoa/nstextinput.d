module cocoa.nstextinput;

import objc.runtime;
import cocoa.foundation;

@ObjectiveC final extern(C++):
@nogc nothrow:

class NSTextInputContext {
    mixin ObjcExtend!NSObject;

    @selector("currentInputContext")
    static NSTextInputContext currentInputContext() nothrow @nogc @trusted;

    @selector("selectedKeyboardInputSource")
    NSNumber selectedKeyboardInputSource() nothrow @nogc @trusted;
}

