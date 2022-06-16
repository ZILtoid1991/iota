module iota.window.types;

version (Windows) {
	import core.sys.windows.windows;
	import core.sys.windows.wtypes;
}
/** 
 * Implements Window handles for GUI apps.
 */
version (Windows) {
	alias WindowH = HWND;
} else {
	alias WindowH = void*;
}
/** 
 * Window style identifiers.
 * These can be ORed together.
 */
public enum WindowStyleIDs : uint {
	Border		= 1<<0,
	Caption		= 1<<1,
	Child		= 1<<2,
	Parent		= 1<<3,
	Disabled	= 1<<4,
	Resizable	= 1<<5,
	Minimized	= 1<<6,
	Maximized	= 1<<7,
	MinimizeBtn	= 1<<8,
	MaximizeBtn	= 1<<9,
	PopUp		= 1<<10,
	Visible		= 1<<11,
	Default		= 1<<12,
	DragNDrop	= 1<<13,
	ContextHelp	= 1<<14,
	AppWindow	= 1<<15,
	
}

public enum OutputSurfaceCFG : ulong {
	init,
	//OpenGL
	OpenGL20		=	0x201_0000_0000,
	OpenGL30		=	0x301_0000_0000,
	OpenGL31		=	0x311_0000_0000,
	OpenGL32		=	0x321_0000_0000,
	OpenGL40		=	0x401_0000_0000,
	OpenGL41		=	0x411_0000_0000,
	OpenGL42		=	0x421_0000_0000,
	//Windows
	GDI				=	0x00f_0000_0000,
	DX9				=	0x90f_0000_0000,
	DX10			=	0xa0f_0000_0000,
	DX11			=	0xb0f_0000_0000,
	DX12			=	0xc0f_0000_0000,
}

public class WindowIcon {

}

public class WindowMenu {
	
}