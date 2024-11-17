module cocoa.nscursor;

import objc.runtime;
import cocoa.foundation;

@ObjectiveC final extern(C++):
@nogc nothrow:

class NSCursor {
    mixin ObjcExtend!NSObject;

nothrow @nogc:
    @selector("arrowCursor")
    static NSCursor arrowCursor() nothrow @nogc;

    @selector("IBeamCursor")
    static NSCursor IBeamCursor() nothrow @nogc;

    @selector("IBeamCursorForVerticalLayout")
    static NSCursor IBeamCursorForVerticalLayout() nothrow @nogc;

    @selector("crosshairCursor")
    static NSCursor crosshairCursor() nothrow @nogc;

    @selector("closedHandCursor")
    static NSCursor closedHandCursor() nothrow @nogc;

    @selector("contextualMenuCursor")
    static NSCursor contextualMenuCursor() nothrow @nogc;

    @selector("disappearingItemCursor")
    static NSCursor disappearingItemCursor() nothrow @nogc;

    @selector("dragCopyCursor")
    static NSCursor dragCopyCursor() nothrow @nogc;

    @selector("dragLinkCursor")
    static NSCursor dragLinkCursor() nothrow @nogc;

    @selector("operationNotAllowedCursor")
    static NSCursor operationNotAllowedCursor() nothrow @nogc;

    @selector("pointingHandCursor")
    static NSCursor pointingHandCursor() nothrow @nogc;

    @selector("_windowResizeNorthWestSouthEastCursor")
    static NSCursor windowResizeNorthWestSouthEastCursor() nothrow @nogc;

    @selector("_windowResizeNorthEastSouthWestCursor")
    static NSCursor windowResizeNorthEastSouthWestCursor() nothrow @nogc;

    @selector("_windowResizeSouthWestCursor")
    static NSCursor windowResizeSouthWestCursor() nothrow @nogc;

    @selector("_windowResizeSouthEastCursor")
    static NSCursor windowResizeSouthEastCursor() nothrow @nogc;

    @selector("_windowResizeNorthWestCursor")
    static NSCursor windowResizeNorthWestCursor() nothrow @nogc;

    @selector("_windowResizeNorthEastCursor")
    static NSCursor windowResizeNorthEastCursor() nothrow @nogc;

    @selector("resizeDownCursor")
    static NSCursor resizeDownCursor() nothrow @nogc;

    @selector("resizeLeftCursor")
    static NSCursor resizeLeftCursor() nothrow @nogc;

    @selector("resizeLeftRightCursor")
    static NSCursor resizeLeftRightCursor() nothrow @nogc;

    @selector("resizeRightCursor")
    static NSCursor resizeRightCursor() nothrow @nogc;

    @selector("resizeUpCursor")
    static NSCursor resizeUpCursor() nothrow @nogc;

    @selector("resizeUpDownCursor")
    static NSCursor resizeUpDownCursor() nothrow @nogc;

    @selector("openHandCursor")
    static NSCursor openHandCursor() nothrow @nogc;

    @selector("zoomInCursor")
    static NSCursor zoomInCursor() nothrow @nogc;

    @selector("zoomOutCursor")
    static NSCursor zoomOutCursor() nothrow @nogc;

    @selector("set")
    void set() nothrow @nogc;
}

