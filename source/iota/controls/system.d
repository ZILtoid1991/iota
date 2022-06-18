module iota.controls.system;

version (Windows) {
	import core.sys.windows.windows;
	
	import core.sys.windows.wtypes;
	import iota.controls.keyboard;
	import iota.controls.mouse;
	import std.utf;
}
import iota.controls.types;
import iota.controls.keybscancodes : translateSC;
import iota.etc.charcode;
import iota.window;

/** 
 * Implements a class for system-wide events.
 *
 * Under Windows, this class also handles keyboard and mouse inputs, because of Microsoft of course (Why? You did great
 * with WASAPI and relatively good with MIDI!)
 *
 * Note: Polling might suck up some more advanced windowing-related events. If they really needed, then just add 
 * handling of them to it with OOP magic!
 */
public class System : InputDevice {
	version (Windows) {
		package Keyboard		keyb;		///Pointer to the default, non-virtual keyboard.
		version (iota_use_utf8) {
			///Character input converted to UTF-8
			char[4]				lastChar;
		} else {
			///Character input converted to UTF-32
			dchar				lastChar;
		}
		package Mouse			mouse;		///Pointer to the default, non-virtual mouse.
		protected int[2]		lastMousePos;///Last position of the mouse cursor.
		protected size_t		winCount;	///Window counter.
	}
	package this() nothrow {
		version (Windows) {
			keyb = new Keyboard();
			mouse = new Mouse();
		}
	}
	public override int poll(ref InputEvent output) @nogc nothrow {
		version (Windows) {
			int GET_X_LPARAM(LPARAM lParam) @nogc nothrow pure {
				return cast(int)(cast(short) LOWORD(lParam));
        	}

			int GET_Y_LPARAM(LPARAM lParam) @nogc nothrow pure {
				return cast(int)(cast(short) HIWORD(lParam));
			}
			tryAgain:
			MSG msg;
			BOOL bret = PeekMessage(&msg, OSWindow.refCount[winCount].getHandle, 0, 0, PM_REMOVE);
			if (bret) {
				if (keyb.isTextInputEn()) {
					TranslateMessage(&msg);
				}
				version (iota_hi_prec_timestamp) {
					output.timestamp = MonoTime.currTime();
				} else {
					output.timestamp = msg.time;
				}
				output.handle = OSWindow.refCount[winCount].getHandle;
				switch (msg.message & 0xFF_FF) {
					case WM_CHAR, WM_SYSCHAR:
						output.type = InputEventType.TextInput;
						output.source = keyb;
						version (iota_use_utf8) {
							lastChar[0] = cast(char)(msg.wParam);
							output.textIn.text[0] = lastChar[0];
						} else {
							lastChar = cast(dchar)(msg.wParam);
							output.textIn.text[0] = lastChar;
						}
						output.textIn.isClipboard = false;
						break;
					case WM_UNICHAR, WM_DEADCHAR, WM_SYSDEADCHAR:
						output.type = InputEventType.TextInput;
						output.source = keyb;
						version (iota_use_utf8) {
							lastChar = encodeUTF8Char(cast(dchar)(msg.wParam));
						} else {
							lastChar = cast(dchar)(msg.wParam);
							output.textIn.text[0] = lastChar;
						}
						output.textIn.isClipboard = false;
						break;
					case WM_KEYDOWN, WM_KEYUP, WM_SYSKEYDOWN, WM_SYSKEYUP:
						output.type = InputEventType.Keyboard;
						output.source = keyb;
						if ((msg.message & 0xFF_FF) == WM_KEYDOWN || (msg.message & 0xFF_FF) == WM_SYSKEYDOWN)
							output.button.dir = 1;
						else
							output.button.dir = 0;
						output.button.id = translateSC(cast(uint)msg.wParam);
						output.button.repeat = (msg.lParam & 0xFF_FF) < 255 ? cast(ubyte)(msg.lParam & 0xFF) : 0xFF;
						output.button.aux = keyb.getModifiers();
						break;
					case 0x020E , WM_MOUSEWHEEL:
						output.type = InputEventType.MouseScroll;
						output.source = mouse;
						if ((msg.message & 0xFF_FF) == 0x020E)
							output.mouseSE.xS = GET_WHEEL_DELTA_WPARAM(msg.wParam);
						else
							output.mouseSE.yS = GET_WHEEL_DELTA_WPARAM(msg.wParam);
						output.mouseSE.x = GET_X_LPARAM(msg.lParam);
						output.mouseSE.y = GET_Y_LPARAM(msg.lParam);
						lastMousePos[0] = output.mouseSE.x;
						lastMousePos[1] = output.mouseSE.y;
						break;
					case WM_MOUSEMOVE:
						output.type = InputEventType.MouseMove;
						output.source = mouse;
						if (msg.wParam & MK_LBUTTON)
							output.mouseME.buttons |= MouseButtonFlags.Left;
						if (msg.wParam & MK_RBUTTON)
							output.mouseME.buttons |= MouseButtonFlags.Right;
						if (msg.wParam & MK_MBUTTON)
							output.mouseME.buttons |= MouseButtonFlags.Middle;
						if (msg.wParam & MK_XBUTTON1)
							output.mouseME.buttons |= MouseButtonFlags.Prev;
						if (msg.wParam & MK_XBUTTON2)
							output.mouseME.buttons |= MouseButtonFlags.Next;
						output.mouseME.x = GET_X_LPARAM(msg.lParam);
						output.mouseME.y = GET_Y_LPARAM(msg.lParam);
						output.mouseME.xD = output.mouseME.x - lastMousePos[0];
						output.mouseME.yD = output.mouseME.y - lastMousePos[1];
						lastMousePos[0] = output.mouseME.x;
						lastMousePos[1] = output.mouseME.y;
						break;
					case WM_LBUTTONUP, WM_LBUTTONDOWN, WM_LBUTTONDBLCLK, WM_MBUTTONUP, WM_MBUTTONDOWN, WM_MBUTTONDBLCLK,
					WM_RBUTTONUP, WM_RBUTTONDOWN, WM_RBUTTONDBLCLK, WM_XBUTTONUP, WM_XBUTTONDOWN, WM_XBUTTONDBLCLK:
						output.type = InputEventType.MouseMove;
						output.source = mouse;
						output.mouseCE.x = GET_X_LPARAM(msg.lParam);
						output.mouseCE.y = GET_Y_LPARAM(msg.lParam);
						output.mouseCE.repeat = 0;
						switch (msg.message & 0xFF_FF) {
							case WM_LBUTTONUP:
								output.mouseCE.dir = 0;
								output.mouseCE.button = MouseButtons.Left;
								break;
							case WM_LBUTTONDOWN:
								output.mouseCE.dir = 1;
								output.mouseCE.button = MouseButtons.Left;
								break;
							case WM_LBUTTONDBLCLK:
								output.mouseCE.repeat = 1;
								goto case WM_LBUTTONDOWN;
							case WM_RBUTTONUP:
								output.mouseCE.dir = 0;
								output.mouseCE.button = MouseButtons.Right;
								break;
							case WM_RBUTTONDOWN:
								output.mouseCE.dir = 1;
								output.mouseCE.button = MouseButtons.Right;
								break;
							case WM_RBUTTONDBLCLK:
								output.mouseCE.repeat = 1;
								goto case WM_RBUTTONDOWN;
							case WM_MBUTTONUP:
								output.mouseCE.dir = 0;
								output.mouseCE.button = MouseButtons.Middle;
								break;
							case WM_MBUTTONDOWN:
								output.mouseCE.dir = 1;
								output.mouseCE.button = MouseButtons.Middle;
								break;
							case WM_MBUTTONDBLCLK:
								output.mouseCE.repeat = 1;
								goto case WM_MBUTTONDOWN;
							case WM_XBUTTONUP:
								output.mouseCE.dir = 0;
								output.mouseCE.button = HIWORD(msg.wParam) == 1 ? MouseButtons.Next : MouseButtons.Prev;
								break;
							case WM_XBUTTONDOWN:
								output.mouseCE.dir = 1;
								output.mouseCE.button = HIWORD(msg.wParam) == 1 ? MouseButtons.Next : MouseButtons.Prev;
								break;
							case WM_XBUTTONDBLCLK:
								output.mouseCE.repeat = 1;
								goto case WM_XBUTTONDOWN;
							default:

								break;
						}
						break;
					case WM_QUIT:
						output.type = InputEventType.ApplExit;
						output.source = this;
						break;
					case WM_SIZE:
						output.type = InputEventType.WindowResize;
						output.source = this;
						break;
					default:
						goto tryAgain;
				}
			} else {
				//Check for window events
				
				winCount++;
				if (winCount < OSWindow.refCount.length)
					goto tryAgain;
				else
					winCount = 0;
				return 0;
			}

			return 1;
		}
	}
}