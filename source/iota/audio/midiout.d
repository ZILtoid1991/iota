module iota.audio.midiout;

public abstract class MIDIOutput {
	///The last status code returned by a function
    public int lastStatusCode;
	/** 
	 * Sends data to the output
	 * Params:
	 *   buffer = Data that will be written to the output.
	 */
	public abstract void write(ubyte[] buffer) @nogc nothrow;
	/** 
     * Starts the MIDI output stream.
     * Returns: Zero on success, or a specific error code.
     */
    public abstract int start() nothrow;
    /** 
     * Stops the MIDI output stream.
     * Returns: Zero on success, or a specific error code.
     */
    public abstract int stop() nothrow;
}