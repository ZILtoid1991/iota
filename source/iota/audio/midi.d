module iota.audio.midi;

import iota.audio.types;

version (Windows) {
	import core.sys.windows.windows;
	import core.sys.windows.wtypes;
}

package string[] inDevs;
package string[] outDevs;
/** 
 * Initializes MIDI subsystem.
 * Returns: Zero on success, or a specific error code.
 */
public int initMIDI() {
	version (Windows) {
		uint nOutDevices = midiOutGetNumDevs();
		uint nInDevices = midiInGetNumDevs();
		
		return 0;
	} else return MIDIInitializationStatus.OSNotSupported;
}