module iota.audio.wasapi;

version (Windows):

package import iota.audio.backend.windows;

import iota.audio.device;
import iota.audio.output;

//import core.thread;

import core.sys.windows.windows;
import core.sys.windows.objidl;
import core.sys.windows.wtypes;

import core.time;

import core.thread;

package IMMDeviceEnumerator immEnum;
package IMMDeviceCollection deviceList;

shared static ~this() {
	if (immEnum !is null) immEnum.Release();
	if (deviceList !is null) deviceList.Release();
	CoUninitialize();
}
/** 
 * Contains the last error code returned during driver or device initialization.
 */
public static HRESULT lastErrorCode;

package int initDriverWASAPI() @trusted {
	if (immEnum) {
		lastErrorCode = immEnum.EnumAudioEndpoints(EDataFlow.eRender, DEVICE_STATE_ACTIVE, deviceList);
		switch (lastErrorCode) {
			case S_OK:
				if (deviceList !is null){
					initializedDriver = DriverType.WASAPI;
					return AudioInitializationStatus.AllOk;
				} else {
					return AudioInitializationStatus.UninitializedDriver;
				}
			case E_OUTOFMEMORY: return AudioInitializationStatus.OutOfMemory;
			case E_POINTER, E_INVALIDARG: return AudioInitializationStatus.InternalError;
			default: return AudioInitializationStatus.Unknown;
		}
	} else return AudioInitializationStatus.DriverNotAvailable;
}
/** 
 * Implements a WASAPI device, and can create both input and output streams for such devices.
 */
public class WASAPIDevice : AudioDevice {
	/// References the backend
	protected IMMDevice			backend;
	/// Contains the properties of this device
	protected IPropertyStore	devProperties;
	/// The audio client. Initialized upon a successful audiospecs request.
	protected IAudioClient		audioClient;
	/// Windows specific audio format.
	protected WAVEFORMATEX		waudioSpecs;
	/// Windows specific error codes
	public HRESULT				werrCode;
	/** 
	 * Creates an instance that refers to the backend. 
	 */
	package this(IMMDevice backend) @system {
		this.backend = backend;
		werrCode = backend.OpenPropertyStore(STGM_READ, devProperties);
		if (werrCode == S_OK) {

		}
		this._nOfOutputs = -1;
		this._nOfInputs = -1;
		werrCode = backend.Activate(IID_IAudioClient, CLSCTX_ALL, null, cast(void**)&audioClient);
		if (werrCode != S_OK) {
			switch (werrCode) {
				case E_NOINTERFACE: errCode = AudioInitializationStatus.DriverNotAvailable; break;
				case AUDCLNT_E_DEVICE_INVALIDATED: errCode = AudioInitializationStatus.DeviceNotFound; break;
				case E_OUTOFMEMORY: errCode = AudioInitializationStatus.OutOfMemory; break;
				case E_INVALIDARG, E_POINTER: errCode = AudioInitializationStatus.InternalError; break;
				default: errCode = AudioInitializationStatus.Unknown; break;
			}
		}
	}
	~this() {
		if (backend !is null)
			backend.Release();
		if (devProperties !is null)
			devProperties.Release();
		if (audioClient !is null)
			audioClient.Release();
	}
	/**
	 *
	 */
	public @property AudioShareMode shareMode(AudioShareMode val) @nogc @safe pure nothrow {
		return _shareMode = val;
	}
	/** 
	 * Returns the recommended sample rate, or -1 if sample-rate isn't bound to internal clock.
	 */
	public override int getRecommendedSampleRate() nothrow @trusted {
		WAVEFORMATEX* format;
		werrCode = audioClient.GetMixFormat(&format);

		const int result = format.nSamplesPerSec;
		CoTaskMemFree(format);
		return result;
	}
	/**
	 * Sets the device's audio specifications to the closest possible specifications.
	 * Params:
	 *  reqSpecs = The requested audio secifications. Can be set AudioSpecs.init if don't care.
	 *  flags = Tells the function what specifications are must or can be compromised.
	 * Returns: The actual audio specs, or AudioSpecs.init in case of failure.
	 * In case of a failure, `errCode` is also set with the corresponding flags.
	 */
	public override AudioSpecs requestSpecs(AudioSpecs reqSpecs, int flags = 0) @trusted {
		reqSpecs.mirrorBufferSizes();
		if (reqSpecs.outputChannels) {
			
			waudioSpecs.wFormatTag = (reqSpecs.format.flags & SampleFormat.Flag.Type_Test) != SampleFormat.Flag.Type_Float ? 
					WAVE_FORMAT_PCM : WAVE_FORMAT_IEEE_FLOAT;
			waudioSpecs.nSamplesPerSec = reqSpecs.sampleRate;
			waudioSpecs.nChannels = reqSpecs.outputChannels;
			waudioSpecs.wBitsPerSample = reqSpecs.format.bits;
			waudioSpecs.nBlockAlign = cast(ushort)((waudioSpecs.wBitsPerSample / 8) * reqSpecs.outputChannels);
			waudioSpecs.nAvgBytesPerSec = waudioSpecs.nBlockAlign * waudioSpecs.nSamplesPerSec;
			WAVEFORMATEX* closestMatch;
			werrCode = audioClient.IsFormatSupported(
				_shareMode == AudioShareMode.Shared ? AUDCLNT_SHAREMODE.AUDCLNT_SHAREMODE_SHARED : 
				AUDCLNT_SHAREMODE.AUDCLNT_SHAREMODE_EXCLUSIVE, &waudioSpecs, &closestMatch);
			if (closestMatch)
				waudioSpecs = *closestMatch;
			switch (werrCode) {
				case S_OK: break;
				case S_FALSE, AUDCLNT_E_UNSUPPORTED_FORMAT:
					reqSpecs.sampleRate = waudioSpecs.nSamplesPerSec;
					reqSpecs.format.bits = cast(ubyte)waudioSpecs.wBitsPerSample;
					reqSpecs.mirrorBufferSizes();
					break;
				case E_POINTER, E_INVALIDARG: 
					errCode = AudioInitializationStatus.InternalError; 
					return AudioSpecs.init;
				case AUDCLNT_E_DEVICE_INVALIDATED: 
					errCode = AudioInitializationStatus.DeviceNotFound; 
					return AudioSpecs.init;
				case AUDCLNT_E_SERVICE_NOT_RUNNING: 
					errCode = AudioInitializationStatus.DriverNotAvailable; 
					return AudioSpecs.init;
				default: 
					errCode = AudioInitializationStatus.Unknown; 
					break;
			}
			
			CoTaskMemFree(closestMatch);
		}
		return _specs = reqSpecs;
	}
	/** 
	 * Creates an OutputStream specific to the given driver/device, with the requested parameters, then returns it. Or
	 * null in case of an error. 
	 */
	public override OutputStream createOutputStream() nothrow @trusted {
		if (audioClient !is null) {
			werrCode = audioClient.Initialize(
					_shareMode == AudioShareMode.Shared ? AUDCLNT_SHAREMODE.AUDCLNT_SHAREMODE_SHARED : 
					AUDCLNT_SHAREMODE.AUDCLNT_SHAREMODE_EXCLUSIVE, 
					AUDCLNT_STREAMFLAGS_AUTOCONVERTPCM | AUDCLNT_STREAMFLAGS_EVENTCALLBACK,
					_specs.bufferSize_time.total!"hnsecs", _specs.bufferSize_time.total!"hnsecs", &waudioSpecs, null);
			if (werrCode != S_OK) {
				switch (werrCode) {
					case E_OUTOFMEMORY: errCode = StreamInitializationStatus.OutOfMemory; break;
					case E_INVALIDARG: errCode = StreamInitializationStatus.ModeNotSupported; break;
					default: errCode = StreamInitializationStatus.Unknown; break;
				}
				return null;
			}
			IAudioClient temp = audioClient;
			audioClient = null;
			return new WASAPIOutputStream(temp, _specs.outputChannels * _specs.bits, _specs.bufferSize_slmp);
		} else
			return null;
	}
}

public class WASAPIOutputStream : OutputStream {
	protected uint			bufferSize;
	protected uint			frameSize;
	protected IAudioClient	backend;
	protected IAudioRenderClient buffer;
	protected HANDLE		eventHandle;
	public HRESULT			werrCode;
	package this(IAudioClient backend, uint frameSize, uint bufferSize) nothrow @nogc @system {
		this.backend = backend;
		this.frameSize = frameSize;
		eventHandle = CreateEvent(null, FALSE, FALSE, null);
		werrCode = backend.SetEventHandle(eventHandle);
		switch (werrCode) {
			case S_OK: break;
			case AUDCLNT_E_EVENTHANDLE_NOT_EXPECTED, AUDCLNT_E_NOT_INITIALIZED: 
				errCode = StreamRuntimeStatus.InternalError; return;
			case AUDCLNT_E_DEVICE_INVALIDATED: errCode = StreamRuntimeStatus.DeviceNotFound; return;
			case AUDCLNT_E_SERVICE_NOT_RUNNING: errCode = StreamRuntimeStatus.NoAudioService; return;
			default: errCode = StreamRuntimeStatus.Unknown; break;
		}
		this.bufferSize = bufferSize;
		/+werrCode = backend.GetBufferSize(bufferSize);
		switch (werrCode) {
			case AUDCLNT_E_NOT_INITIALIZED, E_POINTER: errCode = StreamRuntimeStatus.InternalError; return;
			case AUDCLNT_E_DEVICE_INVALIDATED: errCode = StreamRuntimeStatus.DeviceNotFound; return;
			case AUDCLNT_E_SERVICE_NOT_RUNNING: errCode = StreamRuntimeStatus.NoAudioService; return;
			case S_OK: break;
			default: errCode = StreamRuntimeStatus.Unknown; break;
		}
		UINT32 padding;
		backend.GetCurrentPadding(padding);
		bufferSize -= padding;+/
		werrCode = backend.GetService(IID_IAudioRenderClient, cast(void**)&buffer);
		switch (werrCode) {
			case E_POINTER, AUDCLNT_E_NOT_INITIALIZED, AUDCLNT_E_WRONG_ENDPOINT_TYPE:
				errCode = StreamRuntimeStatus.InternalError; 
				return;
			case AUDCLNT_E_DEVICE_INVALIDATED: errCode = StreamRuntimeStatus.DeviceNotFound; return;
			case AUDCLNT_E_SERVICE_NOT_RUNNING: errCode = StreamRuntimeStatus.NoAudioService; return;
			case S_OK: break;
			default: errCode = StreamRuntimeStatus.Unknown; break;
		}
	}
	~this() {
		if (buffer !is null) buffer.Release();
		if (backend !is null) backend.Release();
		CloseHandle(eventHandle);
	}
	protected void audioThread() @nogc nothrow {
		const size_t cbufferSize = bufferSize * (frameSize / 8);
		while (statusCode & StatusFlags.IsRunning) {
			werrCode = WaitForSingleObject(eventHandle, 500);
			if (werrCode != WAIT_OBJECT_0) {
				backend.Stop();
				errCode = StreamRuntimeStatus.Unknown;
			}
			if (buffer is null) return;
			ubyte* data;
			do {		// To do: This is a bit janky, and there's like some glitches in the test audio. (Not so much in real tests)
				werrCode = buffer.GetBuffer(bufferSize, data);
				if (werrCode == AUDCLNT_E_BUFFER_TOO_LARGE) statusCode |= StatusFlags.BufferOverrun;	//Set buffer overrun flag if protection was engaged.
			} while (werrCode == AUDCLNT_E_BUFFER_TOO_LARGE && (statusCode & StatusFlags.IsRunning) && buffer !is null);
			switch (werrCode) {
				case AUDCLNT_E_BUFFER_TOO_LARGE: return;
				case AUDCLNT_E_BUFFER_ERROR, AUDCLNT_E_BUFFER_SIZE_ERROR, AUDCLNT_E_OUT_OF_ORDER, 
						AUDCLNT_E_BUFFER_OPERATION_PENDING:
					errCode = StreamRuntimeStatus.InternalError;
					backend.Stop();
					return;
				case AUDCLNT_E_DEVICE_INVALIDATED:
					errCode = StreamRuntimeStatus.DeviceNotFound;
					return;
				case S_OK: break;
				default: errCode = StreamRuntimeStatus.Unknown; break;
			}
			callback_buffer(data[0..cbufferSize]);
			werrCode = buffer.ReleaseBuffer(bufferSize, 0);
			switch (werrCode) {
				case AUDCLNT_E_INVALID_SIZE, AUDCLNT_E_BUFFER_SIZE_ERROR, AUDCLNT_E_OUT_OF_ORDER:
					errCode = StreamRuntimeStatus.InternalError;
					backend.Stop();
					return;
				case AUDCLNT_E_DEVICE_INVALIDATED:
					errCode = StreamRuntimeStatus.DeviceNotFound;
					backend.Stop();
					return;
				case S_OK: break;
				default: errCode = StreamRuntimeStatus.Unknown; break;
			}
			ResetEvent(eventHandle);
		}
	}
	/** 
	 * Runs the audio thread. This either means that it'll create a new low-level thread to feed the stream a steady 
	 * amount of data, or use whatever backend the OS has.
	 * Returns: 0, or an error code if there was a failure.
	 */
	public override int runAudioThread() @trusted @nogc nothrow {
		if (callback_buffer is null) return errCode = StreamRuntimeStatus.BufferCallbackNotSet;
		werrCode = backend.Start();
		if (werrCode != S_OK) {

		}
		statusCode |= StatusFlags.IsRunning;
		_threadID = createLowLevelThread(&audioThread);
		return errCode = StreamRuntimeStatus.AllOk;
	}
	/**
	 * Suspends the audio thread by allowing it to escape normally and close things safely, or suspending it on the
	 * backend.
	 * Returns: 0, or an error code if there was a failure.
	 * Note: It's wise to put this function into a mutex, or a `synchronized` block.
	 */
	public override int suspendAudioThread() @trusted @nogc nothrow {
		if (errCode) {
			backend.Stop();
			return errCode;
		} else {
			werrCode = backend.Stop();
			if (werrCode != S_OK) {

			}
			statusCode &= ~StatusFlags.IsRunning;
			return errCode = StreamRuntimeStatus.AllOk;
		}
	}
}