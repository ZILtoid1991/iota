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
	protected Thread		autoReader;
	protected ubyte[]		buffer;
	protected snd_rawmidi_t* rmidi;
	protected snd_rawmidi_params_t* params;
	protected bool			isRunning;
	protected string		nameID;
	public ssize_t			errCode;
	/** 
	 * Returns the content of the buffer and clears it.
	 */
	public override ubyte[] read() nothrow {
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
		errCode = snd_rawmidi_open(rmidi, null, nameID.ptr, mode);
		if (errCode) return MIDIInitializationStatus.UnknownError;
		else return 0;
	}
	/** 
	 * Stops the MIDI input stream.
	 * Returns: Zero on success, or a specific error code.
	 */
	public override int stop() nothrow {
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