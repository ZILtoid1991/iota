module iota.audio.backend.linux;

version (linux):

import core.stdc.stdint;
import core.stdc.config;
import core.stdc.time;


// Begining of ALSA bindings (most done by Adam D. Ruppe)
// Minimal, only needed functions have bindings.

extern(C):

@nogc nothrow:

pragma(lib, "asound");

private import core.sys.posix.poll;


const(char)* snd_strerror(int);

// ctl

enum snd_ctl_elem_iface_t {
	SND_CTL_ELEM_IFACE_CARD,
	SND_CTL_ELEM_IFACE_HWDEP,
	SND_CTL_ELEM_IFACE_MIXER,
	SND_CTL_ELEM_IFACE_PCM,
	SND_CTL_ELEM_IFACE_RAWMIDI,
	SND_CTL_ELEM_IFACE_TIMER,
	SND_CTL_ELEM_IFACE_SEQUENCER,
}

enum snd_ctl_elem_type_t {
	SND_CTL_ELEM_TYPE_NONE,
	SND_CTL_ELEM_TYPE_BOOLEAN,
	SND_CTL_ELEM_TYPE_INTEGER,
	SND_CTL_ELEM_TYPE_ENUMERATED,
	SND_CTL_ELEM_TYPE_BYTES,
	SND_CTL_ELEM_TYPE_IEC958,
	SND_CTL_ELEM_TYPE_INTEGER64,
}

struct snd_ctl_t {}
struct snd_sctl_t {}
struct snd_ctl_card_info_t {}

int snd_card_get_name(int card, char** name);
int snd_card_load(int card);
int snd_card_next(int* rcard);
int snd_ctl_open(snd_ctl_t** ctlp, const (char*) name, int mode);
int snd_ctl_close(snd_ctl_t* ctl);
int snd_ctl_card_info(snd_ctl_t* ctl, snd_ctl_card_info_t* info);
void snd_ctl_card_info_clear(snd_ctl_card_info_t* obj);

// pcm

enum snd_pcm_stream_t {
	SND_PCM_STREAM_PLAYBACK,
	SND_PCM_STREAM_CAPTURE
}


enum snd_pcm_access_t {
	/** mmap access with simple interleaved channels */ 
	SND_PCM_ACCESS_MMAP_INTERLEAVED = 0, 
	/** mmap access with simple non interleaved channels */ 
	SND_PCM_ACCESS_MMAP_NONINTERLEAVED, 
	/** mmap access with complex placement */ 
	SND_PCM_ACCESS_MMAP_COMPLEX, 
	/** snd_pcm_readi/snd_pcm_writei access */ 
	SND_PCM_ACCESS_RW_INTERLEAVED, 
	/** snd_pcm_readn/snd_pcm_writen access */ 
	SND_PCM_ACCESS_RW_NONINTERLEAVED, 
	SND_PCM_ACCESS_LAST = SND_PCM_ACCESS_RW_NONINTERLEAVED
}


enum snd_pcm_format {
	/** Unknown */
	SND_PCM_FORMAT_UNKNOWN = -1,
	/** Signed 8 bit */
	SND_PCM_FORMAT_S8 = 0,
	/** Unsigned 8 bit */
	SND_PCM_FORMAT_U8,
	/** Signed 16 bit Little Endian */
	SND_PCM_FORMAT_S16_LE,
	/** Signed 16 bit Big Endian */
	SND_PCM_FORMAT_S16_BE,
	/** Unsigned 16 bit Little Endian */
	SND_PCM_FORMAT_U16_LE,
	/** Unsigned 16 bit Big Endian */
	SND_PCM_FORMAT_U16_BE,
	/** Signed 24 bit Little Endian using low three bytes in 32-bit word */
	SND_PCM_FORMAT_S24_LE,
	/** Signed 24 bit Big Endian using low three bytes in 32-bit word */
	SND_PCM_FORMAT_S24_BE,
	/** Unsigned 24 bit Little Endian using low three bytes in 32-bit word */
	SND_PCM_FORMAT_U24_LE,
	/** Unsigned 24 bit Big Endian using low three bytes in 32-bit word */
	SND_PCM_FORMAT_U24_BE,
	/** Signed 32 bit Little Endian */
	SND_PCM_FORMAT_S32_LE,
	/** Signed 32 bit Big Endian */
	SND_PCM_FORMAT_S32_BE,
	/** Unsigned 32 bit Little Endian */
	SND_PCM_FORMAT_U32_LE,
	/** Unsigned 32 bit Big Endian */
	SND_PCM_FORMAT_U32_BE,
	/** Float 32 bit Little Endian, Range -1.0 to 1.0 */
	SND_PCM_FORMAT_FLOAT_LE,
	/** Float 32 bit Big Endian, Range -1.0 to 1.0 */
	SND_PCM_FORMAT_FLOAT_BE,
	/** Float 64 bit Little Endian, Range -1.0 to 1.0 */
	SND_PCM_FORMAT_FLOAT64_LE,
	/** Float 64 bit Big Endian, Range -1.0 to 1.0 */
	SND_PCM_FORMAT_FLOAT64_BE,
	/** IEC-958 Little Endian */
	SND_PCM_FORMAT_IEC958_SUBFRAME_LE,
	/** IEC-958 Big Endian */
	SND_PCM_FORMAT_IEC958_SUBFRAME_BE,
	/** Mu-Law */
	SND_PCM_FORMAT_MU_LAW,
	/** A-Law */
	SND_PCM_FORMAT_A_LAW,
	/** Ima-ADPCM */
	SND_PCM_FORMAT_IMA_ADPCM,
	/** MPEG */
	SND_PCM_FORMAT_MPEG,
	/** GSM */
	SND_PCM_FORMAT_GSM,
	/** Special */
	SND_PCM_FORMAT_SPECIAL = 31,
	/** Signed 24bit Little Endian in 3bytes format */
	SND_PCM_FORMAT_S24_3LE = 32,
	/** Signed 24bit Big Endian in 3bytes format */
	SND_PCM_FORMAT_S24_3BE,
	/** Unsigned 24bit Little Endian in 3bytes format */
	SND_PCM_FORMAT_U24_3LE,
	/** Unsigned 24bit Big Endian in 3bytes format */
	SND_PCM_FORMAT_U24_3BE,
	/** Signed 20bit Little Endian in 3bytes format */
	SND_PCM_FORMAT_S20_3LE,
	/** Signed 20bit Big Endian in 3bytes format */
	SND_PCM_FORMAT_S20_3BE,
	/** Unsigned 20bit Little Endian in 3bytes format */
	SND_PCM_FORMAT_U20_3LE,
	/** Unsigned 20bit Big Endian in 3bytes format */
	SND_PCM_FORMAT_U20_3BE,
	/** Signed 18bit Little Endian in 3bytes format */
	SND_PCM_FORMAT_S18_3LE,
	/** Signed 18bit Big Endian in 3bytes format */
	SND_PCM_FORMAT_S18_3BE,
	/** Unsigned 18bit Little Endian in 3bytes format */
	SND_PCM_FORMAT_U18_3LE,
	/** Unsigned 18bit Big Endian in 3bytes format */
	SND_PCM_FORMAT_U18_3BE,
	/* G.723 (ADPCM) 24 kbit/s, 8 samples in 3 bytes */
	SND_PCM_FORMAT_G723_24,
	/* G.723 (ADPCM) 24 kbit/s, 1 sample in 1 byte */
	SND_PCM_FORMAT_G723_24_1B,
	/* G.723 (ADPCM) 40 kbit/s, 8 samples in 3 bytes */
	SND_PCM_FORMAT_G723_40,
	/* G.723 (ADPCM) 40 kbit/s, 1 sample in 1 byte */
	SND_PCM_FORMAT_G723_40_1B,
	/* Direct Stream Digital (DSD) in 1-byte samples (x8) */
	SND_PCM_FORMAT_DSD_U8,
	/* Direct Stream Digital (DSD) in 2-byte samples (x16) */
	SND_PCM_FORMAT_DSD_U16_LE,
	SND_PCM_FORMAT_LAST = SND_PCM_FORMAT_DSD_U16_LE,
	// I snipped a bunch of endian-specific ones!
}

struct snd_pcm_t {}

struct snd_pcm_hw_params_t {}

struct snd_pcm_sw_params_t {}

int snd_pcm_open(snd_pcm_t**, const(char)*, snd_pcm_stream_t, int);
int snd_pcm_close(snd_pcm_t*);
int snd_pcm_pause(snd_pcm_t*, int);
int	snd_pcm_start(snd_pcm_t *pcm);
int snd_pcm_drain(snd_pcm_t *pcm);
int snd_pcm_prepare(snd_pcm_t*);
int snd_pcm_nonblock(snd_pcm_t* pcm, int nonblock);
int snd_pcm_hw_params(snd_pcm_t*, snd_pcm_hw_params_t*);
int snd_pcm_hw_params_set_periods(snd_pcm_t*, snd_pcm_hw_params_t*, uint, int);
int snd_pcm_hw_params_set_periods_near(snd_pcm_t*, snd_pcm_hw_params_t*, uint*, int);
int snd_pcm_hw_params_set_buffer_size(snd_pcm_t*, snd_pcm_hw_params_t*, snd_pcm_uframes_t);
int snd_pcm_hw_params_set_buffer_size_near(snd_pcm_t*, snd_pcm_hw_params_t*, snd_pcm_uframes_t*);
int snd_pcm_hw_params_set_channels(snd_pcm_t*, snd_pcm_hw_params_t*, uint);
int snd_pcm_hw_params_malloc(snd_pcm_hw_params_t**);
void snd_pcm_hw_params_free(snd_pcm_hw_params_t*);
int snd_pcm_hw_params_any(snd_pcm_t*, snd_pcm_hw_params_t*);
int snd_pcm_hw_params_set_access(snd_pcm_t*, snd_pcm_hw_params_t*, snd_pcm_access_t);
int snd_pcm_hw_params_set_format(snd_pcm_t*, snd_pcm_hw_params_t*, snd_pcm_format);
int snd_pcm_hw_params_set_rate_near(snd_pcm_t*, snd_pcm_hw_params_t*, uint*, int*);
int snd_pcm_hw_params_get_channels_max 	(const (snd_pcm_hw_params_t)* params, uint* val);
int snd_pcm_sw_params_malloc(snd_pcm_sw_params_t**);
void snd_pcm_sw_params_free(snd_pcm_sw_params_t*);
int snd_pcm_sw_params_current(snd_pcm_t *pcm, snd_pcm_sw_params_t *params);
int snd_pcm_sw_params(snd_pcm_t *pcm, snd_pcm_sw_params_t *params);
int snd_pcm_sw_params_set_avail_min(snd_pcm_t*, snd_pcm_sw_params_t*, snd_pcm_uframes_t);
int snd_pcm_sw_params_set_start_threshold(snd_pcm_t*, snd_pcm_sw_params_t*, snd_pcm_uframes_t);
int snd_pcm_sw_params_set_stop_threshold(snd_pcm_t*, snd_pcm_sw_params_t*, snd_pcm_uframes_t);

alias snd_pcm_sframes_t = c_long;
alias snd_pcm_uframes_t = c_ulong;
snd_pcm_sframes_t snd_pcm_writei(snd_pcm_t*, const void*, snd_pcm_uframes_t size);
snd_pcm_sframes_t snd_pcm_readi(snd_pcm_t*, void*, snd_pcm_uframes_t size);

int snd_pcm_wait(snd_pcm_t *pcm, int timeout);
snd_pcm_sframes_t snd_pcm_avail(snd_pcm_t *pcm);
snd_pcm_sframes_t snd_pcm_avail_update(snd_pcm_t *pcm);

const(char)* snd_strerror(int errnum);

int snd_pcm_recover (snd_pcm_t* pcm, int err, int silent);

alias snd_lib_error_handler_t = void function (const(char)* file, int line, const(char)* function_, int err, const(char)* fmt, ...);
int snd_lib_error_set_handler (snd_lib_error_handler_t handler);

import core.stdc.stdarg;
private void alsa_message_silencer (const(char)* file, int line, const(char)* function_, int err, const(char)* fmt, ...) {}
//k8: ALSAlib loves to trash stderr; shut it up
void silence_alsa_messages () { snd_lib_error_set_handler(&alsa_message_silencer); }
extern(D) shared static this () { silence_alsa_messages(); }

// raw midi

static if(is(size_t == uint))
	alias ssize_t = int;
else
	alias ssize_t = long;


//struct snd_rawmidi_t {}
//int snd_rawmidi_open(snd_rawmidi_t**, snd_rawmidi_t**, const(char)*, int);
//int snd_rawmidi_close(snd_rawmidi_t*);
//int snd_rawmidi_drain(snd_rawmidi_t*);
//ssize_t snd_rawmidi_write(snd_rawmidi_t*, const void*, size_t);
//ssize_t snd_rawmidi_read(snd_rawmidi_t*, void*, size_t);

// mixer

struct snd_mixer_t {}
struct snd_mixer_elem_t {}
struct snd_mixer_selem_id_t {}

alias snd_mixer_elem_callback_t = int function(snd_mixer_elem_t*, uint);

int snd_mixer_open(snd_mixer_t**, int mode);
int snd_mixer_close(snd_mixer_t*);
int snd_mixer_attach(snd_mixer_t*, const(char)*);
int snd_mixer_load(snd_mixer_t*);

// FIXME: those aren't actually void*
int snd_mixer_selem_register(snd_mixer_t*, void*, void*);
int snd_mixer_selem_id_malloc(snd_mixer_selem_id_t**);
void snd_mixer_selem_id_free(snd_mixer_selem_id_t*);
void snd_mixer_selem_id_set_index(snd_mixer_selem_id_t*, uint);
void snd_mixer_selem_id_set_name(snd_mixer_selem_id_t*, const(char)*);
snd_mixer_elem_t* snd_mixer_find_selem(snd_mixer_t*, snd_mixer_selem_id_t*);
// FIXME: the int should be an enum for channel identifier
int snd_mixer_selem_get_playback_volume(snd_mixer_elem_t*, int, c_long*);
int snd_mixer_selem_get_playback_volume_range(snd_mixer_elem_t*, c_long*, c_long*);

int snd_mixer_selem_set_playback_volume_all(snd_mixer_elem_t*, c_long);

void snd_mixer_elem_set_callback(snd_mixer_elem_t*, snd_mixer_elem_callback_t);
int snd_mixer_poll_descriptors(snd_mixer_t*, pollfd*, uint space);

int snd_mixer_handle_events(snd_mixer_t*);

// FIXME: the first int should be an enum for channel identifier
int snd_mixer_selem_get_playback_switch(snd_mixer_elem_t*, int, int* value);
int snd_mixer_selem_set_playback_switch_all(snd_mixer_elem_t*, int);
int snd_device_name_hint (int card, const(char)* iface, void*** hints);
int snd_device_name_free_hint (void** hints);
char* snd_device_name_get_hint (const void* hint, const(char)* id);
// rawmidi API
enum snd_rawmidi_stream_t { 
	SND_RAWMIDI_STREAM_OUTPUT = 0 , SND_RAWMIDI_STREAM_INPUT , SND_RAWMIDI_STREAM_LAST = SND_RAWMIDI_STREAM_INPUT 
}
 
enum snd_rawmidi_type_t { 
	SND_RAWMIDI_TYPE_HW , SND_RAWMIDI_TYPE_SHM , SND_RAWMIDI_TYPE_INET , SND_RAWMIDI_TYPE_VIRTUAL 
}
 
enum snd_rawmidi_clock_t { 
	SND_RAWMIDI_CLOCK_NONE = 0 , SND_RAWMIDI_CLOCK_REALTIME = 1 , SND_RAWMIDI_CLOCK_MONOTONIC = 2 , 
	SND_RAWMIDI_CLOCK_MONOTONIC_RAW = 3 
}
 
enum snd_rawmidi_read_mode_t { SND_RAWMIDI_READ_STANDARD = 0 , SND_RAWMIDI_READ_TSTAMP = 1 }

struct snd_rawmidi_info_t {}
struct snd_rawmidi_params_t {}
struct snd_rawmidi_status_t {}
struct snd_rawmidi_t {}

int snd_rawmidi_open (snd_rawmidi_t** in_rmidi, snd_rawmidi_t** out_rmidi, const(char)* name, int mode);
/+int snd_rawmidi_open_lconf (snd_rawmidi_t** in_rmidi, snd_rawmidi_t** out_rmidi, const(char)* name, int mode, 
		snd_config_t* lconf);+/
int snd_rawmidi_close (snd_rawmidi_t* rmidi);
int snd_rawmidi_poll_descriptors_count (snd_rawmidi_t* rmidi); 
//int snd_rawmidi_poll_descriptors (snd_rawmidi_t* rmidi, pollfd* pfds, uint space);
//int snd_rawmidi_poll_descriptors_revents (snd_rawmidi_t* rawmidi, pollfd* pfds, uint nfds, ushort* revent);
int snd_rawmidi_nonblock (snd_rawmidi_t* rmidi, int nonblock);
size_t snd_rawmidi_info_sizeof ();
int snd_rawmidi_info_malloc (snd_rawmidi_info_t** ptr);
void snd_rawmidi_info_free (snd_rawmidi_info_t* obj);
void snd_rawmidi_info_copy (snd_rawmidi_info_t* dst, const(snd_rawmidi_info_t)* src);
uint snd_rawmidi_info_get_device (const(snd_rawmidi_info_t)* obj);
uint snd_rawmidi_info_get_subdevice (const(snd_rawmidi_info_t)* obj);
snd_rawmidi_stream_t snd_rawmidi_info_get_stream (const(snd_rawmidi_info_t)* obj);
int snd_rawmidi_info_get_card (const(snd_rawmidi_info_t)* obj);
uint snd_rawmidi_info_get_flags (const(snd_rawmidi_info_t)* obj);
const(char)* snd_rawmidi_info_get_id (const(snd_rawmidi_info_t)* obj);
const(char)* snd_rawmidi_info_get_name (const(snd_rawmidi_info_t)* obj);
const(char)* snd_rawmidi_info_get_subdevice_name (const(snd_rawmidi_info_t)* obj);
uint snd_rawmidi_info_get_subdevices_count (const(snd_rawmidi_info_t)* obj);
uint snd_rawmidi_info_get_subdevices_avail (const(snd_rawmidi_info_t)* obj);
void snd_rawmidi_info_set_device (snd_rawmidi_info_t* obj, uint val);
void snd_rawmidi_info_set_subdevice (snd_rawmidi_info_t* obj, uint val);
void snd_rawmidi_info_set_stream (snd_rawmidi_info_t* obj, snd_rawmidi_stream_t val);
int snd_rawmidi_info (snd_rawmidi_t* rmidi, snd_rawmidi_info_t* info);
size_t snd_rawmidi_params_sizeof ();
int snd_rawmidi_params_malloc (snd_rawmidi_params_t** ptr);
void snd_rawmidi_params_free (snd_rawmidi_params_t* obj);
void snd_rawmidi_params_copy (snd_rawmidi_params_t* dst, const snd_rawmidi_params_t* src);
int snd_rawmidi_params_set_buffer_size (snd_rawmidi_t* rmidi, snd_rawmidi_params_t* params, size_t val);
size_t snd_rawmidi_params_get_buffer_size (const(snd_rawmidi_params_t)* params);
int snd_rawmidi_params_set_avail_min (snd_rawmidi_t* rmidi, snd_rawmidi_params_t* params, size_t val);
size_t snd_rawmidi_params_get_avail_min (const(snd_rawmidi_params_t)* params);
int snd_rawmidi_params_set_no_active_sensing (snd_rawmidi_t* rmidi, snd_rawmidi_params_t* params, int val);
int snd_rawmidi_params_get_no_active_sensing (const(snd_rawmidi_params_t)* params);
int snd_rawmidi_params_set_read_mode (const snd_rawmidi_t* rawmidi, snd_rawmidi_params_t* params, snd_rawmidi_read_mode_t val);
snd_rawmidi_read_mode_t snd_rawmidi_params_get_read_mode (const(snd_rawmidi_params_t)* params);
int snd_rawmidi_params_set_clock_type (const snd_rawmidi_t* rawmidi, snd_rawmidi_params_t* params, snd_rawmidi_clock_t val);
snd_rawmidi_clock_t snd_rawmidi_params_get_clock_type (const(snd_rawmidi_params_t)* params);
int snd_rawmidi_params (snd_rawmidi_t* rmidi, snd_rawmidi_params_t* params);
int snd_rawmidi_params_current (snd_rawmidi_t* rmidi, snd_rawmidi_params_t* params);
size_t snd_rawmidi_status_sizeof ();
int snd_rawmidi_status_malloc (snd_rawmidi_status_t** ptr);
void snd_rawmidi_status_free (snd_rawmidi_status_t* obj);
void snd_rawmidi_status_copy (snd_rawmidi_status_t* dst, const(snd_rawmidi_status_t)* src);
//void snd_rawmidi_status_get_tstamp (const(snd_rawmidi_status_t)* obj, snd_htimestamp_t *ptr);
size_t snd_rawmidi_status_get_avail (const(snd_rawmidi_status_t)* obj);
size_t snd_rawmidi_status_get_xruns (const(snd_rawmidi_status_t)* obj);
int snd_rawmidi_status (snd_rawmidi_t* rmidi, snd_rawmidi_status_t* status);
int snd_rawmidi_drain (snd_rawmidi_t* rmidi);
int snd_rawmidi_drop (snd_rawmidi_t* rmidi);
ssize_t snd_rawmidi_write (snd_rawmidi_t* rmidi, const void *buffer, size_t size);
ssize_t snd_rawmidi_read (snd_rawmidi_t* rmidi, void *buffer, size_t size);
//ssize_t snd_rawmidi_tread (snd_rawmidi_t* rmidi, timespec *tstamp, void *buffer, size_t size);
const(char)* snd_rawmidi_name (snd_rawmidi_t* rmidi);
snd_rawmidi_type_t snd_rawmidi_type (snd_rawmidi_t* rmidi);
snd_rawmidi_stream_t snd_rawmidi_stream (snd_rawmidi_t* rawmidi);
// End of ALSA bindings
