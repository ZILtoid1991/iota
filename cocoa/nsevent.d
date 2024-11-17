module cocoa.nsevent;

import cocoa.foundation;
import cocoa.nswindow;

import objc.meta;
import objc.runtime;

@ObjectiveC final extern(C++):
@nogc nothrow:

enum NSEventMaskAny = NSUIntegerMax;
enum NSUIntegerMax = size_t.max;

__gshared NSString NSDefaultRunLoopMode;
extern (D) static this() {
    NSDefaultRunLoopMode = "kCFRunLoopDefaultMode".ns;
}

enum NSEventType : NSUInteger {
    LeftMouseDown         = 1,
    LeftMouseUp          = 2,
    RightMouseDown       = 3,
    RightMouseUp         = 4,
    MouseMoved           = 5,
    LeftMouseDragged     = 6,
    RightMouseDragged    = 7,
    MouseEntered         = 8,
    MouseExited          = 9,
    KeyDown              = 10,
    KeyUp                = 11,
    FlagsChanged         = 12,
    ScrollWheel          = 22,
    TabletPoint         = 23,
    TabletProximity     = 24,
    OtherMouseDown      = 25,
    OtherMouseUp        = 26,
    OtherMouseDragged   = 27
}

enum NSEventMask : NSUInteger {
    LeftMouseDown         = 1 << NSEventType.LeftMouseDown,
    LeftMouseUp          = 1 << NSEventType.LeftMouseUp,
    RightMouseDown       = 1 << NSEventType.RightMouseDown,
    RightMouseUp         = 1 << NSEventType.RightMouseUp,
    MouseMoved           = 1 << NSEventType.MouseMoved,
    LeftMouseDragged     = 1 << NSEventType.LeftMouseDragged,
    RightMouseDragged    = 1 << NSEventType.RightMouseDragged,
    MouseEntered         = 1 << NSEventType.MouseEntered,
    MouseExited          = 1 << NSEventType.MouseExited,
    KeyDown              = 1 << NSEventType.KeyDown,
    KeyUp                = 1 << NSEventType.KeyUp,
    FlagsChanged         = 1 << NSEventType.FlagsChanged,
    ScrollWheel          = 1 << NSEventType.ScrollWheel,
    TabletPoint          = 1 << NSEventType.TabletPoint,
    TabletProximity      = 1 << NSEventType.TabletProximity,
    OtherMouseDown       = 1 << NSEventType.OtherMouseDown,
    OtherMouseUp         = 1 << NSEventType.OtherMouseUp,
    OtherMouseDragged    = 1 << NSEventType.OtherMouseDragged,
    AppKitDefined        = 1 << 13,
    SystemDefined        = 1 << 14,
    AnyEvent             = 0xffffffff
}

class NSEvent {
    mixin ObjcExtend!NSObject;

nothrow @nogc:
    @selector("type")
    NSEventType type();

    @selector("modifierFlags")
    NSEventModifierFlags modifierFlags();

    @selector("window")
    NSWindow window() @nogc nothrow;

    @selector("windowNumber")
    NSInteger windowNumber();

    @selector("keyCode")
    ushort keyCode();

    @selector("isARepeat")
    BOOL isARepeat();

    @selector("characters")
    NSString characters();

    @selector("addLocalMonitorForEventsMatchingMask:handler:")
    static NSObject addLocalMonitorForEventsMatchingMask(NSUInteger mask, NSEvent function(NSEvent) handler) @nogc nothrow;

    @selector("charactersIgnoringModifiers")
    NSString charactersIgnoringModifiers();

    @selector("addLocalMonitorForEventsMatchingMask:handler:")
    static NSObject addLocalMonitorForEventsMatchingMask(NSEventMask mask, NSEvent function(NSEvent) @nogc nothrow handler);

    @selector("locationInWindow")
    CGPoint locationInWindow();

    @selector("timestamp") 
    CGFloat timestamp();

    @selector("deltaX")
    CGFloat deltaX();

    @selector("deltaY")
    CGFloat deltaY();

    @selector("deltaZ")
    CGFloat deltaZ();
}

