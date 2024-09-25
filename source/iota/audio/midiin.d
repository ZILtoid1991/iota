module iota.audio.midiin;

public abstract class MIDIInput {
	///The last status code returned by a function
	public int lastStatusCode;
	///If set, input data will be passed through this delegate
	public @system @nogc nothrow void delegate(ubyte[] data, size_t timestamp) midiInCallback;
	/** 
	 * Returns the content of the buffer and clears it.
	 */
	public abstract ubyte[] read() @safe nothrow;
	/** 
	 * Starts the MIDI input stream.
	 * Returns: Zero on success, or a specific error code.
	 */
	public abstract int start() @trusted nothrow;
	/** 
	 * Stops the MIDI input stream.
	 * Returns: Zero on success, or a specific error code.
	 */
	public abstract int stop() @trusted nothrow;
}