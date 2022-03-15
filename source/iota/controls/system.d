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
import iota.etc.window;

/** 
 * Implements a class for system-wide events.
 *
 * Under Windows, this class also handles keyboard and mouse inputs, because of Microsoft of course (Why? You did great
 * with WASAPI and relatively good with MIDI!)
 */
public class System : InputDevice {
	version (Windows) {
		protected Keyboard		keyb;		///Pointer to the default, non-virtual keyboard.
		version (iota_use_utf8) {
			///Character input converted to UTF-8
			char[8]				lastChar;
		} else {
			///Character input converted to UTF-32
			dchar				lastChar;
		}
		protected Mouse			mouse;		///Pointer to the default, non-virtual mouse.
		protected int[2]		lastMousePos;///Last position of the mouse cursor
	}
	package this() {
		
	}
	public override int poll(ref InputEvent output) @nogc nothrow {
		version (Windows) {
			int GET_X_LPARAM(LPARAM lParam) @nogc nothrow pure {
				return cast(int)(cast(short) LOWORD(lParam));
        	}

			int GET_Y_LPARAM(LPARAM lParam) @nogc nothrow pure {
				return cast(int)(cast(short) HIWORD(lParam));
			}
			MSG msg;
			BOOL bret = PeekMessage(&msg, null, WM_KEYFIRST, WM_MOUSELAST, PM_REMOVE);
			if (bret) {
				if (keyb.isTextInputEn()) {
					TranslateMessage(&msg);
				}
				version (iota_hi_prec_timestamp) {
					output.timestamp = MonoTime.currTime();
				} else {
					output.timestamp = msg.time;
				}
				switch (msg.message & 0xFF_FF) {
					case WM_CHAR, WM_SYSCHAR:
						output.type = InputEventType.TextInput;
						output.source = keyb;
						version (iota_use_utf8) {
							lastChar[0] = cast(char)(msg.wParam);
							output.textIn.text = lastChar[0..1];
						} else {
							lastChar = cast(dchar)(msg.wParam);
							output.textIn.text = (&lastChar)[0..1];
						}
						output.textIn.isClipboard = false;
						break;
					case WM_UNICHAR, WM_DEADCHAR, WM_SYSDEADCHAR:
						output.type = InputEventType.TextInput;
						output.source = keyb;
						version (iota_use_utf8) {
							
						} else {
							lastChar = cast(dchar)(msg.wParam);
							output.textIn.text = (&lastChar)[0..1];
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
							output.mouseME.buttons = MouseButtonFlags.Left;
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
					default:
						break;
				}
			} else {
				return 0;
			}

			return int.init; // TODO: implement
		}
	}
}