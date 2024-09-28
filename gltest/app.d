module app;

import std.stdio;
import std.conv : to;
import core.thread;
import iota.controls;
import iota.controls.keybscancodes;
import iota.window;

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
		bool isRunning = true;
		bool isFullscreen;
		GLfloat[9] testVertex = [
			-1.0, -1.0, 0.0,
			1.0, -1.0, 0.0,
			0.0, 1.0, 0.0,
		];
		

		OSWindow glOutput = 
			new OSWindow("Iota OpenGL test", "glSurface", -1, -1, 1280, 960, WindowCfgFlags.IgnoreMenuKey);
		int errCode = initInput(ConfigFlags.gc_Enable | ConfigFlags.gc_TriggerMode, OSConfigFlags.win_XInput);
		const glRC = glOutput.getOpenGLHandle();
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
			//Rendering part begin
			glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);

			glUseProgram(glProgramID);

			glEnableVertexAttribArray(0);
			glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
			glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, null);
			glDrawArrays(GL_TRIANGLES, 0, 3);
			glDisableVertexAttribArray(0);

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
				default:
					break;
				}
				
			}
			Thread.sleep(dur!"msecs"(10));
			//Input event polling part end
		}
		return 0;
	} catch (Throwable t) {
		writeln(t);
		return 1;
	}
}