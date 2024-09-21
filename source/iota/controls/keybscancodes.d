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
version(Windows) package uint translateSC(uint input, uint aux) @nogc @safe pure nothrow {
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
			/*
			It seems Microsoft made the 19th bit of lParam to accidentally function as a way to differentiate between the left and right shift.
			Let's use it!
			*/
			if (aux & (1 << 18)) {	
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
			return input - 0x31 + 30;
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
} else {
	///Translates KeySyms to USB HID ScanCodes
	///(Temporary, only use if other methods fail)
	package uint translateKeySym (const uint code) {
		if (code >= 0xFFbe && code <= 0xFFc9) {			//F1-12
			return code - 0xFFbe + 0x3A;
		} else if (code >= 0xFFca && code <= 0xFFd5) {	//F13-24
			return code - 0xFFca + 0x68;
		} else if (code >= 0xFFb1 && code <= 0xFFb9) {	//np1-9 (0 is at a different order)
			return code - 0xFFb1 + 0x59;
		} else if (code >= 0x0031 && code <= 0x0039) {	//n1-9 (0 is at a different order)
			return code - 0x0031 + 0x1E;
		} else if ((code & 0x20) >= 0x0061 && (code & 0x20) <= 0x007a) {	//A-Z
			return (code & 0x20) - 0x0061 + 0x04;
		} else {
			switch (code) {
			
			case 0xFF08:
				return ScanCode.BACKSPACE;
			case 0xFF09:
				return ScanCode.TAB;
			case 0xFF0d:
				return ScanCode.ENTER;
			case 0xFF13:
				return ScanCode.PAUSE;
			case 0xFF14:
				return ScanCode.SCROLLLOCK;
			case 0xFF15:
				return ScanCode.SYSREQ;
			case 0xFF1b:
				return ScanCode.ESCAPE;
			case 0xFFff:
				return ScanCode.DELETE;
			case 0xFF50:
				return ScanCode.HOME;	//Navblock begin
			case 0xFF51:
				return ScanCode.LEFT;
			case 0xFF52:
				return ScanCode.UP;
			case 0xFF53:
				return ScanCode.RIGHT;
			case 0xFF54:
				return ScanCode.DOWN;
			case 0xFF55:
				return ScanCode.PAGEUP;
			case 0xFF56:
				return ScanCode.PAGEDOWN;
			case 0xFF57:
				return ScanCode.END;	//Navblock end
			case 0xFF60:
				return ScanCode.SELECT;
			case 0xFF62:
				return ScanCode.EXECUTE;
			case 0xFF63:
				return ScanCode.INSERT;
			case 0xFF65:
				return ScanCode.UNDO;
			case 0xFF66:
				return ScanCode.REDO;
			case 0xFF67:
				return ScanCode.MENU;
			case 0xFF68:
				return ScanCode.FIND;
			case 0xFF69:
				return ScanCode.CANCEL;
			case 0xFF6a:
				return ScanCode.HELP;
			case 0xFF7F:
				return ScanCode.NUMLOCK;
			case 0xFF80:				//Numpad misc. begin
				return ScanCode.NP_SPACE;
			case 0xFFb0:
				return ScanCode.np0;
			case 0xFF89:
				return ScanCode.NP_TAB;
			case 0xFF8d:
				return ScanCode.NP_ENTER;
			case 0xFFbd:
				return ScanCode.NP_EQUALS;
			case 0xFFaa:
				return ScanCode.NP_MULTIPLY;
			case 0xFFab:
				return ScanCode.NP_PLUS;
			case 0xFFac:
				return ScanCode.NP_COMMA;
			case 0xFFad:
				return ScanCode.NP_MINUS;
			case 0xFFae:
				return ScanCode.NP_DECIMAL;
			case 0xFFaf:
				return ScanCode.NP_DIVIDE;//Numpad misc. end
			case 0xFFe1:				//Modifiers begin
				return ScanCode.LSHIFT;
			case 0xFFe2:
				return ScanCode.RSHIFT;
			case 0xFFe3:
				return ScanCode.LCTRL;
			case 0xFFe4:
				return ScanCode.RCTRL;
			case 0xFFe9:
				return ScanCode.LALT;
			case 0xFFea:
				return ScanCode.RALT;
			case 0xFFeb:
				return ScanCode.LGUI;
			case 0xFFec:
				return ScanCode.RGUI;	//Modifiers end
			case 0x30, 0x21:
				return ScanCode.n0;
			case 0x20:
				return ScanCode.SPACE;
			case 0x3b, 0x3a:
				return ScanCode.SEMICOLON;
			case 0x44, 0x22:
				return ScanCode.APOSTROPHE;
			case 0x2c, 0x3c:
				return ScanCode.COMMA;
			case 0x2e, 0x3e:
				return ScanCode.PERIOD;
			case 0x3f, 0x2f:
				return ScanCode.SLASH;
			case 0x2d, 0x5f:
				return ScanCode.MINUS;
			case 0x3d, 0x2b:
				return ScanCode.EQUALS;
			case 0x60, 0x7e:
				return ScanCode.GRAVE;
			case 0x5b, 0x7b:
				return ScanCode.LEFTBRACKET;
			case 0x5d, 0x7d:
				return ScanCode.RIGHTBRACKET;
			case 0x5c, 0x7c:
				return ScanCode.BACKSLASH;
			default:
				return 0;
			}
		}
		
	}
	/// Translates X11 keycodes to USB HID scancodes, using reverse-engineered lookup tables from the Linux kernel.
	/// Should be the same across all kernels since version 2.6, with only some minor changes regarding to lesser known
	/// and used scancodes.
	package uint translateKeyCode(const uint code) @nogc @safe pure nothrow {	
		/+
	  0,  0,  0,  0, 30, 48, 46, 32, 18, 33, 34, 35, 23, 36, 37, 38,//0
	 50, 49, 24, 25, 16, 19, 31, 20, 22, 47, 17, 45, 21, 44,  2,  3,//1
	  4,  5,  6,  7,  8,  9, 10, 11, 28,  1, 14, 15, 57, 12, 13, 26,//2
	 27, 43, 43, 39, 40, 41, 51, 52, 53, 58, 59, 60, 61, 62, 63, 64,//3
	 65, 66, 67, 68, 87, 88, 99, 70,119,110,102,104,111,107,109,106,//4
	105,108,103, 69, 98, 55, 74, 78, 96, 79, 80, 81, 75, 76, 77, 71,//5
	 72, 73, 82, 83, 86,127,116,117,183,184,185,186,187,188,189,190,//6
	191,192,193,194,134,138,130,132,128,129,131,137,133,135,136,113,//7
	//0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
	115,114,unk,unk,unk,121,unk, 89, 93,124, 92, 94, 95,unk,unk,unk,//8
	122,123, 90, 91, 85,unk,unk,unk,unk,unk,unk,unk,111,unk,unk,unk,//9
	unk,unk,unk,unk,unk,unk,unk,unk,unk,unk,unk,unk,unk,unk,unk,unk,//A
	unk,unk,unk,unk,unk,unk,179,180,unk,unk,unk,unk,unk,unk,unk,unk,//B
	unk,unk,unk,unk,unk,unk,unk,unk,unk,unk,unk,unk,unk,unk,unk,unk,//C
	unk,unk,unk,unk,unk,unk,unk,unk,111,unk,unk,unk,unk,unk,unk,unk,//D
	 29, 42, 56,125, 97, 54,100,126,164,166,165,163,161,115,114,113,//E
	150,158,159,128,136,177,178,176,142,152,173,140,unk,unk,unk,unk //F
		+/
		immutable ubyte[256] table = [
		//	0    1    2    3    4    5    6    7    8    9    A    B    C    D    E    F
			0x00,0x29,0x1E,0x1F,0x20,0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x2D,0x2E,0x2A,0x2B,//0(0)
			0x14,0x1A,0x08,0x15,0x17,0x1C,0x18,0x0C,0x12,0x13,0x2F,0x30,0x28,0xE0,0x04,0x16,//1(16)
			0x07,0x09,0x0A,0x0B,0x0D,0x0E,0x0F,0x33,0x34,0x35,0xE1,0x31,0x1D,0x1B,0x06,0x19,//2(32)
			0x05,0x11,0x10,0x36,0x37,0x38,0xE5,0x55,0xE2,0x2C,0x39,0x3A,0x3B,0x3C,0x3D,0x3E,//3(48)
			0x3F,0x40,0x41,0x42,0x43,0x53,0x47,0x5F,0x60,0x61,0x56,0x5C,0x5D,0x5E,0x57,0x59,//4(64)
			0x5A,0x5B,0x62,0x63,0x00,0x94,0x64,0x44,0x45,0x87,0x92,0x93,0x8A,0x00,0x8B,0x8C,//5(80)
			0x58,0xE4,0x54,0x46,0xE6,0x00,0x4A,0x52,0x4B,0x50,0x4F,0x4D,0x51,0x4E,0x49,0x4C,//6(96)
			0x00,0x7F,0x81,0x80,0x66,0x67,0x00,0x48,0x00,0x85,0x90,0x91,0x89,0xE3,0xE7,0x65,//7(112)
			0x78,0x79,0x76,0x7A,0x77,0x7C,0x74,0x7D,0x7E,0x7B,0x75,0x00,0xFB,0x00,0xF8,0x00,//8
			0x00,0x00,0x00,0x00,0x00,0x00,0xF0,0x00,0xF9,0x00,0x00,0x00,0x00,0x00,0xF1,0xF2,//9
			0x00,0xEC,0x00,0xEB,0xE8,0xEA,0xE9,0x00,0x00,0x00,0x00,0x00,0x00,0xFA,0x00,0x00,//A
			0xF7,0xF5,0xF6,0xB6,0xB7,0x00,0x00,0x68,0x69,0x6A,0x6B,0x6C,0x6D,0x6E,0x6F,0x70,//B
			0x71,0x72,0x73,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,//C
			0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,//D
			0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,//E
			0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,//F
		//	0    1    2    3    4    5    6    7    8    9    A    B    C    D    E    F
		];
		return table[(code - 8) & 0xFF];
	}
}
///Translates PS/2 make codes to USB HID codes.
///(Why did they had to use PS/2 codes when USB HID was already available by that time?)
package uint translatePS2MC (const uint code, const bool e0Flag) @nogc @safe pure nothrow {
	immutable ubyte[128] tableA = [
	//	0    1    2    3    4    5    6    7    8    9    A    B    C    D    E    F
		0x00,0x29,0x1E,0x1F,0x20,0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x2D,0x2E,0x2A,0x2B,
		0x14,0x1A,0x08,0x15,0x17,0x1C,0x18,0x0C,0x12,0x13,0x2F,0x30,0x28,0xE0,0x04,0x16,
		0x07,0x09,0x0A,0x0B,0x0D,0x0E,0x0F,0x33,0x34,0x35,0xE1,0x31,0x1D,0x1B,0x06,0x19,
		0x05,0x11,0x10,0x36,0x37,0x38,0xE5,0x55,0xE2,0x2C,0x39,0x3A,0x3B,0x3C,0x3D,0x3E,
		0x3F,0x40,0x41,0x42,0x43,0x53,0x47,0x5F,0x60,0x61,0x56,0x5C,0x5D,0x5E,0x57,0x59,
		0x5A,0x5B,0x62,0x63,0x00,0x00,0x64,0x44,0x45,0x67,0x00,0x00,0x00,0x8C,0x00,0x00,
		0x00,0x00,0x00,0x00,0x68,0x69,0x6A,0x6B,0x6C,0x6D,0x6E,0x6F,0x70,0x71,0x72,0x00,
		0x88,0x90,0x91,0x87,0x00,0x00,0x73,0x93,0x92,0x00,0x8A,0x8B,0x00,0x89,0x85,0x00,
	];
	immutable ubyte[128] tableB = [
	//	0    1    2    3    4    5    6    7    8    9    A    B    C    D    E    F
		0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
		0xB6,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xB5,0x00,0x00,0x58,0xE4,0x00,0x00,
		0xE2,0x00,0xCD,0x00,0xB7,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xEA,0x00,
		0xE9,0x00,0x00,0x46,0x00,0x54,0x48,0x00,0xE6,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
		0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x4A,0x52,0x4B,0x00,0x50,0x00,0x4F,0x00,0x4D,
		0x51,0x4E,0x49,0x4C,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xE3,0x5C,0x65,0x81,0x82,
		0x00,0x00,0x00,0x83,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
		0x00,0x00,0x00,0x00,0x00,0x00,0x94,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
	];
	if (e0Flag) return tableB[code & 0x7F];
	else return tableA[code & 0x7F];
}