module iota.audio.output;

import iota.audio.types;
import core.thread;

/** 
 * Defines an output stream for audio output.
 * Periodically calls a callback function (delegate) as long as the stream isn't shut down.
 */
public abstract class OutputStream {
	/** 
	 * The ID of the audio thread if there's any.
	 */
	protected ThreadID _threadID;
	/// The last error code that was encountered, or 0 if none.
	public int			errCode;
	/// Internal state flags.
	protected uint		statusCode;
	public enum StatusFlags {
		IsRunning			=	1<<0,	///Set if thread is running.
		BufferOverrun		=	1<<8,	///Set if a buffer overrun event have happened.
		BufferUnderrun		=	1<<9,	///Set if a buffer underrun event have happened.
	}
	/** 
	 * Returns the thread ID of the stream thread.
	 * Warning: It is not advised to join this thread.
	 */
	public @property ThreadID threadID() @nogc @trusted pure nothrow const {
		version (OSX) {
			return cast(ThreadID)(_threadID);
		} else {
			return _threadID;
		}
	}
	/** 
	 * Called periodically request more data to device output.
	 * Target must not call any functions that either suspend the thread, or would impact real-time performance (disk
	 * operations, etc).
	 */ 
	public @system @nogc nothrow void delegate(ubyte[] buffer) callback_buffer;
	/** 
	 * Called when a buffer underflow error have occured. (Optional)
	 */
	public @system @nogc nothrow void delegate() callback_onBufferUnderflow;
	/** 
	 * Runs the audio thread. This either means that it'll create a new low-level thread to feed the stream a steady 
	 * amount of data, or use whatever the backend on the OS has.
	 * Returns: 0, or an error code if there was a failure.
	 */
	public abstract int runAudioThread() @trusted @nogc nothrow;
	/**
	 * Suspends the audio thread by allowing it to escape normally and close things safely, or suspending it on the
	 * backend.
	 * Returns: 0, or an error code if there was a failure.
	 * Note: It's wise to put this function into a mutex, or a `synchronized` block.
	 */
	public abstract int suspendAudioThread() @trusted @nogc nothrow;
}