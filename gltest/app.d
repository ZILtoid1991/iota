module app;

import std.stdio;
import std.conv : to;
import std.math;
import core.thread;
import iota.controls;
import iota.controls.keybscancodes;
import iota.window;
	import iota.controls.polling : poll;

version (Windows) {
	import core.sys.windows.windows;
}

//import darg;

string vertexShader = q{
	#version 120
	//layout(location = 0) in vec3 vertexPosition_modelspace;
	void main() {
		gl_TexCoord[0] = ftransform();
		gl_Position = ftransform();
	}	
} ~ '\0';
string fragmentShader = q{
	#version 120
	//out vec4 color;
	void main(){
		gl_FragColor = vec4((gl_TexCoord[0].t + 1.0) * 0.5,(gl_TexCoord[0].s + 1.0) * 0.5 * (gl_TexCoord[0].t * -2.0),
				(gl_TexCoord[0].s - 1.0) * -0.5 * (gl_TexCoord[0].t * -2.0),1.0);
	}
} ~ '\0';

import bindbc.opengl;

int main(string[] args) {
	try {
		bool attribsArb;
		bool isRunning = true;
		foreach (string arg ; args) {
			if (arg == "--attribsArb") attribsArb = true;
		}
		bool isFullscreen;
		GLfloat[9] testVertex = [
			-0.5, -0.5, 0.0,
			0.5, -0.5, 0.0,
			0.0, 0.5, 0.0,
		];
		

		OSWindow glOutput = 
			new OSWindow("Iota OpenGL test", "glSurface", -1, -1, 1280, 960, WindowCfgFlags.IgnoreMenuKey);
		int errCode = initInput(ConfigFlags.gc_Enable | ConfigFlags.gc_TriggerMode, OSConfigFlags.win_XInput);
		// const glRC = glOutput.getOpenGLHandle();
		if (attribsArb) {
			glOutput.getOpenGLHandleAttribsARB([
				OpenGLContextAtrb.MajorVersion, 3,
				OpenGLContextAtrb.MinorVersion, 3,
				OpenGLContextAtrb.Flags, OpenGLContextFlags.Debug | OpenGLContextFlags.ForwardCompatible,
				0]);
		} else {
			glOutput.getOpenGLHandle();
		}
		const glStatus = loadOpenGL();
		if (glStatus < GLSupport.gl11) {
			writeln("OpenGL not found!");
			return 1;
		}
		

		GLuint vertexbuffer;
		glGenBuffers(1, &vertexbuffer);
		glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
		glBufferData(GL_ARRAY_BUFFER, testVertex.length * float.sizeof, &testVertex, GL_STATIC_DRAW);

		int infoLogLength;
		
		GLuint vertexShaderID = glCreateShader(GL_VERTEX_SHADER);
		immutable(char)* vertexShaderSrc = vertexShader.ptr;
		glShaderSource(vertexShaderID, 1, &vertexShaderSrc, null);
		glCompileShader(vertexShaderID);
		//glGetShaderiv(vertexShaderID, GL_COMPILE_STATUS, &shaderResult);
		glGetShaderiv(vertexShaderID, GL_INFO_LOG_LENGTH, &infoLogLength);
		if (infoLogLength > 0) {
			char[] msg;
			msg.length = infoLogLength + 1;
			glGetShaderInfoLog(vertexShaderID, infoLogLength, null, msg.ptr);
			writeln(msg);
		}

		GLuint fragmentShaderID = glCreateShader(GL_FRAGMENT_SHADER);
		immutable(char)* fragmentShaderSrc = fragmentShader.ptr;
		glShaderSource(fragmentShaderID, 1, &fragmentShaderSrc, null);
		glCompileShader(fragmentShaderID);
		glGetShaderiv(fragmentShaderID, GL_INFO_LOG_LENGTH, &infoLogLength);
		if (infoLogLength > 0) {
			char[] msg;
			msg.length = infoLogLength + 1;
			glGetShaderInfoLog(fragmentShaderID, infoLogLength, null, msg.ptr);
			writeln(msg);
		}

		GLuint glProgramID = glCreateProgram();
		glAttachShader(glProgramID, vertexShaderID);
		glAttachShader(glProgramID, fragmentShaderID);
		glLinkProgram(glProgramID);
		glGetProgramiv(glProgramID, GL_INFO_LOG_LENGTH, &infoLogLength);
		if (infoLogLength > 0) {
			char[] msg;
			msg.length = infoLogLength + 1;
			glGetProgramInfoLog(glProgramID, infoLogLength, null, msg.ptr);
			writeln(msg);
		}
		glDetachShader(glProgramID, vertexShaderID);
		glDetachShader(glProgramID, fragmentShaderID);

		glDeleteShader(vertexShaderID);
		glDeleteShader(fragmentShaderID);

		while (isRunning) {
			for (int vertexNum ; vertexNum < 9 ; vertexNum+=3) {
				float x = testVertex[vertexNum], y = testVertex[vertexNum + 1];
				testVertex[vertexNum] = (cos(PI / 180) * x) + (sin(PI / 180) * y);
				testVertex[vertexNum + 1] = (-1 * sin(PI / 180) * x) + (cos(PI / 180) * y);
			}
			//Rendering part begin
			glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);

			glUseProgram(glProgramID);

			glEnableVertexAttribArray(0);
			glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
			glBufferData(GL_ARRAY_BUFFER, testVertex.length * float.sizeof, &testVertex, GL_STATIC_DRAW);
			glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, null);
			glDrawArrays(GL_TRIANGLES, 0, 3);
			glDisableVertexAttribArray(0);

			glFinish();

			glOutput.gl_swapBuffers();
			//Rendering part end
			//Input event polling part begin
			InputEvent event;
			poll(event);
			if (event.type == InputEventType.ApplExit || event.type == InputEventType.WindowClose) {
				isRunning = false;
			} else if (event.type == InputEventType.WindowResize) {
				//glOutput.gl_makeCurrent();
				glViewport(0, 0, event.window.width, event.window.height);
			} else if (event.type == InputEventType.Keyboard && event.button.dir == 1) {
				switch (event.button.id) {
				case ScanCode.F11:
					int result;
					if (isFullscreen) result = glOutput.setScreenMode(0, DisplayMode.Windowed);
					else result = glOutput.setScreenMode(0, DisplayMode.FullscreenDesktop);
					isFullscreen = !isFullscreen;
					writeln(result);
					break;
				case ScanCode.ESCAPE:
				    isRunning = false;
                    break;
				default:
					break;
				}
				
			}
			Thread.sleep(dur!"msecs"(10));
			//Input event polling part end
		}
		destroy(glOutput);
		return 0;
	} catch (Throwable t) {
		writeln(t);
		return 1;
	}
}
