module iota.etc.exception;

/** 
 * While most parts of this library instead uses error codes to avoid using exceptions, sometimes their use is 
 * inevitable. Every exception in this library inherits from this for easier tracking between multiple modules.
 */
public class IotaException : Exception {
	this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null) pure nothrow @nogc @safe {
		super(msg, file, line, nextInChain);
	}
}
