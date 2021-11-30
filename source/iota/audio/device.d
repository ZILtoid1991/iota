module iota.audio.device;

public import iota.audio.types;
public import iota.audio.output;

version (Windows) import iota.audio.wasapi;
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
				wasapiHandler = new MMDevices();
				bool status = wasapiHandler.init();
				if (!status) return AudioInitializationStatus.DriverNotAvailable;
				wasapiOutDevices = wasapiHandler.getPlaybackDevices();
				return AudioInitializationStatus.AllOk;
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
public string[] getOutputDevices() nothrow {
	version (Windows) {
		if (initializedDriver == DriverType.WASAPI) {
			string[] result;
			foreach (dev ; wasapiOutDevices) {
				result ~= dev.interfaceName ~ ";" ~ dev.friendlyName;
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
 *   devID = The number of the output device, or -1 if default device is needed.
 *   device = Reference to newly opened device passed here.
 * Returns: 0 (or AudioInitializationStatus.AllOk) if there was no error, or a specific errorcode.
 */
public int openDevice(int devID, ref AudioDevice device) {
	version (Windows) {
		if (initializedDriver == DriverType.WASAPI) {
			IMMDevice dev; 
			if (devID >= 0) {
				dev = wasapiHandler.getDevice(wasapiOutDevices[devID].id);
			} else {
				foreach (d ; wasapiOutDevices) {
					if (d.isDefault) dev = wasapiHandler.getDevice(d.id);
				}
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
	protected int[]		sampleRateRange;
	/// Stores supported formats.
	protected SampleFormat[]	supportedFormats;
	/// Number of input channels, or zero if there's none.
	protected short		nOfInputs;
	/// Number of output channels, or zero if there's none.
	protected short		nOfOutputs;
	/** 
	 * Creates an OutputStream specific to the given driver/device, with the requested parameters, then returns it. Or
	 * null in case of an error.
	 */
	public abstract OutputStream createOutputStream();
}