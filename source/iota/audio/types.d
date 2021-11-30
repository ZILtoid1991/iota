module iota.audio.types;

/** 
 * Defines audio driver types.
 */
enum DriverType {
	None,			///No driver have been initialized, etc.
	WASAPI,			///Windows Audio Stream API
	DirectAudio,	///Direct Audio API (Legacy)
	ALSA,
	JACK,
	PulseAudio,
}
version (windows) {
	static immutable DriverType OS_PREFERRED_DRIVER = DriverType.WASAPI;
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
	Unknown,				///Error cannot be defined
}
enum StreamInitializationStatus {
	AllOk		=	0,		///No issues were encountered during initialization
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
	}
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