module iota.window.fbdev;

version (Windows) {
	import core.sys.windows.windows;
	import core.sys.windows.wtypes;
	import core.sys.windows.wingdi;
	import std.utf : toUTF16z;
	import std.conv : to;
}

import iota.window.oswindow;

import bindbc.opengl;

/** 
 * Defines common traits and functions of a framebuffer Renderer object.
 */
public abstract class FrameBufferRenderer {
	protected OSWindow		renderingSurface;
	public enum ConfigParams {
		init,
		///Toggles VSync. 0 disables, any non-zero value enables it.
		VSync,
		///Changes scaling quality. Note that not all API or versions of them support all options.
		Scaling,
		///Texture width. Returns the next power of two if texture size needs to be rounded up.
		TexWidth,
		///Texture height. Returns the next power of two if texture size needs to be rounded up.
		TexHeight,
		///Width to be used. By default, this value equals with TexWidth.
		UseWidth,
		///Height to be used. By default, this value equals with TexHeight.
		UseHeight,
		///Horizontal offset of display area.
		Hoffset,
		///Vertical offset of display area.
		VOffset,
	}
	/** 
	 * Configures a value associated with the renderer.
	 * Params:
	 *   param = The parameter to be configured.
	 *   val = The value of the parameter.
	 * Returns: 0 on success, -1 on API error, -2 on out of bounds values, -3 on unsupported or bad parameter. Positive values 
	 * mean that the value had been rounded up to the next power of two.
	 */
	public abstract int config(ConfigParams param, int val) @system nothrow;
	/** 
	 * Renders the framebuffer from the supplied bitmap. If VSync is enabled, it'll also wait for the next framebuffer change.
	 * Params:
	 *   bitmap = 
	 * Returns: 0 on succes, a positive value on inconsistencies (e.g. framebuffer size changes), a negative value on errors.
	 */
	public abstract int render(WindowBitmap bitmap) @system nothrow;
	/** 
	 * Attaches a shader program to the frame buffer output.
	 * Params:
	 *   src = the source code of the shader.
	 * Returns: 0 on success, 1 on error.
	 */
	public abstract int attachShader(string[] src) @system nothrow;
}

public class OpenGLRenderer : FrameBufferRenderer {
	protected GLuint		textureID;
	//protected GLuint		frameBufferID;
	protected GLuint		vbo;
	protected GLenum		scaleQ;
	protected bool			vSync;
	protected GLfloat[] verticles = [
	//	Position	TexCoords
		-1.0, -1.0, 0.0, 0.0,	//Top-left
		1.0, -1.0,  1.0, 0.0,	//Top-right
		-1.0, 1.0,  1.0, 1.0,	//Bottom-right
		1.0, -1.0,  0.0, 1.0,	//Bottom-left
	];
	version (Windows) {
		protected HGLRC     renderingContext;
	}
	public static int initGL() {
		loadOpenGL();
		return 0;
	}
	shared static ~this() {
		unloadOpenGL();
	}
	public this(OSWindow window) {
		version (Windows) {
			//glEnable(0);
			renderingSurface = window;
			HDC hdc = GetDC(window.getHandle);
			renderingContext = wglCreateContext(hdc);
		}
		glGenTextures(1, &textureID);
		//glGenBuffers(1, &frameBufferID);
		glGenBuffers(1, &vbo);
		glBufferData(GL_ARRAY_BUFFER, verticles.length, verticles.ptr, GL_STATIC_DRAW);
	}
	~this() {
		wglDeleteContext(renderingContext);
		
	}
	override public int config(FrameBufferRenderer.ConfigParams param, int val) @system nothrow {
		switch (param) {
			default:
				case ConfigParams.VSync:
					vSync = (val != 0);
					return 0;
				case ConfigParams.Scaling:
					switch (val) {
						case 1:
							scaleQ = GL_NEAREST;
							break;
						case 2:
							scaleQ = GL_LINEAR;
							break;
						default:
							return -2;
					}
					glBindTexture(GL_TEXTURE_2D, textureID);
					glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, scaleQ);
					glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, scaleQ);
					return 0;
				return -3;
		}
		return int.init; // TODO: implement
	}

	override public int render(WindowBitmap bitmap) @system nothrow {
		glBindTexture(GL_TEXTURE_2D, textureID);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, bitmap.width, bitmap.height, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8, 
				bitmap.pixels.ptr);
		
		return int.init; // TODO: implement
	}

	override public int attachShader(string[] src) @system nothrow {
		
		return int.init; // TODO: implement
	}
}