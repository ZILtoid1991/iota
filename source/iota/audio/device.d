module iota.audio.device;

import std.string;
import std.utf;
import core.time : Duration;

public import iota.audio.types;
public import iota.audio.output;

version (Windows) {
	public import iota.audio.wasapi;
	import core.sys.windows.windows;
	import core.sys.windows.objidl;
	import core.sys.windows.wtypes;
}
/** 
 * The type of the initialized driver, or none if no driver was initialized yet.
 */
package static DriverType initializedDriver;
/** 
 * Initializes the audio driver, then sets up the device list.
 * Params:
 *   type = The type of driver, defaults to system recommended otherwise.
 * Returns: 0 (or AudioInitializationStatus.AllOk) if there was no error, or a specific errorcode.
 */
public int initDriver(DriverType type = OS_PREFERRED_DRIVER) {
	final switch (type) with (DriverType) {
		case None:
			return AudioInitializationStatus.AllOk;
		case WASAPI:
			version (Windows) {
				lastErrorCode = CoCreateInstance(&CLSID_MMDeviceEnumerator, null, CLSCTX_ALL, &IID_IMMDeviceEnumerator, 
						cast(void**)&immEnum);
				switch (lastErrorCode) {
					case S_OK: return initDriverWASAPI();
					case E_NOINTERFACE: return AudioInitializationStatus.DriverNotAvailable;
					default: return AudioInitializationStatus.Unknown;
				}
			} else {
				return AudioInitializationStatus.OSNotSupported;
			}
		case DirectAudio:

			break;
		case ALSA:

			break;
		case JACK:

			break;
		case PulseAudio:

			break;
	}
	return AudioInitializationStatus.Unknown;
}
/** 
 * Returns the list of names of output devices, or null if there are none or driver haven't been initialized.
 */
public string[] getOutputDeviceNames() nothrow {
	version (Windows) {
		if (initializedDriver == DriverType.WASAPI) {
			string[] result;
			UINT nOfDevices;
			lastErrorCode = deviceList.GetCount(nOfDevices);
			if (lastErrorCode) return null;
			result.length = nOfDevices;
			for (uint i ; i < result.length ; i++) {
				IMMDevice ppDevice;
				lastErrorCode = deviceList.Item(i, ppDevice);
				LPWSTR str;
				if (lastErrorCode == S_OK) ppDevice.GetId(str);
				else str = null;
				result[i] = toUTF8(fromStringz(str));
				try {
					CoTaskMemFree(str);
				} catch (Exception e) {
					
				}
			}
			return result;
		} else {
			return null;
		}
	}
}
/** 
 * Initializes an audio device.
 * Params:
 *   devID = The number of the device, or -1 if default output device is needed.
 *   device = Reference to newly opened device passed here.
 * Returns: 0 (or AudioInitializationStatus.AllOk) if there was no error, or a specific errorcode.
 */
public int openDevice(int devID, ref AudioDevice device) {
	version (Windows) {
		if (initializedDriver == DriverType.WASAPI) {
			IMMDevice dev; 
			if (devID >= 0) {
				lastErrorCode = deviceList.Item(devID, dev);
			} else {
				lastErrorCode = immEnum.GetDefaultAudioEndpoint(EDataFlow.eRender, ERole.eMultimedia, dev);
			}
			if (dev is null) return AudioInitializationStatus.DeviceNotFound;
			device = new WASAPIDevice(dev);
			return AudioInitializationStatus.AllOk;
		} else {
			return AudioInitializationStatus.UninitializedDriver;
		}
	} else {
		return AudioInitializationStatus.Unknown;
	}
}
/** 
 * Implements a universal interface to an audio device.
 * Each driver inherits from this.
 */
public abstract class AudioDevice {
	/// Stores either all supported sample rates, or two values of lowest and highest supported sample rates if any 
	/// value can be set without stepping.
	/// NOTE: It is not guaranteed, that at all sample ranges, all formats will be available.
	protected int[]		_sampleRateRange;
	/// Stores supported formats.
	protected SampleFormat[]	_supportedFormats;
	/// Number of input channels, or zero if there's none.
	protected short		_nOfInputs;
	/// Number of output channels, or zero if there's none.
	protected short		_nOfOutputs;
	/// The last error code if there's any, or 0.
	/// Shall not be set externally, although should not impede on operation.
	public int			errCode;
	/// The audio specifications set and available to this device.
	protected AudioSpecs	_specs;
	/// Tells whether the device is in shared or exclusive mode.
	/// In some cases, this can be set, in others it's either shared or exclusive.
	protected AudioShareMode _shareMode;
	/** 
	 * Called when device is disconnected.
	 */
	public @nogc nothrow void delegate() callback_onDeviceDisconnect;
	/** 
	 * Returns the range of sample rates that this audio device supports. Might return null if it's enforced at audio
	 * spec request.
	 * NOTE: It is not guaranteed, that at all sample ranges, all formats will be available.
	 */
	public @property int[] sampleRateRange() @safe pure nothrow const {
		return _sampleRateRange.dup;
	}
	/** 
	 * Returns the range of audio formats that this audio device supports. Might return null if it's enforced at audio
	 * spec request.
	 * NOTE: It is not guaranteed, that at all sample ranges, all formats will be available.
	 */
	public @property SampleFormat[] supportedFormats() @safe pure nothrow const {
		return _supportedFormats.dup;
	}
	/** 
	 * Returns the number of input channels this device has, or zero if there's none, or -1 if it's enforced at audio
	 * spec request.
	 * NOTE: Depending on the backend, devices' inputs and outputs (or even different inputs and outputs) might show up
	 * as different devices.
	 */
	public @property short nOfInputs() @nogc @safe pure nothrow const {
		return _nOfInputs;
	}
	/** 
	 * Returns the number of output channels this device has, or zero if there's none, or -1 if it's enforced at audio
	 * spec request.
	 * NOTE: Depending on the backend, devices' inputs and outputs (or even different inputs and outputs) might show up
	 * as different devices.
	 */
	public @property short nOfOutputs() @nogc @safe pure nothrow const {
		return _nOfOutputs;
	}
	/** 
	 * Returns the currently set audio specifications.
	 */
	public @property AudioSpecs specs() @nogc @safe pure nothrow const {
		return _specs;
	}
	public @property AudioShareMode shareMode() @nogc @safe pure nothrow const {
		return _shareMode;
	}
	/**
	 * Sets the device's audio specifications to the closest possible specifications.
	 * Params:
	 *  reqSpecs = The requested audio secifications. Can be set AudioSpecs.init if don't care.
	 *  flags = Tells the function what specifications are must or can be compromised.
	 * Returns: The actual audio specs, or AudioSpecs.init in case of failure.
	 * In case of a failure, `errCode` is also set with the corresponding flags.
	 */
	public abstract AudioSpecs requestSpecs(AudioSpecs reqSpecs, int flags = 0);
	/** 
	 * Creates an OutputStream specific to the given driver/device, with the requested parameters, then returns it. Or
	 * null in case of an error, then it also sets `errCode` to a given error code. Might also set a separate error
	 * code variable, depending on the OS/backend.
	 */
	public abstract OutputStream createOutputStream();
}