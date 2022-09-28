module iota.controls.system;

version (Windows) {
	import core.sys.windows.windows;
	
	import core.sys.windows.wtypes;
	import iota.controls.keyboard;
	import iota.controls.mouse;
	import std.utf;
	import std.stdio;
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
 */
public class System : InputDevice {
	version (Windows) {
		package Keyboard[]		keybList;	///List of all keyboards (raw input only)
		package Keyboard		keyb;		///Pointer to the default, non-virtual keyboard.
		version (iota_use_utf8) {
			///Character input converted to UTF-8
			char[4]				lastChar;
		} else {
			///Character input converted to UTF-32
			dchar				lastChar;
		}
		package Mouse[]			mouseList;	///List of all mice (raw input only)
		package Mouse			mouse;		///Pointer to the default, non-virtual mouse.
		protected int[2]		lastMousePos;///Last position of the mouse cursor.
		protected size_t		winCount;	///Window counter.
	}
	enum SystemFlags : ushort {
		Win_RawInput		=	1 << 8,
	}
	package this(uint config = 0, uint osConfig = 0) nothrow {
		version (Windows) {
			if (osConfig & OSConfigFlags.win_LegacyIO) {
				keyb = new Keyboard();
				mouse = new Mouse();
			} else {
				status |= SystemFlags.Win_RawInput | StatusFlags.IsConnected;
			}
			_type = InputDeviceType.System;
		}
	}
	public override int poll(ref InputEvent output) nothrow {
		version (Windows) {
			int GET_X_LPARAM(LPARAM lParam) @nogc nothrow pure {
				return cast(int)(cast(short) LOWORD(lParam));
        	}

			int GET_Y_LPARAM(LPARAM lParam) @nogc nothrow pure {
				return cast(int)(cast(short) HIWORD(lParam));
			}
			tryAgain:
			MSG msg;
			//BOOL bret = PeekMessage(&msg, OSWindow.refCount[winCount].getHandle, 0, 0, PM_REMOVE);
			BOOL bret = GetMessageW(&msg, OSWindow.refCount[winCount].getHandle, 0, 0);
			if (bret) {
				if (keyb.isTextInputEn()) {
					TranslateMessage(&msg);
				}
				auto message = msg.message & 0xFF_FF;
				//Dispatch all enabled messages to window first, so things will be easier later on.
				if (!(keyb.isMenuKeyDisabled() && (message == WM_SYSKEYDOWN || message == WM_SYSKEYUP)) || 
						(keyb.isMetaKeyDisabled() && (message == WM_KEYDOWN || message == WM_KEYUP) && (msg.wParam == VK_LWIN 
						|| msg.wParam == VK_RWIN)) ||
						(keyb.isMetaKeyCombDisabled() && (message == WM_KEYDOWN || message == WM_KEYUP) && 
						(keyb.getModifiers | KeyboardModifiers.Meta))) {
					DispatchMessageW(&msg);
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
						if (message == WM_KEYDOWN || message == WM_SYSKEYDOWN)
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
						if (message == 0x020E)
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
						output.type = InputEventType.MouseClick;
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
					
					case WM_MOVING, WM_MOVE:
						output.type = InputEventType.WindowMove;
						output.source = this;
						break;
					case WM_SIZING, WM_SIZE:
						output.type = InputEventType.WindowResize;
						output.source = this;
						break;
					case WM_INPUT:		//Raw input
						switch (msg.wParam & 0xFF) {
							case RIM_INPUT:
								output.handle = null;
								DefWindowProcW(msg.hwnd, msg.message, msg.wParam, msg.lParam);
								break;
							case RIM_INPUTSINK:
								break;
							default:
								break;
						}
						break;
					case 0x00FE:		//Raw input device added/removed
						if (msg.wParam == 2) {	//Device removed
							foreach (size_t i, Keyboard dev ; keybList) {
								if (dev.devHandle == cast(HANDLE)msg.lParam) {
									dev.status |= InputDevice.StatusFlags.IsInvalidated;
									dev.status &= ~InputDevice.StatusFlags.IsConnected;
									output.source = dev;
									keybList = keybList[0..i] ~ keybList[i+1..$];
									goto breakTwoLoopsAtOnce;
								}
							}
							foreach (size_t i, Mouse dev ; mouseList) {
								if (dev.devHandle == cast(HANDLE)msg.lParam) {
									dev.status |= InputDevice.StatusFlags.IsInvalidated;
									dev.status &= ~InputDevice.StatusFlags.IsConnected;
									output.source = dev;
									mouseList = mouseList[0..i] ~ mouseList[i+1..$];
									goto breakTwoLoopsAtOnce;
								}
							}
							breakTwoLoopsAtOnce:
							output.type = InputEventType.DeviceRemoved;
						} else if (msg.wParam == 1) {	//Device added
							output.type = InputEventType.DeviceAdded;
							HANDLE devHandle = cast(HANDLE)msg.lParam;
						}
						break;
					default:
						//check for window status
						output.source = this;
						final switch (OSWindow.refCount[winCount].getWindowStatus) with (OSWindow.Status) {
							case init: break;
							case Quit: 
								output.type = InputEventType.WindowClose;
								break;
							case Minimize: 
								output.type = InputEventType.WindowMinimize;
								break;
							case Maximize: 
								output.type = InputEventType.WindowMaximize;
								break;
							case Move, MoveEnded: 
								output.type = InputEventType.WindowMove;
								break;
							case Resize, ResizeEnded: 
								output.type = InputEventType.WindowResize;
								break;
							case InputLangCh: 
								output.type = InputEventType.InputLangChange;
								break;
							case InputLangChReq: break;
						}
						break;
				}
			} else {
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