module iota.audio.midiwin;

version (Windows):

import iota.audio.midiin;
import iota.audio.midiout;
import core.sys.windows.windows;
import core.sys.windows.wtypes;
package import iota.audio.backend.windows;
public import iota.audio.types;

public class WindowsMIDIInput : MIDIInput {
	/** 
	 * Function for handling callbacks from OS side.
	 */
	package static extern(Windows) void midiHandler(HMIDIIN midi, UINT msg, DWORD_PTR instance, DWORD_PTR param1, 
			DWORD_PTR param2) @nogc nothrow {
		if (msg != MIM_OPEN && msg != MIM_CLOSE)
			(cast(WindowsMIDIInput)(cast(void*)instance)).handleEvent(msg, param1, param2);
	}
	///Contains all currently received MIDI messages.
	///If full, further MIDI messages will be dropped.
	protected ubyte[] buffer;
	protected size_t bufferpos;
	protected HMIDIIN handle;
	///The last error code produced by the OS
	public MMRESULT lastErrorCode;
	package this(UINT deviceID, size_t bufferSize) nothrow {
		lastErrorCode = midiInOpen(&handle, deviceID, cast(size_t)(cast(void*)&midiHandler), cast(size_t)(cast(void*)this), 
				CALLBACK_FUNCTION);
		buffer.length = bufferSize;
	}
	~this() {
		if (handle)
			midiInClose(handle);
	}
	package void handleEvent(UINT msg, DWORD_PTR param1, DWORD_PTR param2) @nogc nothrow {
		if (midiInCallback is null) {
			switch (msg) {
				case MIM_ERROR:
					size_t data = param1;
					int i = 4;
					while ((i) && bufferpos < buffer.length) {
						buffer[bufferpos] = cast(ubyte)data;
						data>>=8;
						bufferpos++;
						i--;
					}
					break;
				case MIM_DATA:
					size_t data = param1;
					int i = 3;
					if ((data & 0xf0) == 0xc0 || (data & 0xf0) == 0xD0) i = 2;
					if ((data & 0xf0) == 0xf0 && (data & 0x0f) > 0x05) i = 1;
					while ((i) && bufferpos < buffer.length) {
						buffer[bufferpos] = cast(ubyte)data;
						data>>=8;
						bufferpos++;
						i--;
					}
					break;
				case MIM_LONGDATA, MIM_LONGERROR:
					LPMIDIHDR data = cast(LPMIDIHDR)(cast(void*)param1);
					const int t = data.dwBytesRecorded;
					int i;
					while ((i < t) && bufferpos < buffer.length) {
						buffer[bufferpos] = cast(ubyte)(data.lpData[i]);
						bufferpos++;
						i++;
					}
					break;
				default:
					break;
			}
		} else {
			switch (msg) {
				case MIM_LONGDATA, MIM_LONGERROR:
					LPMIDIHDR data = cast(LPMIDIHDR)(cast(void*)param1);
					midiInCallback((cast(ubyte*)data.lpData)[0..data.dwBytesRecorded], param2);
					break;
				default:
					break;
			}
		}
		
	}
	override public ubyte[] read() pure nothrow {
		const size_t pos = bufferpos;
		bufferpos = 0;
		return buffer[0..pos];
	}
	/** 
     * Starts the MIDI input stream.
     * Returns: Zero on success, or a specific error code.
     */
    override public int start() nothrow {
		lastErrorCode = midiInStart(handle);
		if (lastErrorCode == MMSYSERR_INVALHANDLE)	return lastStatusCode = MIDIDeviceStatus.DeviceDisconnected;
		else return lastStatusCode = MIDIDeviceStatus.AllOk;
	}
    /** 
     * Stops the MIDI input stream.
     * Returns: Zero on success, or a specific error code.
     */
    override public int stop() nothrow {
		lastErrorCode = midiInStop(handle);
		if (lastErrorCode == MMSYSERR_INVALHANDLE)	return lastStatusCode = MIDIDeviceStatus.DeviceDisconnected;
		else return lastStatusCode = MIDIDeviceStatus.AllOk;
	}
}
public class WindowsMIDIOutput : MIDIOutput {
	protected HMIDIOUT handle;
	///The last error code produced by the OS
	public MMRESULT lastErrorCode;
	package this(UINT deviceID) @nogc nothrow {
		lastErrorCode = midiOutOpen(&handle, deviceID, 0, 0, CALLBACK_NULL);
	}
	~this() {
		midiOutClose(handle);
	}
	override public void write(ubyte[] buffer) {
		if (buffer.length <= 3) {
			DWORD msg;
			for (int i ; i < buffer.length ; i++) {
				msg |= buffer[i]<<(i*8);
			}
			lastErrorCode = midiOutShortMsg(handle, msg);
		} else {
			MIDIHDR msg;
			msg.lpData = cast(char*)buffer.ptr;
			msg.dwBufferLength = cast(DWORD)buffer.length;
			msg.dwBytesRecorded = cast(DWORD)buffer.length;
			msg.dwFlags = MHDR_DONE;
			lastErrorCode = midiOutPrepareHeader(handle, &msg, cast(UINT)MIDIHDR.sizeof);
			lastErrorCode = midiOutLongMsg(handle, &msg, cast(UINT)MIDIHDR.sizeof);
			lastErrorCode = midiOutUnprepareHeader(handle, &msg, cast(UINT)MIDIHDR.sizeof);
		}
	}
	/** 
     * Starts the MIDI output stream.
     * Returns: Zero on success, or a specific error code.
     */
    override public int start() nothrow {
		return lastStatusCode = MIDIDeviceStatus.AllOk;
	}
    /** 
     * Stops the MIDI output stream.
     * Returns: Zero on success, or a specific error code.
     */
    override public int stop() nothrow {
		return lastStatusCode = MIDIDeviceStatus.AllOk;
	}
}