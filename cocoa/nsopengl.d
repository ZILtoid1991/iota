module cocoa.nsopengl;

import objc.runtime;
import cocoa.foundation;
import cocoa.nsview;
import bindbc.opengl;

@ObjectiveC final extern(C++):
@nogc nothrow:

enum : int {
    NSOpenGLPFADoubleBuffer = 5,
    NSOpenGLPFAColorSize = 8,
    NSOpenGLPFAAlphaSize = 11,
    NSOpenGLPFADepthSize = 12,
    NSOpenGLPFAStencilSize = 13
}

enum NSOpenGLContextParameter {
    NSOpenGLCPSwapInterval = 222,
    NSOpenGLCPSurfaceOrder = 235,
    NSOpenGLCPSurfaceOpacity = 236,
    NSOpenGLCPSurfaceBackingSize = 304,
    NSOpenGLCPReclaimResources = 308,
    NSOpenGLCPCurrentRendererID = 309,
    NSOpenGLCPGPUVertexProcessing = 310,
    NSOpenGLCPGPUFragmentProcessing = 311,
    NSOpenGLCPHasDrawable = 314,
    NSOpenGLCPMPSwapsInFlight = 315,
}

class NSOpenGLPixelFormat {
    mixin ObjcExtend!NSObject;

nothrow @nogc:
    @selector("alloc")
    static NSOpenGLPixelFormat alloc();

    @selector("initWithAttributes:")
    NSOpenGLPixelFormat initWithAttributes(const(int)*);
}

class NSOpenGLContext {
    mixin ObjcExtend!NSObject;

nothrow @nogc:
    @selector("alloc")
    static NSOpenGLContext alloc();

    @selector("initWithFormat:shareContext:")
    NSOpenGLContext initWithFormat(NSOpenGLPixelFormat format, NSOpenGLContext shareContext);

    @selector("setView:")
    void setView(NSView view);

    @selector("flushBuffer")
    void flushBuffer();

    @selector("makeCurrentContext")
    void makeCurrentContext();

    @selector("setValues:forParameter:")
    void setValues(const(int)* vals, NSOpenGLContextParameter param);
    
    @selector("update")
    void update();
}

