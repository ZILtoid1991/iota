module iota.audio.types;

public import core.time : Duration;

/** 
 * Defines audio driver types.
 */
enum DriverType {
	None,			///No driver have been initialized, etc.
	WASAPI,			///Windows Audio Stream API
	DirectAudio,	///Direct Audio API (Legacy)
	ALSA,			///Advanced Linux Sound Architecture
	JACK,			///JACK Audio Connection Kit
}
version (Windows) {
	static immutable DriverType OS_PREFERRED_DRIVER = DriverType.WASAPI;
} else version (linux) {
	static immutable DriverType OS_PREFERRED_DRIVER = DriverType.ALSA;
} else {
	static immutable DriverType OS_PREFERRED_DRIVER = DriverType.None;
}
/** 
 * Defines audio initialization status codes.
 */
enum AudioInitializationStatus {
	AllOk		=	0,		///No issues were encountered during initialization
	OSNotSupported,			///OS doesn't support this driver
	DriverNotAvailable,		///Driver is not available
	UninitializedDriver,	///Driver has not been initialized
	NoAudioDeviceFound,		///No audio device was found
	DeviceNotFound,			///Specified device cannot be found
	InternalError,			///Error likely due to this library
	OutOfMemory,			///Not enough memory to initialize driver
	Unknown,				///Error cannot be defined
}
/** 
 * Defines stream initialization status codes.
 */
enum StreamInitializationStatus {
	AllOk		=	0,		///No issues were encountered during initialization
	NoAudioService,			///Audio service not found
	OutOfMemory,			///Not enough memory to initialize stream
	UnsupportedFormat,		///Format isn't supported
	ModeNotSupported,		///Mode not supported
	DeviceInUse,			///Audio device is either in exclusive mode by another library, or can't get exclusive mode
	DeviceNotFound,			///Specified device cannot be found (e.g. got disconnected)
	InternalError,			///Error likely due to this library
	Unknown,				///Error cannot be defined
}
/**
 * Defines stream execution status codes.
 */
enum StreamRuntimeStatus {
	AllOk		=	0,		///No issues were encountered during startup of runtime
	BufferUnderrun,			///During runtime, a buffer underrun event happened
	BufferCallbackNotSet,	///The buffer callback wasn't set up
	DeviceNotFound,			///Specified device cannot be found (e.g. got disconnected)
	NoAudioService,			///Audio service not found
	InternalError,			///Error likely due to this library
	Unknown,				///Unexpected error code
}
/** 
 * Defines an audio sample format for streams.
 */
public struct SampleFormat {
	/// The number of bits for each sample.
	ubyte		bits;
	/// Flags that define the properties of the format.
	ubyte		flags;
	public enum Flag : ubyte {
		Type_Unknown		=	0x0,	/// Indicates either an unknown, or a format not directly supported by iota.
		Type_Unsigned		=	0x1,	/// Unsigned integer
		Type_Signed			=	0x2,	/// Signed integer
		Type_Float			=	0x3,	/// Floating-point
		/// To test types in branching
		Type_Test			=	0x3,
		/// Set if format is big endian
		BigEndian			=	0x4,
		/// Set if format is padded to whole byte boundary
		PaddedToByte		=	0x8,
		/// Set if format is padded to word (16/32/64 bit etc.) boundary
		PaddedToWord		=	0x10,
		/// Set if type is emulated
		IsEmulated			=	0x20,
	}
	/// Compression type, or zero if uncompressed.
	ubyte		cmprType;
	/// Auxilliary byte for padding, compression parameters, etc.
	ubyte		aux;
	/** 
	 * Returns true if format is in native endian format.
	 */
	public bool isNativeEndian() @nogc @safe pure nothrow const {
		version (LittleEndian)
			return (flags & Flag.BigEndian) == 0;
		else
			return (flags & Flag.BigEndian) != 0;
	}
}
/**
 * Contains commonly used predefined formats.
 */
public immutable SampleFormat[] predefinedFormats = [
	//Little endian formats (does anyone still using big endian?)
	SampleFormat(0x08, 0x01, 0x00, 0x00),	//8 bit unsigned integer
	SampleFormat(0x08, 0x02, 0x00, 0x00),	//8 bit signed integer
	SampleFormat(0x10, 0x01, 0x00, 0x00),	//16 bit unsigned integer
	SampleFormat(0x10, 0x02, 0x00, 0x00),	//16 bit signed integer
	SampleFormat(0x18, 0x01, 0x00, 0x00),	//24 bit unsigned integer
	SampleFormat(0x18, 0x02, 0x00, 0x00),	//24 bit signed integer
	SampleFormat(0x18, 0x11, 0x00, 0x00),	//24 bit unsigned integer (padded to 32 bit word)
	SampleFormat(0x18, 0x12, 0x00, 0x00),	//24 bit signed integer (padded to 32 bit word)
	SampleFormat(0x20, 0x01, 0x00, 0x00),	//32 bit unsigned integer
	SampleFormat(0x20, 0x02, 0x00, 0x00),	//32 bit signed integer
	SampleFormat(0x20, 0x03, 0x00, 0x00),	//32 bit floating-point
];
public enum PredefinedFormats {
	UI8,		//8 bit unsigned integer
	SI8,		//8 bit signed integer
	UI16,		//16 bit unsigned integer
	SI16,		//16 bit signed integer
	UI24UP,		//24 bit unsigned integer
	SI24UP,		//24 bit signed integer
	UI24,		//24 bit unsigned integer (padded to 32 bit word)
	SI24,		//24 bit signed integer (padded to 32 bit word)
	UI32,		//32 bit unsigned integer
	SI32,		//32 bit signed integer
	FP32,		//32 bit floating-point
}
/** 
 * Used to set audio specifications, etc.
 *
 * Note on buffer length: When requesting, only one of the bufferSize parameters have to be set. If both are set, then
 * `bufferSize_slmp` takes priority. If neither are set, then the library tries to request a recommended buffer size.
 * On returning, both are set to reflect on the current specifications.
 */
public struct AudioSpecs {
	/// The format of the audio
	SampleFormat	format;
	/// The sample rate of the specified stream.
	int				sampleRate;
	/// The number of input channels.
	short			inputChannels;
	/// The number of output channels.
	short			outputChannels;
	/// The length of the audio buffer in samples.
	/// See note on buffer length.
	uint			bufferSize_slmp;
	/// The length of the audio buffer in a given time.
	/// See note on buffer length.
	Duration		bufferSize_time;
	/** 
	 * Returns the number of bits per channel, including padding.
	 */
	public uint bits() @nogc @safe pure nothrow const {
		uint result = format.bits;
		if (format.flags & format.Flag.PaddedToByte) {
			result += 8 - (format.bits % 8);
		} else if (format.flags & format.Flag.PaddedToWord) {
			result += 32 - (format.bits % 32);
		}
		return result;
	}
	/** 
	 * Mirrors the buffer sizes if one is set to T.init.
	 */
	public void mirrorBufferSizes() @safe {
		import core.time : hnsecs;
		if (bufferSize_slmp) {
			bufferSize_time = hnsecs(cast(long)((1 / cast(real)sampleRate) * bufferSize_slmp * 10_000_000.0));
		} else if (cast(bool)bufferSize_time) {
			bufferSize_slmp = cast(uint)((bufferSize_time.total!"hnsecs" / 10_000_000.0) / (1 / cast(real)sampleRate));
		}
	}
	/**
	 * Returns a string representation of this struct.
	 */
	public string toString() const @safe { 
		import std.format : format;
		string result;
		result ~= format("%s bits ", this.format.bits);
		switch (this.format.flags & SampleFormat.Flag.Type_Test) {
			case SampleFormat.Flag.Type_Signed:
				result ~= "signed; ";
				break;
			case SampleFormat.Flag.Type_Unsigned:
				result ~= "unsigned; ";
				break;
			case SampleFormat.Flag.Type_Float:
				result ~= "floating point; ";
				break;
			default: break;
		}
		result ~= format("sample rate: %s Hz; ", sampleRate);
		result ~= format("input channels: %s ; ", inputChannels);
		result ~= format("output channels: %s ; ", outputChannels);
		result ~= format("buffer size (in samples): %s ; ", bufferSize_slmp);
		result ~= format("buffer size (in time): %s ms; ", (cast(real)bufferSize_time.total!"hnsecs" / 10_000.0));
		return result;
	}
}
/** 
 * Tells the stream initializer which specs are needed, or tells it to recommend a spec.
 */
public enum AudioSpecsInitFlags {
	init,

	CloseBufferSize			=	1<<0,	///Buffer size won't be higher than the nearest power of two
	ExactBits				=	1<<1,	///Requests exactly the same number of bits (might be emulated)
	ExactFormat				=	1<<2,	///Requests exactly the same format (might be emulated)
	CloseSampleRate			=	1<<3,	///Requests a nearby sample rate
	ExactSampleRate			=	1<<4,	///Requests the exact sample rate
	ExactInputChannels		=	1<<5,	///Requests the exact number of input channels
	ExactOutputChannels		=	1<<6,	///Requests the exact number of output channels

	UseRecommendedSpecs		=	-1,
	UseRecommendedHDSpecs	=	-2,
}
/** 
 * Tells whether the audio stream is shared with other applications.
 * Some drivers might work only in one mode, others can be switched.
 */
public enum AudioShareMode : ubyte {
	Shared,
	Exlusive
}
/** 
 * Defines MIDI initialization status codes.
 */
public enum MIDIInitializationStatus {
	AllOk	=	0,		///No errors were encountered, operation was successful.
	DevicesNotFound,	///No devices are found.
	InitError,			///Initialization error otherwise not specified.
	OSNotSupported,		///OS not (yet) supported.
	UnknownError
}
/** 
 * Defines MIDI device initialization status codes.
 */
public enum MIDIDeviceInitStatus {
	AllOk	=	0,		///No errors were encountered, operation was successful.
	InvalidDeviceID,	///Invalid device ID.
	DeviceDisconnected,	///Device disconnected, or invalidated.
	InitError,			///Initialization error otherwise not specified.
	OutOfMemory,		///Out of memory error.
	OSNotSupported,		///OS not (yet) supported.
	UnknownError
}
/** 
 * Defines MIDI device status codes.
 */
public enum MIDIDeviceStatus {
	AllOk	=	0,		///No errors were encountered, operation was successful.
	DeviceDisconnected,	///Device disconnected, or invalidated.
	UnknownError,
}
public enum DeviceDirection : ubyte {
	init,
	Input	=	0x01,
	Output	=	0x02,
	IO		=	0x03,	///Both input and output
}