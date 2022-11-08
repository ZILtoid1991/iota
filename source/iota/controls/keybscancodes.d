module iota.controls.keybscancodes;

/**
 * (Mostly) USB HID compatible keyboard scancodes.
 */
public enum ScanCode : uint {
	init,
	A				=	4,
	B				=	5,
	C				=	6,
	D				=	7,
	E				=	8,
	F				=	9,
	G				=	10,
	H				=	11,
	I				=	12,
	J				=	13,
	K				=	14,
	L				=	15,
	M				=	16,
	N				=	17,
	O				=	18,
	P				=	19,
	Q				=	20,
	R				=	21,
	S				=	22,
	T				=	23,
	U				=	24,
	V				=	25,
	W				=	26,
	X				=	27,
	Y				=	28,
	Z				=	29,

	n1				=	30,
	n2				=	31,
	n3				=	32,
	n4				=	33,
	n5				=	34,
	n6				=	35,
	n7				=	36,
	n8				=	37,
	n9				=	38,
	n0				=	39,

	ENTER			=	40,
	ESCAPE			=	41,
	BACKSPACE		=	42,
	TAB				=	43,
	SPACE			=	44,

	MINUS			=	45,
	EQUALS			=	46,
	LEFTBRACKET		=	47,
	RIGHTBRACKET	=	48,
	BACKSLASH		=	49,
	NONUSHASH		=	50,
	SEMICOLON		=	51,
	APOSTROPHE		=	52,
	GRAVE			=	53,
	COMMA			=	54,
	PERIOD			=	55,
	SLASH			=	56,
	CAPSLOCK		=	57,

	F1				=	58,
	F2				=	59,
	F3				=	60,
	F4				=	61,
	F5				=	62,
	F6				=	63,
	F7				=	64,
	F8				=	65,
	F9				=	66,
	F10				=	67,
	F11				=	68,
	F12				=	69,

	PRINTSCREEN		=	70,
	SCROLLLOCK		=	71,
	PAUSE			=	72,
	INSERT			=	73,
	HOME			=	74,
	PAGEUP			=	75,
	DELETE			=	76,
	END				=	77,
	PAGEDOWN		=	78,
	RIGHT			=	79,
	LEFT			=	80,
	DOWN			=	81,
	UP				=	82,

	NUMLOCK			=	83,
	NP_DIVIDE		=	84,
	NP_MULTIPLY		=	85,
	NP_MINUS		=	86,
	NP_PLUS			=	87,
	NP_ENTER		=	88,

	np1				=	89,
	np2				=	90,
	np3				=	91,
	np4				=	92,
	np5				=	93,
	np6				=	94,
	np7				=	95,
	np8				=	96,
	np9				=	97,
	np0				=	98,

	NP_PERIOD		=	99,

	NONUSBACKSLASH	=	100,
	APPLICATION		=	101,

	NP_EQUALS		=	102,

	F13				=	104,
	F14				=	105,
	F15				=	106,
	F16				=	107,
	F17				=	108,
	F18				=	109,
	F19				=	110,
	F20				=	111,
	F21				=	112,
	F22				=	113,
	F23				=	114,
	F24				=	115,

	EXECUTE			=	116,
	HELP			=	117,
	MENU			=	118,
	SELECT			=	119,
	STOP			=	120,
	REDO			=	121,
	UNDO			=	122,
	CUT				=	123,
	COPY			=	124,
	PASTE			=	125,
	FIND			=	126,
	MUTE			=	127,
	VOLUME_UP		=	128,
	VOLUME_DOWN		=	129,

	NP_COMMA		=	133,
	NP_EQUALSAS400	=	134,

	INTERNATIONAL1	=	135,
	INTERNATIONAL2	=	136,
	INTERNATIONAL3	=	137,
	INTERNATIONAL4	=	138,
	INTERNATIONAL5	=	139,
	INTERNATIONAL6	=	140,
	INTERNATIONAL7	=	141,
	INTERNATIONAL8	=	142,
	INTERNATIONAL9	=	143,

	LANGUAGE1		=	144,
	LANGUAGE2		=	145,
	LANGUAGE3		=	146,
	LANGUAGE4		=	147,
	LANGUAGE5		=	148,
	LANGUAGE6		=	149,
	LANGUAGE7		=	150,
	LANGUAGE8		=	151,
	LANGUAGE9		=	152,

	ALTERASE		=	153,
	SYSREQ			=	154,
	CANCEL			=	155,
	PRIOR			=	157,
	ENTER2			=	158,
	SEPARATOR		=	159,
	OUT				=	160,
	OPERATE			=	161,
	CLEARAGAIN		=	162,
	CRSEL			=	163,
	EXSEL			=	164,

	NP00			=	176,
	NP000			=	177,
	THROUSANDSEPAR	=	178,
	HUNDREDSSEPAR	=	179,
	CURRENCYUNIT	=	180,
	CURRENCYSUBUNIT	=	181,
	NP_LEFTPAREN	=	182,
	NP_RIGHTPAREN	=	183,
	NP_LEFTBRACE	=	184,
	NP_RIGHTBRACE	=	185,
	NP_TAB			=	186,
	NP_BACKSPACE	=	187,
	NP_A			=	188,
	NP_B			=	189,
	NP_C			=	190,
	NP_D			=	191,
	NP_E			=	192,
	NP_F			=	193,
	NP_XOR			=	194,
	NP_POWER		=	195,
	NP_PERCENT		=	196,
	NP_LESS			=	197,
	NP_GREATER		=	198,
	NP_AMPERSAND	=	199,
	NP_DBAMPERSAND	=	200,
	NP_VERTICALBAR	=	201,
	NP_DBVERTICALBAR=	202,
	NP_COLON		=	203,
	NP_HASH			=	204,
	NP_SPACE		=	205,
	NP_AT			=	206,
	NP_EXCLAM		=	207,
	NP_MEMSTORE		=	208,
	NP_MEMRECALL	=	209,
	NP_MEMCLEAR		=	210,
	NP_MEMADD		=	211,
	NP_MEMSUBSTRACT	=	212,
	NP_MEMMULTIPLY	=	213,
	NP_MEMDIVIDE	=	214,
	NP_PLUSMINUS	=	215,
	NP_CLEAR		=	216,
	NP_CLEARENTRY	=	217,
	NP_BINARY		=	218,
	NP_OCTAL		=	219,
	NP_DECIMAL		=	220,
	NP_HEXADECIMAL	=	221,

	LCTRL			=	224,
	LSHIFT			=	225,
	LALT			=	226,
	LGUI			=	227,
	RCTRL			=	228,
	RSHIFT			=	229,
	RALT			=	230,
	RGUI			=	231,

	MEDIAPLAY		=	232,
	MEDIASTOPCD		=	233,
	MEDIAPREV		=	234,
	MEDIANEXT		=	235,
	MEDIAEJECT		=	236,
	MEDIAVOLUP		=	237,
	MEDIAVOLDOWN	=	238,
	MEDIAMUTE		=	239,

	MEDIAWWW 		=	0xf0,
	MEDIABACK 		=	0xf1,
	MEDIAFORWARD 	=	0xf2,
	MEDIASTOP 		=	0xf3,
	MEDIAFIND 		=	0xf4,
	MEDIASCROLLUP 	=	0xf5,
	MEDIASCROLLDOWN =	0xf6,
	MEDIAEDIT 		=	0xf7,
	MEDIASLEEP 		=	0xf8,
	MEDIACOFFEE 	=	0xf9,
	MEDIAREFRESH 	=	0xfa,
	MEDIACALC 		=	0xfb,
	//Not sure about these, but I can't find their respected USB HID scancodes, so I just added these here.
	//There's a faint chance that LAUNCHAPP1 and 2 are MEDIAEDIT and  MEDIACALC, but I can't find anything about them.
	//Note that these might no longer will exist as are currently in the future.
	MEDIAMAIL		=	0x100,
	MEDIASELECT		=	0x101,
	LAUNCHAPP1		=	0x102,
	LAUNCHAPP2		=	0x103,
}

/**
 * Translates OS native scancodes to standard ones.
 */
version(Windows) package uint translateSC(uint input, uint aux, bool rshift) @nogc @safe pure nothrow {
	switch (input) {
		case 0x08:
			return ScanCode.BACKSPACE;
		case 0x09:
			return ScanCode.TAB;
		case 0x0c:
			return ScanCode.CLEARAGAIN;
		case 0x0d:
			return ScanCode.ENTER;
		case 0x10:
			if (rshift) {
				return ScanCode.RSHIFT;
			} else {
				return ScanCode.LSHIFT;
			}
		case 0x11:
			if (aux & (1 << 24)) {
				return ScanCode.RCTRL;
			} else {
				return ScanCode.LCTRL;
			}
		case 0x12:
			if (aux & (1 << 24)) {
				return ScanCode.RALT;
			} else {
				return ScanCode.LALT;
			}
		case 0x13:
			return ScanCode.PAUSE;
		case 0x14:
			return ScanCode.CAPSLOCK;
		case 0x15:
			return ScanCode.LANGUAGE1;
		case 0x1b:
			return ScanCode.ESCAPE;
		case 0x19:
			return ScanCode.LANGUAGE2;
		case 0x20:
			return ScanCode.SPACE;
		case 0x21:
			return ScanCode.PAGEUP;
		case 0x22:
			return ScanCode.PAGEDOWN;
		case 0x23:
			return ScanCode.END;
		case 0x24:
			return ScanCode.HOME;
		case 0x25:
			return ScanCode.LEFT;
		case 0x26:
			return ScanCode.UP;
		case 0x27:
			return ScanCode.RIGHT;
		case 0x28:
			return ScanCode.DOWN;
		case 0x29:
			return ScanCode.SELECT;
		case 0x2c:
			return ScanCode.PRINTSCREEN;
		case 0x2d:
			return ScanCode.INSERT;
		case 0x2e:
			return ScanCode.DELETE;
		case 0x2f:
			return ScanCode.HELP;
		case 0x30:						//Numeric-block
			return ScanCode.n0;
		case 0x31: .. case 0x39:		//Numeric-block
			return input - 0x30 + 30;
		case 0x41: .. case 0x5A:		//Alpha-block
			return input - 0x41 + 4;
		case 0x5b:
			return ScanCode.LGUI;
		case 0x5c:
			return ScanCode.RGUI;
		case 0x5d:
			return ScanCode.APPLICATION;
		case 0x5f:
			return ScanCode.MEDIASLEEP;
		case 0x60:						//Numpad
			return ScanCode.np0;
		case 0x61: .. case 0x69:		//Numpad
			return input - 0x61 + ScanCode.np1;
		case 0x6a:
			return ScanCode.NP_MULTIPLY;
		case 0x6b:
			return ScanCode.NP_PLUS;
		case 0x6c:
			return ScanCode.NP_COMMA;
		case 0x6d:
			return ScanCode.NP_MINUS;
		case 0x6e:
			return ScanCode.NP_DECIMAL;
		case 0x6f:
			return ScanCode.NP_DIVIDE;
		case 0x70: .. case 0x7B:		//Function row
			return input - 0x70 + 58;
		case 0x7C: .. case 0x87:		//Extended function row
			return input - 0x7C + 104;
		case 0x90:
			return ScanCode.NUMLOCK;
		case 0x91:
			return ScanCode.SCROLLLOCK;
		case 0xA0:
			return ScanCode.LSHIFT;
		case 0xa1:
			return ScanCode.RSHIFT;
		case 0xa2:
			return ScanCode.LCTRL;
		case 0xa3:
			return ScanCode.RCTRL;
		case 0xa4:
			return ScanCode.LALT;
		case 0xa5:
			return ScanCode.RALT;
		case 0xa6:
			return ScanCode.MEDIABACK;
		case 0xa7:
			return ScanCode.MEDIAFORWARD;
		case 0xa8:
			return ScanCode.MEDIAREFRESH;
		case 0xa9:
			return ScanCode.STOP;
		case 0xaa:
			return ScanCode.MEDIAFIND;
		case 0xab:
			return ScanCode.MEDIACOFFEE;
		case 0xac:
			return ScanCode.MEDIAWWW;
		case 0xad:
			return ScanCode.MUTE;
		case 0xae:
			return ScanCode.VOLUME_DOWN;
		case 0xaf:
			return ScanCode.VOLUME_UP;
		case 0xb0:
			return ScanCode.MEDIANEXT;
		case 0xb1:
			return ScanCode.MEDIAPREV;
		case 0xb2:
			return ScanCode.MEDIASTOP;
		case 0xb3:
			return ScanCode.MEDIAPLAY;
		case 0xb4:
			return ScanCode.MEDIAMAIL;
		case 0xb5:
			return ScanCode.MEDIASELECT;
		case 0xb6:
			return ScanCode.LAUNCHAPP1;
		case 0xb7:
			return ScanCode.LAUNCHAPP2;

		case 0xba:
			return ScanCode.SEMICOLON;
		case 0xbb:
			return ScanCode.EQUALS;
		case 0xbc:
			return ScanCode.COMMA;
		case 0xbd:
			return ScanCode.MINUS;
		case 0xbe:
			return ScanCode.PERIOD;
		case 0xbf:
			return ScanCode.SLASH;
		case 0xc0:
			return ScanCode.GRAVE;
		case 0xdb:
			return ScanCode.LEFTBRACKET;
		case 0xdc:
			return ScanCode.BACKSLASH;
		case 0xdd:
			return ScanCode.RIGHTBRACKET;
		case 0xde:
			return ScanCode.APOSTROPHE;
		case 0xdf:
			return ScanCode.NONUSHASH;
		case 0xe2:
			return ScanCode.NONUSBACKSLASH;
		default:
			return 0xFF_FF;
	}
}
