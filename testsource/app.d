import std.stdio;
import std.conv : to;
import core.thread;
import iota.audio.device;
import iota.audio.output;

int main(string[] args) {
	version (Windows) {
		writeln("Please select driver:");
		writeln("1) Windows Audio Stream API");
	}
	string cmdIn = readln();
	int errCode = initDriver(DriverType.WASAPI);
	if (errCode != AudioInitializationStatus.AllOk) {
		writeln("Driver failed to initialize! Error code: ", errCode);
		version (Windows) writeln("Windows error code: ", lastErrorCode);
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
	}
	cmdIn = readln();
	AudioDevice device;
	errCode = openDevice(cmdIn[0..$-1].to!int(), device);
	version (Windows) {
		if (errCode != AudioInitializationStatus.AllOk) {
			writeln("Device failed to initialize! Error code: ", errCode, " ; Windows error code: ", lastErrorCode);
			return 0;
		}
		AudioSpecs givenSpecs = device.requestSpecs(AudioSpecs(predefinedFormats[9], 48_000, 0x00, 0x02, 512, Duration.init));
		WASAPIDevice wdevice = cast(WASAPIDevice)device;
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
		if (givenSpecs.format.bits == 16)
			outStream.callback_buffer = &renderer.renderingCallback16;
		else if (givenSpecs.format.bits == 32)
			outStream.callback_buffer = &renderer.renderingCallback32;
		errCode = outStream.runAudioThread();
		if (errCode != AudioInitializationStatus.AllOk) {
			writeln("Audio stream failed to start! Error code: ", errCode, " ; Windows error code: ", woutStream.werrCode);
			return 0;
		}
		Thread.sleep(dur!"seconds"(10));
		const int errCode2 = outStream.errCode;
		errCode = outStream.suspendAudioThread();
		if (errCode != AudioInitializationStatus.AllOk && errCode2 != StreamRuntimeStatus.AllOk) {
			writeln("Audio stream failed to shut down! Error code: ", errCode, " ; Windows error code: ", woutStream.werrCode,
					"Stream error code: ", errCode2);
			return 0;
		}
		writeln("Callback time:", renderer.callbackTime);
	}
	return 0;
}

public class RenderingThread {
	protected int phasePos;
	protected const int phaseLenght = 480, cycleLenght = 960;
	public int callbackTime;
	this() {

	}
	void renderingCallback16(ubyte[] buffer) @nogc nothrow {
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