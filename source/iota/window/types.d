module iota.window.types;

import std.typecons : BitFlags;
import std.bitmanip : bitfields;
import std.conv : to;

version (Windows) {
	import core.sys.windows.windows;
	import core.sys.windows.wtypes;
} else {
	import x11.Xlib;
	import x11.X;
}
/** 
 * Implements Window handles for GUI apps.
 */
version (Windows) {
	alias WindowH = HWND;
} else {
	alias WindowH = Window;
	//alias WindowH = void*;
}
///Defines window configuration flags.
public enum WindowCfgFlags {
	FixedSize			=	1 << 0,	///Creates a non-resizable window.
	IgnoreMenuKey		=	1 << 16,///Makes the window to ignore "menu" (Alt, F11) key under Windows.
}
/** 
 * Defines various window option flags that can be supplied during creating a new window.
 */
public enum WindowOptionFlags : ulong {
	///Disables menu key behavior, without it the Alt key can cause the keyboard input to hang, which is especially a
	///concern with applications without a menubar.
	DisableMenuKey	=	1L<<32L,
}
/// Describes the color format of a bitmap image 
public struct ColorFormat {
	enum ChannelType : ubyte {
		None		=	0x00,
		Red			=	0x01,
		Green		=	0x02,
		Blue		=	0x03,
		Alpha		=	0x04,
		Cyan		=	0x05,
		Yellow		=	0x06,
		Magenta		=	0x07,
		blacK		=	0x08,
		ColorIndex	=	0x09,
		X			=	0x0A,
		Y			=	0x0B,
		Z			=	0x0C,
		Greyscale	=	0x0D,
		flag_FP		=	0x80,	///Bit set if channel is floating point
	}
	ubyte[8]	chBits;			///Stores the number of bits for each color channel.
	ubyte[8]	chType;			///Stores the channel type information. Zero if channel not used or is padding bits
	///Returns the default RGBA32 color format for the given system.
	static ColorFormat defaultRGBA32() @nogc @safe nothrow {
		return ColorFormat([8,8,8,8,0,0,0,0], 
			[ChannelType.Red, ChannelType.Green, ChannelType.Blue, ChannelType.Alpha, 0, 0, 0, 0]);
	}
	///Returns the total number of bits.
	int getTotalBits() @nogc @safe pure nothrow const {
		return chBits[0] + chBits[1] + chBits[2] + chBits[3] + chBits[4] + chBits[5] + chBits[6] + chBits[7];
	}
}
/**
 * Implements a bitmap to be used with this library, mainly its windowing elements (cursors, etc.).
 */
public class WindowBitmap {
	uint		width;		///Width of the bitmap.
	uint		height;		///Height of the bitmap.
	size_t		pitch;		///Size of a single scanline in bytes.
	ColorFormat format;		///Stores color format information for this bitmap.
	///Stores the pixeldata of the bitmap.
	///Byte order should match system defaults to avoid conversions.
	ubyte[]		pixels;
	public this(uint width, uint height, ubyte[] pixels, ColorFormat format = ColorFormat.defaultRGBA32) 
			@nogc @safe pure nothrow {
		this.width = width;
		this.height = height;
		this.pixels = pixels;
		this.format = format;
		pitch = (width * getTotalBits) / 8;
		pitch += (width * getTotalBits) % 8 ? 1 : 0;
	}
	///Returns the total number of bits.
	int getTotalBits() @nogc @safe pure nothrow {
		return format.getTotalBits;
	}
}
///Defines standard cursors that can be chosen by the user.
///Please note some of them might be exclusive to certain OSes and/or desktop environments.
public enum StandardCursors {
	//init,
	Arrow,
	TextSelect,
	Busy,
	PrecisionSelect,
	AltSelect,
	ResizeNESW,
	ResizeNWSE,
	ResizeNS,
	ResizeWE,
	Move,
	Forbidden,
	Hand,
	WaitArrow,
	HelpSelect,
	LocationSelect,
	PersonSelect,
}
///Display mode accessing shorthands.
public enum DisplayMode {
	FullscreenHighest	=	-1,///Sets the highest possible resolution for fullscreen.
	FullscreenDesktop	=	-2,///Use current desktop resolution for fullscreen.
	Windowed			=	-3,///Sets the window back to windowed mode.
}
///Defines various properties of screen modes.
public enum ScreenModeFlags : ushort {
	FullScreen		=	1<<0,
	Interlaced		=	1<<1,
	AdaptiveSync	=	1<<2,///Synchronization is tied to software refresh (G-Sync, freesync, etc.)
	HDR				=	1<<3,///High Dynamic Range is supported.
	Rotate90		=	1<<4,///Screen is rotated by 90 degrees (both for 270).
	Rotate180		=	1<<5,///Screen is rotated by 180 degrees (both for 270).
}
/**
 * Defines potential display modes with in-depth parameters.
 */
public struct ScreenMode {
	string deviceName;
	int width;
	int height;
	int offsetH;				///Horizontal offset of screen in multiscreen setups
	int offsetV;				///Vertical offset of screen in multiscreen setups
	float refreshRate;
	ushort bitDepth = 32;
	BitFlags!ScreenModeFlags flags;
	string toString() @safe const {
		return width.to!string ~ "x" ~ height.to!string ~ "@" ~ refreshRate.to!string ~ "Hz";
	}
}