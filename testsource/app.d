import std.stdio;
import std.conv : to;
import core.thread;
import iota.audio.device;
import iota.audio.output;

int main(string[] args) {
	writeln("Please select driver:");
	version (Windows) {
		writeln("1) Windows Audio Stream API");
	} else version (linux) {
		writeln("1) ALSA");
	}
	string cmdIn = readln();
	int errCode = initDriver();
	if (errCode != AudioInitializationStatus.AllOk) {
		writeln("Driver failed to initialize! Error code: ", errCode);
		version (Windows) writeln("Windows error code: ", lastErrorCode);
		else version (linux) writeln("Linux error code: ", lastErrorCode);
		return 0;
	}
	string[] deviceList = getOutputDeviceNames();
	if (deviceList.length) {
		writeln("Please select device:");
		foreach (size_t i, string key; deviceList) {
			writeln(i, ") ", key);
		}
	} else {
		writeln("No devices were found");
		version (Windows) writeln("Windows error code: ", lastErrorCode);
		else version (linux) writeln("Linux error code: ", lastErrorCode);
	}
	cmdIn = readln();
	AudioDevice device;
	errCode = openDevice(cmdIn[0..$-1].to!int(), device);
	version (Windows) {
		if (errCode != AudioInitializationStatus.AllOk) {
			writeln("Device failed to initialize! Error code: ", errCode, " ; Windows error code: ", lastErrorCode);
			return 0;
		}
		WASAPIDevice wdevice = cast(WASAPIDevice)device;
		int samplerate = device.getRecommendedSampleRate();
		if (samplerate <= 0) {
			writeln("Failed to request default sampling rate! Windows error code: ", wdevice.werrCode);
			return 0;
		}
		writeln("Recommended sampling rate: ", samplerate);
		AudioSpecs givenSpecs = device.requestSpecs(
			AudioSpecs(predefinedFormats[PredefinedFormats.FP32], samplerate, 0x00, 0x02, 512, Duration.init)
		);
		writeln("Received specs: ", givenSpecs.toString);
		
		if (device.errCode != AudioInitializationStatus.AllOk) {
			writeln("Failed to request audio specifications! Error code: ", errCode, " ; Windows error code: ", wdevice.werrCode);
			return 0;
		}
		RenderingThread renderer = new RenderingThread();
		OutputStream outStream = device.createOutputStream();
		if (outStream is null) {
			writeln("Stream failed to initialize! Error code: ", device.errCode, " ; Windows error code: ", wdevice.werrCode);
			return 0;
		}
		WASAPIOutputStream woutStream = cast(WASAPIOutputStream)outStream;
		if ((givenSpecs.format.flags & SampleFormat.Flag.Type_Test) == SampleFormat.Flag.Type_Float) {
			outStream.callback_buffer = &renderer.renderingCallbackFP;
		} else if (givenSpecs.format.bits == 16) {
			outStream.callback_buffer = &renderer.renderingCallback16;
		} else if (givenSpecs.format.bits == 32)
			outStream.callback_buffer = &renderer.renderingCallback32;
		errCode = outStream.runAudioThread();
		if (errCode != AudioInitializationStatus.AllOk) {
			writeln("Audio stream failed to start! Error code: ", errCode, " ; Windows error code: ", woutStream.werrCode);
			return 0;
		}
		Thread.sleep(dur!"seconds"(10));
		const int errCode2 = outStream.errCode;
		synchronized {
			errCode = outStream.suspendAudioThread();
		}
		if (errCode != AudioInitializationStatus.AllOk && errCode2 != StreamRuntimeStatus.AllOk) {
			writeln("Audio stream failed to shut down! Error code: ", errCode, " ; Windows error code: ", woutStream.werrCode,
					"Stream error code: ", errCode2);
			return 0;
		}
		writeln("Callback time:", renderer.callbackTime);
	} else version (linux) {
		if (errCode != AudioInitializationStatus.AllOk) {
			writeln("Device failed to initialize! Error code: ", errCode, " ; Linux error message: ", 
					getErrorString(lastErrorCode));
			return 0;
		}
		AudioSpecs givenSpecs = device.requestSpecs(AudioSpecs(predefinedFormats[PredefinedFormats.FP32], 44_100, 0x00, 0x02, 
				1024, Duration.init));
		writeln("Received specs: ", givenSpecs.toString);
		ALSADevice ldevice = cast(ALSADevice)device;
		if (ldevice.alsaerrCode) {
			writeln("Failed to request audio specifications! Error code: ", errCode, " ; ALSA error message: ", 
					getErrorString(ldevice.alsaerrCode));
			return 0;
		}
		RenderingThread renderer = new RenderingThread();
		OutputStream outStream = device.createOutputStream();
		if (outStream is null) {
			writeln("Stream failed to initialize! Error code: ", device.errCode, " ; ALSA error message: ", 
					getErrorString(ldevice.alsaerrCode));
			return 0;
		}
		ALSAOutStream aoutstream = cast(ALSAOutStream)outStream;
		if (givenSpecs.format.bits == 16)
			outStream.callback_buffer = &renderer.renderingCallback16;
		else if (givenSpecs.format.bits == 32)
			outStream.callback_buffer = &renderer.renderingCallback32;
		errCode = outStream.runAudioThread();
		if (errCode != AudioInitializationStatus.AllOk) {
			writeln("Audio stream failed to start! Error code: ", errCode, " ; ALSA error message: ", 
					getErrorString(aoutstream.alsaerrCode));
			return 0;
		}
		Thread.sleep(dur!"seconds"(10));
		const int errCode2 = outStream.errCode;
		synchronized {
			errCode = outStream.suspendAudioThread();
		}
		if (errCode != AudioInitializationStatus.AllOk && errCode2 != StreamRuntimeStatus.AllOk) {
			writeln("Audio stream failed to shut down! Error code: ", errCode, " ; ALSA error message: ", 
					getErrorString(aoutstream.alsaerrCode), "Stream error code: ", errCode2);
			return 0;
		}
		writeln("Callback time:", renderer.callbackTime, " Last buffer size:", renderer.lastBufferSize);
	}
	return 0;
}

public class RenderingThread {
	protected int phasePos;
	protected const int phaseLenght = 480, cycleLenght = 960;
	public int callbackTime;
	public size_t lastBufferSize;
	this() {

	}
	void renderingCallback16(ubyte[] buffer) @nogc nothrow {
		lastBufferSize = buffer.length;
		callbackTime++;
		short[] buffer2 = cast(short[])(cast(void[])buffer);
		for (int i ; i < buffer2.length ; i+=2) {
			const short output = phasePos < phaseLenght ? short.max : short.min;
			phasePos++;
			buffer2[i] = output;
			buffer2[i + 1] = output;
			phasePos = phasePos >= cycleLenght ? 0 : phasePos;
		}
	}
	void renderingCallback32(ubyte[] buffer) @nogc nothrow {
		callbackTime++;
		int[] buffer2 = cast(int[])(cast(void[])buffer);
		for (int i ; i < buffer2.length ; i+=2) {
			const int output = phasePos < phaseLenght ? int.max : int.min;
			phasePos++;
			buffer2[i] = output;
			buffer2[i + 1] = output;
			phasePos = phasePos >= cycleLenght ? 0 : phasePos;
		}
	}
	void renderingCallbackFP(ubyte[] buffer) @nogc nothrow {
		callbackTime++;
		float[] buffer2 = cast(float[])(cast(void[])buffer);
		for (int i ; i < buffer2.length ; i+=2) {
			const float output = phasePos < phaseLenght ? 1.0 : -1.0;
			phasePos++;
			buffer2[i] = output;
			buffer2[i + 1] = output;
			phasePos = phasePos >= cycleLenght ? 0 : phasePos;
		}
	}
}