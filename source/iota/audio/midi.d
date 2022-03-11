module iota.audio.midi;

public import iota.audio.types;
public import iota.audio.midiin;
public import iota.audio.midiout;

version (Windows) {
	package import iota.audio.midiwin;
	import core.sys.windows.windows;
	import core.sys.windows.wtypes;
	/** 
	 * Te last error code that occured on the OS side.
	 */
	MMRESULT lastErrorCode;
}

/** 
 * The last error code that occured on middleware side.
 */
public int lastStatusCode;
package string[] inDevs;
package string[] outDevs;
/** 
 * Initializes MIDI subsystem.
 * Returns: Zero on success, or a specific error code.
 */
public int initMIDI() {
	version (Windows) {
		import std.string : fromStringz;
		import std.utf : toUTF8;

		uint nOutDevices = midiOutGetNumDevs();
		uint nInDevices = midiInGetNumDevs();
		if (!(nInDevices | nOutDevices)) return lastStatusCode = MIDIInitializationStatus.DevicesNotFound;
		inDevs.length = nInDevices;
		for (int i ; i < inDevs.length ; i++) {
			MIDIINCAPS caps;
			size_t u = i;
			lastErrorCode = midiInGetDevCaps(u, &caps, cast(UINT)MIDIINCAPS.sizeof);
			if (lastErrorCode == MMSYSERR_NOERROR)
				inDevs[i] = toUTF8(fromStringz(caps.szPname.ptr).idup);
			else 
				return lastStatusCode = MIDIInitializationStatus.InitError;
		}
		outDevs.length = nOutDevices;
		for (int i ; i < outDevs.length ; i++) {
			MIDIOUTCAPS caps;
			size_t u = i;
			lastErrorCode = midiOutGetDevCaps(u, &caps, cast(UINT)MIDIOUTCAPS.sizeof);
			if (lastErrorCode == MMSYSERR_NOERROR)
				outDevs[i] = toUTF8(fromStringz(caps.szPname.ptr).idup);
			else 
				return lastStatusCode = MIDIInitializationStatus.InitError;
		}
		return 0;
	} else return lastStatusCode = MIDIInitializationStatus.OSNotSupported;
}
///Returns the name of all MIDI input devices.
public string[] getMIDIInputDevs() @safe nothrow {
	return inDevs.dup;
}
///Returns the name of all MIDI output devices.
public string[] getMIDIOutputDevs() @safe nothrow {
	return outDevs.dup;
}
/** 
 * Opens an input for a MIDI stream.
 * Params:
 *   input = Stream returned here.
 *   num = The ID of the device.
 *   bufSize = The input buffer size if applicable (1024 by default).
 * Returns: 0 if the operation is successful, or an error code.
 */
public int openMIDIInput(ref MIDIInput input, uint num, size_t bufSize = 1024) {
	version (Windows) {
		WindowsMIDIInput wmi = new WindowsMIDIInput(num, bufSize);
		switch (wmi.lastErrorCode) {
			case MMSYSERR_NOMEM:
				return MIDIDeviceInitStatus.OutOfMemory;
			case MMSYSERR_BADDEVICEID:
				return MIDIDeviceInitStatus.InvalidDeviceID;
			case MMSYSERR_NOERROR:
				input = wmi;
				return MIDIDeviceInitStatus.AllOk;
			default:
				return MIDIDeviceInitStatus.InitError;
		}
	} else return lastStatusCode = MIDIDeviceInitStatus.OSNotSupported;
}
/** 
 * Opens an output for a MIDI stream.
 * Params:
 *   output = Stream returned here.
 *   num = The ID of the device.
 * Returns: 
 */
public int openMIDIOutput(ref MIDIOutput output, uint num) {
	version (Windows) {
		WindowsMIDIOutput wmi = new WindowsMIDIOutput(num);
		switch (wmi.lastErrorCode) {
			case MMSYSERR_NOMEM:
				return MIDIDeviceInitStatus.OutOfMemory;
			case MMSYSERR_BADDEVICEID:
				return MIDIDeviceInitStatus.InvalidDeviceID;
			case MMSYSERR_NOERROR:
				output = wmi;
				return MIDIDeviceInitStatus.AllOk;
			default:
				return MIDIDeviceInitStatus.InitError;
		}
	} else return lastStatusCode = MIDIDeviceInitStatus.OSNotSupported;
}