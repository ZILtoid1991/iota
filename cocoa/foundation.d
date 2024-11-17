module cocoa.foundation;

import objc.runtime;

extern(C) bool CGEventSourceKeyState(int stateID, ushort keyCode) nothrow @nogc;

version(watchOS) {
    alias CGFloat = float;
} else {
    alias CGFloat = double;
}

struct CGPoint {
    CGFloat x;
    CGFloat y;
}

struct CGSize {
    CGFloat width;
    CGFloat height;
}

struct CGRect {
    CGPoint origin;
    CGSize size;
}

enum NSEventModifierFlags : NSUInteger {
    AlphaShiftKeyMask         = 1 << 16,
    ShiftKeyMask              = 1 << 17,
    ControlKeyMask            = 1 << 18,
    AlternateKeyMask          = 1 << 19,
    CommandKeyMask            = 1 << 20,
    NumericPadKeyMask         = 1 << 21,
    HelpKeyMask               = 1 << 22,
    FunctionKeyMask           = 1 << 23
}

