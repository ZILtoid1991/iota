module cocoa.nsview;

import cocoa.foundation;
import cocoa.nswindow;

import objc.runtime;
@ObjectiveC final extern(C++):
@nogc nothrow:

enum NSViewLayerContentsRedrawPolicy : NSInteger {
    Never                   = 0,
    OnSetNeedsDisplay      = 1,
    DuringViewResize       = 2,
    BeforeViewResize       = 3,
    Crossfade              = 4
}

enum NSViewLayerContentsPlacement : NSInteger {
    ScaleAxesIndependently = 0,
    ScaleProportionallyToFit = 1,
    ScaleProportionallyToFill = 2,
    Center = 3,
    Top = 4,
    TopRight = 5,
    Right = 6,
    BottomRight = 7,
    Bottom = 8,
    BottomLeft = 9,
    Left = 10,
    TopLeft = 11
}

enum NSTrackingAreaOptions : NSUInteger {
    MouseEnteredAndExited = 0x01,
    MouseMoved           = 0x02,
    CursorUpdate        = 0x04,
    ActiveWhenFirstResponder = 0x10,
    ActiveInKeyWindow   = 0x20,
    ActiveInActiveApp   = 0x40,
    ActiveAlways        = 0x80,
    AssumeInside        = 0x100
}

class NSTrackingArea {
    mixin ObjcExtend!NSObject;

    @selector("alloc")
    static NSTrackingArea alloc();

    @selector("initWithRect:options:owner:userInfo:")
    NSTrackingArea initWithRect(CGRect rect, NSTrackingAreaOptions options, NSView owner, NSDictionary userInfo);
}

class NSView {
    mixin ObjcExtend!NSObject;

nothrow @nogc:
    @selector("initWithFrame:")
    NSView initWithFrame(CGRect frameRect);

    @selector("addSubview:")
    void addSubview(NSView view);

    @selector("setWantsLayer:")
    void setWantsLayer(BOOL flag);

    @selector("setLayerContentsRedrawPolicy:")
    void setLayerContentsRedrawPolicy(NSViewLayerContentsRedrawPolicy policy);

    @selector("frame")
    CGRect frame();
    
    @selector("setFrame:")
    void setFrame(CGRect frame);

    @selector("bounds")
    CGRect bounds();

    @selector("setBounds:")
    void setBounds(CGRect bounds);

    @selector("window")
    NSWindow window();

    @selector("setContentView:")
    void setContentView(NSView view);

    @selector("addTrackingArea:")
    void addTrackingArea(NSTrackingArea area);
}

