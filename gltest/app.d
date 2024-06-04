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
	#version 110
	//layout(location = 0) in vec3 vertexPosition_modelspace;
	void main() {
		gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * gl_Vertex;
	}	
} ~ '\0';
string fragmentShader = q{
	#version 110
	//out vec4 color;
	void main(){
		gl_FragColor = vec4(1.0,1.0,1.0,1.0);
	}
} ~ '\0';

import bindbc.opengl;

int main(string[] args) {
	try {
		bool isRunning = true;
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
				glViewport(0, 0, event.window.width, event.window.height);
			} else if (event.type != InputEventType.init) {

				//writeln(event.toString());
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