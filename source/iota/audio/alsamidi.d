module iota.audio.alsamidi;

version (linux) :

package import iota.audio.backend.linux;
package import iota.audio.backend.linux2;
import iota.audio.types;
import iota.audio.midiin;
import iota.audio.midiout;

import core.thread;
import core.time;

public class ALSAMIDIInput : MIDIInput {
	protected Thread		autoReader;		///Automatic reader thread for delegate method
	protected ubyte[]		buffer;			
	protected snd_rawmidi_t* rmidi;			///Handle to the raw MIDI device
	//protected snd_rawmidi_params_t* params;
	protected bool			isRunning;		///Set to true if the reader is in operation
	protected string		nameID;			///Device name identifier with added null terminator
	public ssize_t			errCode;		///Last returned error code
	package this(string nameID, uint bufferSize = 4096) {
		this.nameID = nameID ~ "/00";
		buffer.length = bufferSize;
	}
	/** 
	 * Returns the content of the buffer and clears it.
	 */
	public override ubyte[] read() nothrow {
		errCode = snd_rawmidi_read(rmidi, null, 0);
		if (errCode >= 0) {
			errCode = snd_rawmidi_read(rmidi, buffer.ptr, buffer.length);
			if (errCode >= 0) {
				return buffer[0..errCode];
			}
		}
		return null;
	}
	/** 
	 * Starts the MIDI input stream.
	 * Returns: Zero on success, or a specific error code.
	 */
	public override int start() nothrow {
		int mode;
		if (midiInCallback is null) {
			mode = 0x0002;
		}
		errCode = snd_rawmidi_open(&rmidi, null, cast(const(char)*)nameID.ptr, mode);
		if (errCode) {
			return lastStatusCode = MIDIDeviceStatus.UnknownError;
		}
		isRunning = true;
		if (midiInCallback !is null) {
			autoReader = new Thread(&readerThread);
			autoReader.start();
		}
		return lastStatusCode = 0;
	}
	/** 
	 * Stops the MIDI input stream.
	 * Returns: Zero on success, or a specific error code.
	 */
	public override int stop() nothrow {
		errCode = snd_rawmidi_drain(rmidi);
		isRunning = false;
		errCode = snd_rawmidi_close(rmidi);
		if (errCode) return lastStatusCode = MIDIDeviceStatus.UnknownError;
		return 0;
	}
	protected void readerThread() {
		while (isRunning) {
			errCode = snd_rawmidi_read(rmidi, buffer.ptr, buffer.length);
			if (errCode >= 0) {
				midiInCallback(buffer[0..errCode], cast(uint)(MonoTime.currTime.ticks / 10_000_000));
			} else {
				isRunning = false;
			}
		}
	}
}

public class ALSAMIDIOutput : MIDIOutput {
	protected snd_rawmidi_t* rmidi;
	//protected snd_rawmidi_params_t* params;
	protected bool			isRunning;
	protected string		nameID;
	public ssize_t			errCode;
	/** 
	 * Sends data to the output
	 * Params:
	 *   buffer = Data that will be written to the output.
	 */
	public override void write(ubyte[] buffer) @nogc nothrow {
		errCode = snd_rawmidi_write(rmidi, buffer.ptr, buffer.length);
	}
	/** 
     * Starts the MIDI output stream.
     * Returns: Zero on success, or a specific error code.
     */
    public override int start() nothrow {
		errCode = snd_rawmidi_open(null, &rmidi, nameID.ptr, 0);
		if (!errCode) return 0;
		else return MIDIDeviceStatus.UnknownError;
	}
    /** 
     * Stops the MIDI output stream.
     * Returns: Zero on success, or a specific error code.
     */
    public override int stop() nothrow {
		errCode = snd_rawmidi_close(rmidi);
		if (!errCode) return 0;
		else return MIDIDeviceStatus.UnknownError;
	}
}