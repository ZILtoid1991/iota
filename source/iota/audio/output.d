module iota.audio.output;

import iota.audio.types;
import core.thread;

/** 
 * Defines an output stream for audio output.
 * Periodically calls a callback function (delegate) as long as the stream isn't shut down.
 */
public abstract class OutputStream {
	/** 
	 * Called periodically request more data to device output.
	 * Target must not call any functions that either suspend the thread, or would impact real-time performance (disk
	 * operations, etc).
	 */
	public @nogc nothrow void delegate(void[] buffer) callback_buffer;
	/** 
	 * Called when a buffer underflow error have occured. (Optional)
	 */
	public @nogc nothrow void delegate() callback_onBufferUnderflow;
	/** 
	 * Creates a low-level thread for handling periodic audio callbacks.
	 * Returns: The ID of the real-time thread, or ThreadID.init in case of an error.
	 * NOTE: Do not join, or externally shut down this thead! Use function `suspendAudioThread` to stop the audio 
	 * stream.
	 */
	public abstract ThreadID runAudioThread() @nogc nothrow;
	/**
	 * Suspends the thread by allowing it to escape normally and close things safely.
	 * Returns: Zero if there was no error during the stream, or specific error codes/flags.
	 */
	public abstract int suspendAudioThread() @nogc nothrow;
}