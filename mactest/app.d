module mactest;

version(OSX):

import objc.meta;
import objc.runtime;
import cocoa;
import metal;

const float[] vertexData = [
    0.0, 1.0, 0.0,
    -1.0, -1.0, 0.0,
    1.0, -1.0, 0.0
];

enum metalVertexShader = q{
    vertex float4 basic_vertex(
        const device packed_float3* vertex_array [[buffer(0)]],
        unsigned int vid [[vertex_id]]
    )
    {
        return float4(vertex_array[vid], 1.0);
    }
};

enum metalFragmentShader = q{
    fragment half4 basic_fragment()
    {
        return half4(1.0);
    }
};

__gshared MTLBuffer vertexBuffer;
__gshared MTLRenderPipelineDescriptor pipelineDescriptor;
__gshared MTLCommandQueue commandQueue;
__gshared MTLRenderPipelineState state;

enum DefaultPixelFormat = MTLPixelFormat.BGRA8Unorm_sRGB;

extern(C) void initMetal(MTLDevice device) {
    vertexBuffer = device.newBuffer(vertexData.ptr, float.sizeof*vertexData.length, MTLResourceOptions.DefaultCache);

    NSError err;
    auto defaultLibrary = device.newLibraryWithSource((metalVertexShader ~ metalFragmentShader).ns, null, &err);
    if(err !is null || defaultLibrary is null) {
        NSLog("Error compiling shader %@".ns, err);
        return;
    }

    auto fragmentProgram = defaultLibrary.newFunctionWithName("basic_fragment".ns);
    auto vertexProgram = defaultLibrary.newFunctionWithName("basic_vertex".ns);

    auto descriptor = MTLVertexDescriptor.vertexDescriptor;

    enum POSITION = 0;
    enum BufferIndexMeshPositions = 0;
    descriptor.attributes[POSITION].format = MTLVertexFormat.float3;
    descriptor.attributes[POSITION].offset = 0;
    descriptor.attributes[POSITION].bufferIndex = BufferIndexMeshPositions;

    descriptor.layouts[POSITION].stepRate = 1;
    descriptor.layouts[POSITION].stepFunction = MTLVertexStepFunction.PerVertex;
    descriptor.layouts[POSITION].stride = float.sizeof*3;

    pipelineDescriptor = MTLRenderPipelineDescriptor.alloc.initialize;
    pipelineDescriptor.label = "TestProgram".ns;
    pipelineDescriptor.vertexFunction = vertexProgram;
    pipelineDescriptor.fragmentFunction = fragmentProgram;
    pipelineDescriptor.vertexDescriptor = descriptor;
    pipelineDescriptor.colorAttachments[0].pixelFormat = DefaultPixelFormat;
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.Depth32Float_Stencil8;
    pipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.Depth32Float_Stencil8;

    state = device.newRenderPipelineStateWithDescriptor(pipelineDescriptor, &err);
    commandQueue = device.newCommandQueue();
}

extern(C) void renderMetal(MTKView view) {
    auto desc = view.currentRenderPassDescriptor;
    if(desc is null) return;

    auto cmdBuffer = commandQueue.commandBuffer();
    cmdBuffer.label = "MyCommand".ns;

    auto encoder = cmdBuffer.renderCommandEncoderWithDescriptor(desc);
    encoder.setRenderPipelineState(state);
    encoder.setVertexBuffer(vertexBuffer, 0, 0);
    encoder.drawPrimitives(MTLPrimitiveType.Triangle, 0, 3);
    encoder.endEncoding();
    
    cmdBuffer.presentDrawable(view.currentDrawable);
    cmdBuffer.commit();
}

@ObjectiveC final extern(C++)
class MetalViewDelegate {
    mixin ObjcExtend!NSObject;
    
    static MetalViewDelegate alloc() @selector("alloc") {
        return cast(MetalViewDelegate)NSObject.alloc;
    }
    
    extern(C) void drawInMTKView(MTKView view) @selector("drawInMTKView:") {
        renderMetal(view);
    }
}

int main(string[] args) {
    auto app = NSApp();
    app.setActivationPolicy(NSApplicationActivationPolicy.Regular);
    
    auto delegate_ = AppDelegate.alloc.initialize();
    app.setDelegate(delegate_);
    
    auto menubar = NSMenu.new_();
    auto appMenuItem = NSMenuItem.new_();
    menubar.addItem(appMenuItem);
    app.setMainMenu(menubar);
    
    auto appMenu = NSMenu.new_();
    auto quitMenuItem = NSMenuItem.alloc.initWithTitle(
        "Quit".ns,
        sel_registerName("terminate:"),
        "q".ns
    );
    quitMenuItem.setTarget(app);
    quitMenuItem.setAction(sel_registerName("terminate:"));
    appMenu.addItem(quitMenuItem);
    appMenuItem.setSubmenu(appMenu);

    auto device = MTLCreateSystemDefaultDevice();
    initMetal(device);
    
    auto rect = cocoa.foundation.CGRect(
        cocoa.foundation.CGPoint(100, 100),
        cocoa.foundation.CGSize(800, 600)
    );

    auto window = NSWindow.alloc.initWithContentRect(
        rect,
        NSWindowStyleMask.Titled | NSWindowStyleMask.Closable | NSWindowStyleMask.Resizable,
        NSBackingStoreType.Buffered,
        NO
    );

    auto metalView = cast(MTKView)(NSView.alloc.initWithFrame(rect));
    auto viewDelegate = cast(MetalViewDelegate)(NSObject.alloc.initialize());
    window.setContentView(cast(NSView)metalView);

    window.setTitle("Metal Triangle".ns);
    window.setReleasedWhenClosed(YES);
    window.makeKeyAndOrderFront(null);
    
    app.activateIgnoringOtherApps(YES);
    app.run();
    
    return 0;
}

