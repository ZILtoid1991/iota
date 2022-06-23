module iota.window.exception;

public import iota.etc.exception;
import std.conv : to;

class WindowCreationException : IotaException {
    size_t  errorCode;
    this(string msg, size_t errorCode, string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null) 
            pure nothrow @nogc @safe {
        this.errorCode = errorCode;
        super(msg, file, line, nextInChain);
    }
    override string toString() {
        return super.toString() ~ "\n Error code: " ~ errorCode.to!string;
    }
}
class RendererCreationException : IotaException {
    size_t  errorCode;
    this(string msg, size_t errorCode, string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null) 
            pure nothrow @nogc @safe {
        this.errorCode = errorCode;
        super(msg, file, line, nextInChain);
    }
    override string toString() {
        return super.toString() ~ "\n Error code: " ~ errorCode.to!string;
    }
}