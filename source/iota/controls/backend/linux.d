module iota.controls.backend.linux;

version(linux):

import core.sys.posix.sys.time;
import core.sys.posix.sys.ioctl;
import core.sys.posix.sys.types;
import core.stdc.stdarg;

static enum O_NONBLOCK				=	0x0000_4000;
static enum O_RDWR					=	0x0000_0002;
static enum O_READONLY				=	0x0000_0000;
static enum EVDEV_FIRST_GC_BTN		=	0x130;
static enum EVDEV_FIRST_HAT			=	0x10;

static enum INPUT_PROP_POINTER		=	0x00;	/* needs a pointer */
static enum INPUT_PROP_DIRECT		=	0x01;	/* direct input devices */
static enum INPUT_PROP_BUTTONPAD	=	0x02;	/* has button(s) under pad */
static enum INPUT_PROP_SEMI_MT		=	0x03;	/* touch rectangle only */
static enum INPUT_PROP_TOPBUTTONPAD	=	0x04;	/* softbuttons at top of pad */
static enum INPUT_PROP_POINTING_STICK=	0x05;	/* is a pointing stick */
static enum INPUT_PROP_ACCELEROMETER=	0x06;	/* has accelerometer */

static enum INPUT_PROP_MAX			=	0x1f;
static enum INPUT_PROP_CNT			=	(INPUT_PROP_MAX + 1);

static enum EV_SYN					=	0x00;
static enum EV_KEY					=	0x01;
static enum EV_REL					=	0x02;
static enum EV_ABS					=	0x03;
static enum EV_MSC					=	0x04;
static enum EV_SW					=	0x05;
static enum EV_LED					=	0x11;
static enum EV_SND					=	0x12;
static enum EV_REP					=	0x14;
static enum EV_FF					=	0x15;
static enum EV_PWR					=	0x16;
static enum EV_FF_STATUS			=	0x17;
static enum EV_MAX					=	0x1f;
static enum EV_CNT					=	(EV_MAX+1);

static enum SYN_REPORT				=	0;
static enum SYN_CONFIG				=	1;
static enum SYN_MT_REPORT			=	2;
static enum SYN_DROPPED				=	3;
static enum SYN_MAX					=	0xf;
static enum SYN_CNT					=	(SYN_MAX+1);

static enum ABS_MT_SLOT				=	0x2f;
static enum ABS_MT_POSITION_X		=	0x35;
static enum ABS_MT_POSITION_Y		=	0x36;
static enum ABS_MT_TRACKING_ID		=	0x39;
static enum ABS_MT_PRESSURE			=	0x3a;

extern(C) @nogc nothrow:

struct input_event {
	/* static if(size_t.sizeof != 4) { */
	timeval		time;
	/* } else {
		ulong_t		__sec;
		ulong_t		__usec;
	} */
	ushort		type;
	ushort		code;
	int			value;
}

struct input_id {
	ushort		bustype;
	ushort		vendor;
	ushort		product;
	ushort		_version;
}

struct input_absinfo {
	int			value;
	int			minimum;
	int			maximum;
	int			fuzz;
	int			flat;
	int			resolution;
}

struct input_keymap_entry {
	ubyte		flags;
	ubyte		len;
	ushort		index;
	uint		keycode;
	ubyte[32]	scancode;
}

struct input_mask {
	uint		type;
	uint		codes_size;
	ulong		codes_ptr;
}

struct ff_replay {
	ushort		length;
	ushort		delay;
}

struct ff_trigger {
	ushort		button;
	ushort		interval;
}

struct ff_envelope {
	ushort		attack_length;
	ushort		attack_level;
	ushort		fade_length;
	ushort		fade_level;
}

struct ff_constant_effect {
	short		level;
	ff_envelope	envelope;
}

struct ff_ramp_effect {
	short		start_level;
	short		end_level;
	ff_envelope	envelope;
}

struct ff_condition_effect {
	ushort		right_saturation;
	ushort		left_saturation;

	short		right_coeff;
	short		left_coeff;

	ushort		deadband;
	short		center;
}

struct ff_periodic_effect {
	ushort		waveform;
	ushort		period;
	short		magnitude;
	short		offset;
	ushort		phase;

	ff_envelope	envelope;

	uint		custom_len;
	short*		custom_data;
}

struct ff_rumble_effect {
	ushort		strong_magnitude;
	ushort		weak_magnitude;
}

struct ff_effect {
	ushort		type;
	short		id;
	ushort		direction;
	ff_trigger	trigger;
	ff_replay	replay;

	union U {
		ff_constant_effect constant;
		ff_ramp_effect ramp;
		ff_periodic_effect periodic;
		ff_condition_effect[2] condition; /* One for each axis */
		ff_rumble_effect rumble;
	}
	U u;
}

enum EvdevMouseButtons {
	LEFT		=	0x110,
	RIGHT		=	0x111,
	MIDDLE		=	0x112,
	SIDE		=	0x113,
	EXTRA		=	0x114,
	FORWARD		=	0x115,
	BACK		=	0x116,
	TASK		=	0x117,
}

enum EvdevGamepadButtons {
	SOUTH		=	0x130,
	A			=	SOUTH,
	EAST		=	0x131,
	B			=	EAST,
	C			=	0x132,
	NORTH		=	0x133,
	X			=	NORTH,
	WEST		=	0x134,
	Y			=	WEST,
	Z			=	0x135,
	TL			=	0x136,
	TR			=	0x137,
	TL2			=	0x138,
	TR2			=	0x139,
	SELECT		=	0x13a,
	START		=	0x13b,
	MODE		=	0x13c,
	THUMBL		=	0x13d,
	THUMBR		=	0x13e,
}

enum EvdevRelAxes {
	X			=	0x00,
	Y			=	0x01,
	Z			=	0x02,
	RX			=	0x03,
	RY			=	0x04,
	RZ			=	0x05,
	HWHEEL		=	0x06,
	DIAL		=	0x07,
	WHEEL		=	0x08,
	MISC		=	0x09,
	MAX			=	0x0f,
	CNT			=	MAX + 1
}

enum EvdevAbsAxes {
	X			=	0x00,
	Y			=	0x01,
	Z			=	0x02,
	RX			=	0x03,
	RY			=	0x04,
	RZ			=	0x05,
	THROTTLE	=	0x06,
	RUDDER		=	0x07,
	WHEEL		=	0x08,
	GAS			=	0x09,
	BRAKE		=	0x0a,
	HAT0X		=	0x10,
	HAT0Y		=	0x11,
	HAT1X		=	0x12,
	HAT1Y		=	0x13,
	HAT2X		=	0x14,
	HAT2Y		=	0x15,
	HAT3X		=	0x16,
	HAT3Y		=	0x17,
	PRESSURE	=	0x18,
	DISTANCE	=	0x19,
	TILT_X		=	0x1a,
	TILT_Y		=	0x1b,
	TOOL_WIDTH	=	0x1c,
}

static enum FF_RUMBLE		=	0x50;
static enum FF_PERIODIC		=	0x51;
static enum FF_CONSTANT		=	0x52;
static enum FF_SPRING		=	0x53;
static enum FF_FRICTION		=	0x54;
static enum FF_DAMPER		=	0x55;
static enum FF_INERTIA		=	0x56;
static enum FF_RAMP			=	0x57;

struct uinput_ff_upload {
	uint		request_id;
	int			retval;
	ff_effect	effect;
	ff_effect	old;
}

struct uinput_ff_erase {
	uint		request_id;
	int			retval;
	uint		effect_id;
}

struct uinput_setup {
	input_id	id;
	char[80]	name;
	uint		ff_effects_max;
}

struct uinput_abs_setup {
	ushort		code; /* axis code */
	/* ushort filler; */
	input_absinfo absinfo;
}

struct uinput_user_dev {
	char[80]	name;
	input_id	id;
	uint		ff_effects_max;
	int[0x40] absmax;
	int[0x40] absmin;
	int[0x40] absfuzz;
	int[0x40] absflat;
}

struct libevdev {}

enum libevdev_read_flag : ubyte {
	LIBEVDEV_READ_FLAG_SYNC			= 1, /**< Process data in sync mode */
	LIBEVDEV_READ_FLAG_NORMAL		= 2, /**< Process data in normal mode */
	LIBEVDEV_READ_FLAG_FORCE_SYNC	= 4, /**< Pretend the next event is a SYN_DROPPED andrequire the caller to sync */
	LIBEVDEV_READ_FLAG_BLOCKING		= 8  /**< The fd is not in O_NONBLOCK and a read may block */
}

libevdev* libevdev_new();
int libevdev_new_from_fd(int fd, libevdev** dev);
void libevdev_free(libevdev* dev);
enum libevdev_log_priority {
	LIBEVDEV_LOG_ERROR = 10,	/**< critical errors and application bugs */
	LIBEVDEV_LOG_INFO  = 20,	/**< informational messages */
	LIBEVDEV_LOG_DEBUG = 30		/**< debug information */
}
alias libevdev_log_func_t = extern(C) void function(libevdev_log_priority priority, void* data, const(char)* file, 
		int line, const(char)* func, const(char)* format, va_list args);
void libevdev_set_log_function(libevdev_log_func_t logfunc, void* data);
void libevdev_set_log_priority(libevdev_log_priority priority);
libevdev_log_priority libevdev_get_log_priority();
alias libevdev_device_log_func_t = extern(C) void function (const(libevdev)* dev, libevdev_log_priority priority,
		void* data, const(char)* file, int line, const(char)* func, const(char)* format, va_list args);
void libevdev_set_device_log_function(libevdev* dev, libevdev_device_log_func_t logfunc, libevdev_log_priority priority,
		void* data);
enum libevdev_grab_mode {
	LIBEVDEV_GRAB = 3,	/**< Grab the device if not currently grabbed */
	LIBEVDEV_UNGRAB = 4	/**< Ungrab the device if currently grabbed */
}
int libevdev_grab(libevdev* dev, libevdev_grab_mode grab);
int libevdev_set_fd(libevdev* dev, int fd);
int libevdev_change_fd(libevdev* dev, int fd);
int libevdev_get_fd(const libevdev* dev);
enum libevdev_read_status {
	/**
	 * libevdev_next_event() has finished without an error
	 * and an event is available for processing.
	 *
	 * @see libevdev_next_event
	 */
	LIBEVDEV_READ_STATUS_SUCCESS = 0,
	/**
	 * Depending on the libevdev_next_event() read flag:
	 * * libevdev received a SYN_DROPPED from the device, and the caller should
	 * now resync the device, or,
	 * * an event has been read in sync mode.
	 *
	 * @see libevdev_next_event
	 */
	LIBEVDEV_READ_STATUS_SYNC = 1
}
int libevdev_next_event(libevdev* dev, uint flags, input_event* ev);
int libevdev_has_event_pending(libevdev* dev);
const(char)* libevdev_get_name(const(libevdev)* dev);
void libevdev_set_name(libevdev* dev, const(char)* name);
const(char)* libevdev_get_phys(const(libevdev)* dev);
void libevdev_set_phys(libevdev* dev, const(char)* phys);
const(char)* libevdev_get_uniq(const(libevdev)*dev);
void libevdev_set_uniq(libevdev* dev, const(char)* uniq);
int libevdev_get_id_product(const(libevdev)* dev);
void libevdev_set_id_product(libevdev* dev, int product_id);
int libevdev_get_id_vendor(const(libevdev)* dev);
void libevdev_set_id_vendor(libevdev* dev, int vendor_id);
int libevdev_get_id_bustype(const(libevdev)* dev);
void libevdev_set_id_bustype(libevdev* dev, int bustype);
void libevdev_set_id_version(libevdev* dev, int _version);
int libevdev_get_driver_version(const(libevdev)* dev);
int libevdev_has_property(const(libevdev)* dev, uint prop);
int libevdev_enable_property(libevdev* dev, uint prop);
int libevdev_disable_property(libevdev* dev, uint prop);
int libevdev_has_event_type(const(libevdev)* dev, uint type);
int libevdev_has_event_code(const(libevdev)* dev, uint type, uint code);
int libevdev_get_abs_minimum(const(libevdev)* dev, uint code);
int libevdev_get_abs_maximum(const(libevdev)* dev, uint code);
int libevdev_get_abs_fuzz(const(libevdev)* dev, uint code);
int libevdev_get_abs_flat(const(libevdev)* dev, uint code);
int libevdev_get_abs_resolution(const(libevdev)* dev, uint code);
const(input_absinfo)* libevdev_get_abs_info(const(libevdev)* dev, uint code);
int libevdev_get_event_value(const(libevdev)* dev, uint type, uint code);
int libevdev_set_event_value(libevdev* dev, uint type, uint code, int value);
int libevdev_fetch_event_value(const(libevdev)* dev, uint type, uint code, int* value);
int libevdev_get_slot_value(const(libevdev)* dev, uint slot, uint code);
int libevdev_set_slot_value(libevdev* dev, uint slot, uint code, int value);
int libevdev_fetch_slot_value(const(libevdev)* dev, uint slot, uint code, int* value);
int libevdev_get_num_slots(const(libevdev)* dev);
int libevdev_get_current_slot(const(libevdev)* dev);
void libevdev_set_abs_minimum(libevdev* dev, uint code, int val);
void libevdev_set_abs_maximum(libevdev* dev, uint code, int val);
void libevdev_set_abs_fuzz(libevdev* dev, uint code, int val);
void libevdev_set_abs_flat(libevdev* dev, uint code, int val);
void libevdev_set_abs_resolution(libevdev* dev, uint code, int val);
void libevdev_set_abs_info(libevdev* dev, uint code, const(input_absinfo)* abs);
int libevdev_enable_event_type(libevdev* dev, uint type);
int libevdev_disable_event_type(libevdev* dev, uint type);
int libevdev_enable_event_code(libevdev* dev, uint type, uint code, const(void)* data);
int libevdev_disable_event_code(libevdev* dev, uint type, uint code);
int libevdev_kernel_set_abs_info(libevdev* dev, uint code, const(input_absinfo)* abs);
enum libevdev_led_value {
	LIBEVDEV_LED_ON = 3, /**< Turn the LED on */
	LIBEVDEV_LED_OFF = 4 /**< Turn the LED off */
}
int libevdev_kernel_set_led_value(libevdev* dev, uint code, libevdev_led_value value);
int libevdev_kernel_set_led_values(libevdev* dev, ...);
int libevdev_set_clock_id(libevdev* dev, int clockid);
int libevdev_event_is_type(const(input_event)* ev, uint type);
int libevdev_event_is_code(const(input_event)* ev, uint type, uint code);
const(char)* libevdev_event_type_get_name(uint type);
const(char)* libevdev_event_code_get_name(uint type, uint code);
const(char)* libevdev_event_value_get_name(uint type, uint code, int value);
const(char)* libevdev_property_get_name(uint prop);
int libevdev_event_type_get_max(uint type);
int libevdev_event_type_from_name(const(char)* name);
int libevdev_event_type_from_name_n(const(char)* name, size_t len);
int libevdev_event_code_from_name(uint type, const(char)* name);
int libevdev_event_code_from_name_n(uint type, const(char)* name, size_t len);
int libevdev_event_value_from_name(uint type, uint code, const(char)* name);
int libevdev_event_type_from_code_name(const(char)* name);
int libevdev_event_type_from_code_name_n(const(char)* name, size_t len);
int libevdev_event_code_from_code_name(const(char)* name);
int libevdev_event_code_from_code_name_n(const(char)* name, size_t len);
int libevdev_event_value_from_name_n(uint type, uint code, const(char)* name, size_t len);
int libevdev_property_from_name(const(char)* name);
int libevdev_property_from_name_n(const(char)* name, size_t len);
int libevdev_get_repeat(const(libevdev)* dev, int* delay, int* period);

int open(scope const(char)* filename, int flags, ...);
int close(int fd);
sizediff_t read(int fd, void* buf, size_t count);
sizediff_t write(int fd, const(void)* buf, size_t count);
