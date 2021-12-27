module iota.audio.alsa;

version (linux):

package import iota.audio.backend.linux;

import iota.audio.device;
import iota.audio.output;

import core.time;

import core.stdc.stdlib;

import core.thread;

/// Name of all devices
package static char*[] devicenames;
/// The last ALSA specific error code
public static int lastErrorCode;

/// Automatic cleanup.
shared static ~this() {
	flushNames();
}
/** 
 * Flushes all device names automatically.
 */
package void flushNames() {
	foreach (key ; devicenames)
		free(key);
}
/** 
 * Returns the error string from an error code.
 * Params:
 *   errCode = 
 */
public string getErrorString(int errCode) {
	import std.string : fromStringz;
	return fromStringz(snd_strerror(errCode)).idup;
}
/** 
 * Implements an ALSA device.
 */
public class ALSADevice : AudioDevice {
	package snd_pcm_t*		pcmHandle;
	protected snd_pcm_hw_params_t* pcmParams;
	/// Contains ALSA-related error codes.
	public int				alsaerrCode;
	package this (snd_pcm_t* pcmHandle) {
		this.pcmHandle = pcmHandle;
		snd_pcm_hw_params_malloc(&pcmParams);
		snd_pcm_hw_params_any(pcmHandle, pcmParams);
		uint val;
		snd_pcm_hw_params_get_channels_max(pcmParams, &val);
		this._nOfOutputs = cast(short)val;
		this._nOfInputs = -1;
	}
	~this() {
		snd_pcm_close(pcmHandle);
		snd_pcm_hw_params_free(pcmParams);

	}

	override public AudioSpecs requestSpecs(AudioSpecs reqSpecs, int flags = 0) {
		reqSpecs.mirrorBufferSizes();
		alsaerrCode = snd_pcm_hw_params_set_access(pcmHandle, pcmParams, snd_pcm_access_t.SND_PCM_ACCESS_RW_INTERLEAVED);
		if (alsaerrCode) {errCode = StreamInitializationStatus.UnsupportedFormat; return AudioSpecs.init;}
		switch (reqSpecs.format.bits) {
			case 0x08:
				switch (reqSpecs.format.flags & SampleFormat.Flag.Type_Test) {
					case SampleFormat.Flag.Type_Unsigned:
						alsaerrCode = snd_pcm_hw_params_set_format(pcmHandle, pcmParams, snd_pcm_format.SND_PCM_FORMAT_U8);
						break;
					case SampleFormat.Flag.Type_Signed:
						alsaerrCode = snd_pcm_hw_params_set_format(pcmHandle, pcmParams, snd_pcm_format.SND_PCM_FORMAT_S8);
						break;
					default:
						errCode = StreamInitializationStatus.UnsupportedFormat; return AudioSpecs.init;
				}
				break;
			case 0x10:
				switch (reqSpecs.format.flags & SampleFormat.Flag.Type_Test) {
					case SampleFormat.Flag.Type_Unsigned:
						alsaerrCode = snd_pcm_hw_params_set_format(pcmHandle, pcmParams, snd_pcm_format.SND_PCM_FORMAT_U16_LE);
						break;
					case SampleFormat.Flag.Type_Signed:
						alsaerrCode = snd_pcm_hw_params_set_format(pcmHandle, pcmParams, snd_pcm_format.SND_PCM_FORMAT_S16_LE);
						break;
					default:
						errCode = StreamInitializationStatus.UnsupportedFormat; return AudioSpecs.init;
				}
				break;
			case 0x18:
				switch (reqSpecs.format.flags & SampleFormat.Flag.Type_Test) {
					case SampleFormat.Flag.Type_Unsigned:
						alsaerrCode = snd_pcm_hw_params_set_format(pcmHandle, pcmParams, snd_pcm_format.SND_PCM_FORMAT_U24_LE);
						break;
					case SampleFormat.Flag.Type_Signed:
						alsaerrCode = snd_pcm_hw_params_set_format(pcmHandle, pcmParams, snd_pcm_format.SND_PCM_FORMAT_S24_LE);
						break;
					default:
						errCode = StreamInitializationStatus.UnsupportedFormat; return AudioSpecs.init;
				}
				break;
			case 0x20:
				switch (reqSpecs.format.flags & SampleFormat.Flag.Type_Test) {
					case SampleFormat.Flag.Type_Float:
						alsaerrCode = snd_pcm_hw_params_set_format(pcmHandle, pcmParams, snd_pcm_format.SND_PCM_FORMAT_FLOAT_LE);
						break;
					case SampleFormat.Flag.Type_Unsigned:
						alsaerrCode = snd_pcm_hw_params_set_format(pcmHandle, pcmParams, snd_pcm_format.SND_PCM_FORMAT_U32_LE);
						break;
					case SampleFormat.Flag.Type_Signed:
						alsaerrCode = snd_pcm_hw_params_set_format(pcmHandle, pcmParams, snd_pcm_format.SND_PCM_FORMAT_S32_LE);
						break;
					default:
						errCode = StreamInitializationStatus.UnsupportedFormat; return AudioSpecs.init;
				}
				break;
			default: 
				errCode = StreamInitializationStatus.UnsupportedFormat; return AudioSpecs.init;
		}
		if (alsaerrCode) {errCode = StreamInitializationStatus.UnsupportedFormat; return AudioSpecs.init;}
		alsaerrCode = snd_pcm_hw_params_set_channels(pcmHandle, pcmParams, reqSpecs.outputChannels);
		if (alsaerrCode) {errCode = StreamInitializationStatus.UnsupportedFormat; return AudioSpecs.init;}
		//snd_pcm_hw_params_set_access(pcmHandle, pcmParams, snd_pcm_access_t.SND_PCM_ACCESS_RW_INTERLEAVED);
		int something = 0;
		alsaerrCode = snd_pcm_hw_params_set_rate_near(pcmHandle, pcmParams, cast(uint*)&reqSpecs.sampleRate, &something);
		if (alsaerrCode) {errCode = StreamInitializationStatus.UnsupportedFormat; return AudioSpecs.init;}
		uint periods = (reqSpecs.bits() * reqSpecs.outputChannels) / 8;
		alsaerrCode = snd_pcm_hw_params_set_periods_near(pcmHandle, pcmParams, &periods, 0);
		if (alsaerrCode) {errCode = StreamInitializationStatus.UnsupportedFormat; return AudioSpecs.init;}
		snd_pcm_uframes_t bufferlen = reqSpecs.bufferSize_slmp * periods;
		alsaerrCode = snd_pcm_hw_params_set_buffer_size_near(pcmHandle, pcmParams, &bufferlen);
		if (alsaerrCode) {errCode = StreamInitializationStatus.UnsupportedFormat; return AudioSpecs.init;}
		reqSpecs.bufferSize_slmp = cast(uint)(bufferlen / periods);
		reqSpecs.bufferSize_time = Duration.init;
		reqSpecs.mirrorBufferSizes();
		alsaerrCode = snd_pcm_hw_params(pcmHandle, pcmParams);
		if (alsaerrCode) {errCode = StreamInitializationStatus.UnsupportedFormat; return AudioSpecs.init;}
		// Set up software parameters
		snd_pcm_sw_params_t* swparams;
		alsaerrCode = snd_pcm_sw_params_malloc(&swparams);
		scope (exit)
			snd_pcm_sw_params_free(swparams);
		if (alsaerrCode) {errCode = StreamInitializationStatus.OutOfMemory; return AudioSpecs.init;}
		alsaerrCode = snd_pcm_sw_params_current(pcmHandle, swparams);
		if (alsaerrCode) {errCode = StreamInitializationStatus.OutOfMemory; return AudioSpecs.init;}
		alsaerrCode = snd_pcm_sw_params_set_avail_min(pcmHandle, swparams, reqSpecs.bufferSize_slmp);
		if (alsaerrCode) {errCode = StreamInitializationStatus.UnsupportedFormat; return AudioSpecs.init;}
		alsaerrCode = snd_pcm_sw_params_set_start_threshold(pcmHandle, swparams, 0);
		if (alsaerrCode) {errCode = StreamInitializationStatus.UnsupportedFormat; return AudioSpecs.init;}
		alsaerrCode = snd_pcm_sw_params(pcmHandle, swparams);
		if (alsaerrCode) {errCode = StreamInitializationStatus.UnsupportedFormat; return AudioSpecs.init;}
		//snd_pcm_nonblock(pcmHandle, 0);
		return _specs = reqSpecs;
	}

	override public OutputStream createOutputStream() {
		alsaerrCode = snd_pcm_prepare(pcmHandle);
		if (alsaerrCode) {
			errCode = StreamInitializationStatus.Unknown;
			return null; // TODO: Implement better error-handling
		} else {
			return new ALSAOutStream(this);
		}
	}
}
/**
 * Implements an ALSA output stream.
 */
public class ALSAOutStream : OutputStream {
	/// Due to how ALSA works, the pcm handle is accessed from there directly, also keeps a reference of it to avoid
	/// calling the destructor.
	protected ALSADevice		dev;
	/// Buffer for outputting audio data.
	protected ubyte[]			buffer;
	/// Contains buffer size in samples.
	protected uint				bufferSize;
	/// Contains the last ALSA specific error code.
	public int					alsaerrCode;

	package this (ALSADevice dev) {
		this.dev = dev;
		buffer.length = (dev.specs().bufferSize_slmp * dev.specs().bits * dev.specs().outputChannels) / 8;
		this.bufferSize = dev.specs().bufferSize_slmp;
	}
	~this() {
		
	}
	protected void audioThread() @nogc nothrow {
		snd_pcm_sframes_t currBufferSize;
		while (statusCode & StatusFlags.IsRunning) {
			callback_buffer(buffer);
			do {
				currBufferSize = snd_pcm_writei(dev.pcmHandle, cast(const(void*))buffer.ptr, bufferSize);
				if (currBufferSize < 0) {
					errCode = StreamRuntimeStatus.Unknown;
					return;
				}
			} while (currBufferSize < bufferSize && statusCode & StatusFlags.IsRunning);
			alsaerrCode = snd_pcm_wait(dev.pcmHandle, 1000);
			if (!alsaerrCode) {
				statusCode |= StatusFlags.BufferUnderrun;
			}
		}
	}
	override public int runAudioThread() @nogc nothrow {
		if (callback_buffer is null) return errCode = StreamRuntimeStatus.BufferCallbackNotSet;
		alsaerrCode = snd_pcm_start(dev.pcmHandle);
		if (alsaerrCode) {
			return errCode = StreamRuntimeStatus.Unknown;
		}
		statusCode |= StatusFlags.IsRunning;
		_threadID = createLowLevelThread(&audioThread);
		return errCode = StreamRuntimeStatus.AllOk;
	}

	override public int suspendAudioThread() @nogc nothrow {
		alsaerrCode = snd_pcm_drain(dev.pcmHandle);
		statusCode &= ~StatusFlags.IsRunning;
		return errCode;
	}
}