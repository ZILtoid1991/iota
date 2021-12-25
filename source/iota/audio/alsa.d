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
		snd_pcm_hw_params_set_access(pcmHandle, pcmParams,  snd_pcm_access_t.ND_PCM_ACCESS_RW_INTERLEAVED);
		switch (reqSpecs.format.bits) {
			case 0x08:
				switch (reqSpecs.format.flags & SampleFormat.Flag.Type_Test) {
					case SampleFormat.Flag.Type_Unsigned:
						snd_pcm_hw_params_set_format(pcmHandle, pcmParams, snd_pcm_format.SND_PCM_FORMAT_U8);
						break;
					case SampleFormat.Flag.Type_Signed:
						snd_pcm_hw_params_set_format(pcmHandle, pcmParams, snd_pcm_format.SND_PCM_FORMAT_S8);
						break;
					default:
						return AudioSpecs.init;
				}
				break;
			case 0x10:
				switch (reqSpecs.format.flags & SampleFormat.Flag.Type_Test) {
					case SampleFormat.Flag.Type_Unsigned:
						snd_pcm_hw_params_set_format(pcmHandle, pcmParams, snd_pcm_format.SND_PCM_FORMAT_U16_LE);
						break;
					case SampleFormat.Flag.Type_Signed:
						snd_pcm_hw_params_set_format(pcmHandle, pcmParams, snd_pcm_format.SND_PCM_FORMAT_S16_LE);
						break;
					default:
						return AudioSpecs.init;
				}
				break;
			case 0x18:
				switch (reqSpecs.format.flags & SampleFormat.Flag.Type_Test) {
					case SampleFormat.Flag.Type_Unsigned:
						snd_pcm_hw_params_set_format(pcmHandle, pcmParams, snd_pcm_format.SND_PCM_FORMAT_U24_LE);
						break;
					case SampleFormat.Flag.Type_Signed:
						snd_pcm_hw_params_set_format(pcmHandle, pcmParams, snd_pcm_format.SND_PCM_FORMAT_S24_LE);
						break;
					default:
						return AudioSpecs.init;
				}
				break;
			case 0x20:
				switch (reqSpecs.format.flags & SampleFormat.Flag.Type_Test) {
					case SampleFormat.Flag.Type_Float:
						snd_pcm_hw_params_set_format(pcmHandle, pcmParams, snd_pcm_format.SND_PCM_FORMAT_FLOAT_LE);
						break;
					case SampleFormat.Flag.Type_Unsigned:
						snd_pcm_hw_params_set_format(pcmHandle, pcmParams, snd_pcm_format.SND_PCM_FORMAT_U32_LE);
						break;
					case SampleFormat.Flag.Type_Signed:
						snd_pcm_hw_params_set_format(pcmHandle, pcmParams, snd_pcm_format.SND_PCM_FORMAT_S32_LE);
						break;
					default:
						return AudioSpecs.init;
				}
				break;
			default: 
				return AudioSpecs.init;
		}
		snd_pcm_hw_params_set_channels(pcmHandle, pcmParams, reqSpecs.outputChannels);
		snd_pcm_hw_params_set_rate_near(pcmHandle, pcmParams, cast(uint*)reqSpecs.sampleRate, 0);
		snd_pcm_uframes_t bufferlen = reqSpecs.bufferSize_slmp;
		snd_pcm_hw_params_set_buffer_size_near(pcmHandle, pcmParams, &bufferlen);
		reqSpecs.bufferSize_slmp = bufferlen;
		return _specs = reqSpecs;
	}

	override public OutputStream createOutputStream() {
		alsaerrCode = snd_pcm_prepare(pcmHandle);
		if (alsaerrCode)
			return OutputStream.init; // TODO: Implement better error-handling
		else
			return new OutputStream(this);
	}
}
/**
 * Implements an ALSA output stream.
 */
public class ALSAOutStream : OutputStream {
	/// Due to how ALSA works, the pcm handle is accessed from there directly, also keeps a reference of it to avoid
	/// calling the destructor.
	protected ALSADevice		dev;

	package this (ALSADevice dev) {
		this.dev = dev;
	}
	~this() {
		
	}
	protected void audioThread() @nogc nothrow {
		while (statusCode & StatusFlags.IsRunning) {

		}
	}
	override public int runAudioThread() @nogc nothrow {
		if (callback_buffer is null) return StreamRuntimeStatus.BufferCallbackNotSet;
		statusCode |= StatusFlags.IsRunning;
		_threadID = createLowLevelThread(&audioThread);
		return StreamRuntimeStatus.AllOk;
	}

	override public int suspendAudioThread() @nogc nothrow {
		statusCode &= ~StatusFlags.IsRunning;
		return StreamRuntimeStatus.AllOk; // TODO: implement
	}
}