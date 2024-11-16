module cocoa.nsmenu;

import objc.runtime;
import objc.meta: SEL;
import cocoa.foundation;

@ObjectiveC final extern(C++):
@nogc nothrow:

class NSMenu {
    mixin ObjcExtend!NSObject;
    
nothrow @nogc:
    @selector("new")
    static NSMenu new_() nothrow @nogc;
    
    @selector("addItem:")
    void addItem(NSMenuItem);
}

class NSMenuItem {
    mixin ObjcExtend!NSObject;

nothrow @nogc:
    @selector("initWithTitle:action:keyEquivalent:")
    NSMenuItem initWithTitle(NSString title, void* action, NSString keyEquivalent);

    @selector("alloc")
    static NSMenuItem alloc() nothrow @nogc;
    
    @selector("new")
    static NSMenuItem new_() nothrow @nogc;
    
    @selector("init")
    NSMenuItem initialize();
    
    @selector("setSubmenu:")
    void setSubmenu(NSMenu);
    
    @selector("setTarget:")
    void setTarget(NSObject);
    
    @selector("setAction:")
    void setAction(SEL);
    
    @selector("setKeyEquivalentModifierMask:")
    void setKeyEquivalentModifierMask(NSEventModifierFlags);
}

