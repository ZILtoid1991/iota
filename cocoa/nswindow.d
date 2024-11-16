module cocoa.nswindow;

import cocoa.foundation;
import cocoa.nsview;

import objc.runtime;
@ObjectiveC final extern(C++):
@nogc nothrow:

enum NSWindowStyleMask : NSUInteger {
    Borderless         = 0,
    Titled            = 1 << 0,
    Closable          = 1 << 1,
    Miniaturizable    = 1 << 2,
    Resizable         = 1 << 3,
    TexturedBackground = 1 << 8,
    UnifiedTitleAndToolbar = 1 << 12,
    FullScreen        = 1 << 14,
    FullSizeContentView = 1 << 15
}

enum NSBackingStoreType : NSUInteger {
    Retained = 0,
    Nonretained = 1,
    Buffered = 2
}

class NSWindow {
    mixin ObjcExtend!NSObject;

nothrow @nogc:
    @selector("initWithContentRect:styleMask:backing:defer:")
    NSWindow initWithContentRect(CGRect contentRect, 
                               NSWindowStyleMask style,
                               NSBackingStoreType backingStoreType,
                               BOOL flag);

    @selector("makeKeyAndOrderFront:")
    void makeKeyAndOrderFront(NSObject sender);

    @selector("setTitle:")
    void setTitle(NSString title);

    @selector("center")
    void center();

    @selector("contentView")
    NSView contentView();

    @selector("setContentView:")
    void setContentView(NSView view);

    @selector("frame")
    CGRect frame();

    @selector("setFrame:display:")
    void setFrame(CGRect frame, BOOL display);

    @selector("setStyleMask:")
    void setStyleMask(NSWindowStyleMask styleMask);

    @selector("toggleFullScreen:")
    void toggleFullScreen(NSObject sender);

    @selector("setReleasedWhenClosed:")
    void setReleasedWhenClosed(BOOL);
}

