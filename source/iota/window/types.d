module iota.window.types;

import std.typecons : BitFlags;
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
/**
 * Implements a bitmap to be used with this library, mainly its windowing elements.
 */
public class WindowBitmap {
	public enum ChannelType : ubyte {
		None		=	0x00,
		Red			=	0x10,
		Green		=	0x20,
		Blue		=	0x30,
		Alpha		=	0x40,
		Grey		=	0x50,
		Index		=	0x60,
		Cyan		=	0x70,
		Yellow		=	0x80,
		Magenta		=	0x90,
		Black		=	0xA0,
		X			=	0xB0,
		Y			=	0xC0,
		Z			=	0xD0,
	}
	uint		width;		///Width of the bitmap.
	uint		height;		///Height of the bitmap.
	size_t		pitch;		///Size of a single scanline in bytes.. 
	///Defines bitmap channels.
	///lower nibble 0-2 = 2^n bits for that channel
	///lower nibble 3 = floating-pont number
	///upper nibble = channel type identifier
	ubyte[8]	channels;
	///Stores the pixeldata of the bitmap.
	///Byte order should match system defaults to avoid conversions.
	ubyte[]		pixels;
	public this(uint width, uint height, ubyte[8] channels, ubyte[] pixels) @nogc @safe pure nothrow {
		this.width = width;
		this.height = height;
		this.channels = channels;
		this.pixels = pixels;
		pitch = (width * getTotalBits) / 8;
		pitch += (width * getTotalBits) % 8 ? 1 : 0;
	}
	/**
	 * Returns the number of bits associated with the given channel number.
	 */
	public int getChannelBits(int chNum) @nogc @safe pure nothrow const {
		return 1<<(channels[chNum] & 0x07);
	}
	/**
	 * Returns the total number of bits used by this bitmap.
	 */
	public int getTotalBits() @nogc @safe pure nothrow const {
		int result;
		for (int i ; i < channels.length ; i++) {
			result += getChannelBits(i);
		}
		return result;
	}
}
///Display mode accessing shorthands.
public enum DisplayMode {
	FullscreenHighest	=	-1,///Sets the highest possible resolution for fullscreen.
	FullscreenDesktop	=	-2,///Sets desktop for fullscreen mode.
	Windowed			=	-3,///Sets the window back to windowed mode.
}
///Defines various properties of screen modes.
public enum ScreenModeFlags : ushort {
	FullScreen		=	1<<0,
	Interlaced		=	1<<1,
	AdaptiveSync	=	1<<2,///Synchronization is tied to software refresh (G-Sync, freesync, etc.)
	HDR				=	1<<3,///High Dynamic Range is supported.
}
/**
 * Defines potential display modes with in-depth parameters.
 */
public struct ScreenMode {
	int width;
	int height;
	float refreshRate;
	ushort bitDepth;
	BitFlags!ScreenModeFlags flags;
	string toString() @safe const {
		return width.to!string ~ "x" ~ height.to!string ~ "@" ~ refreshRate.to!string ~ "Hz";
	}
}