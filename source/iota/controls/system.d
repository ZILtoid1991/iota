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
		///Sizes of the screen. 0 : Virtual desktop width, 1 : Virtual desktop height, 2 : Screen width, 3: Screen height
		protected int[4]		screenSize; 
		protected size_t		winCount;	///Window counter.
		protected InputEvent[]	eventBuff;	///Input event buffer. FIFO.
	}
	enum SystemFlags : ushort {
		Win_RawInput		=	1 << 8,
	}
	package this(uint config = 0, uint osConfig = 0) nothrow {
		version (Windows) {
			if (!(osConfig & OSConfigFlags.win_RawInput)) {
				keyb = new Keyboard();
				mouse = new Mouse();
			} else {
				status |= SystemFlags.Win_RawInput | StatusFlags.IsConnected;
			}
			_type = InputDeviceType.System;
			screenSize = [GetSystemMetrics(SM_CXVIRTUALSCREEN), GetSystemMetrics(SM_CXVIRTUALSCREEN), 
					GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN)];
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

			T getDeviceByHandle(T)(T[] haysack, HANDLE needle) @nogc @safe pure nothrow {
				foreach (key ; haysack) {
					if (key.devHandle == needle) {
						return key;
					}
				}
				return null;
			}

			uint toIOTAMouseButtonFlags(uint src, ushort winFlags) @nogc @safe pure nothrow {
				if (winFlags & RI_MOUSE_BUTTON_1_DOWN)
					src |= MouseButtonFlags.Left;
				if (winFlags & RI_MOUSE_BUTTON_1_UP)
					src &= ~MouseButtonFlags.Left;
				if (winFlags & RI_MOUSE_BUTTON_2_DOWN)
					src |= MouseButtonFlags.Right;
				if (winFlags & RI_MOUSE_BUTTON_2_UP)
					src &= ~MouseButtonFlags.Right;
				if (winFlags & RI_MOUSE_BUTTON_3_DOWN)
					src |= MouseButtonFlags.Middle;
				if (winFlags & RI_MOUSE_BUTTON_3_UP)
					src &= ~MouseButtonFlags.Middle;
				if (winFlags & RI_MOUSE_BUTTON_4_DOWN)
					src |= MouseButtonFlags.Prev;
				if (winFlags & RI_MOUSE_BUTTON_4_UP)
					src &= ~MouseButtonFlags.Prev;
				if (winFlags & RI_MOUSE_BUTTON_5_DOWN)
					src |= MouseButtonFlags.Next;
				if (winFlags & RI_MOUSE_BUTTON_5_UP)
					src &= ~MouseButtonFlags.Next;
				return src;
			}
			if (eventBuff.length) {
				output = eventBuff[0];
				eventBuff = eventBuff[1..$];
				return EventPollStatus.HasMore;
			}
			tryAgain:
			MSG msg;
			//BOOL bret = PeekMessage(&msg, OSWindow.refCount[winCount].getHandle, 0, 0, PM_REMOVE);
			BOOL bret = PeekMessageW(&msg, OSWindow.refCount[winCount].getHandle, 0, 0, PM_REMOVE);
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
						if (message == WM_KEYDOWN || message == WM_SYSKEYDOWN) {
							output.button.dir = 1;
						} else {
							output.button.dir = 0;
						}
						//SHORT rshift = GetAsyncKeyState(VK_RSHIFT);
						//SHORT lshift = GetAsyncKeyState(VK_LSHIFT);
						output.button.id = translateSC(cast(uint)msg.wParam, cast(uint)msg.lParam);
						output.button.repeat = (msg.lParam & 0xFF_FF) < 255 ? cast(ubyte)(msg.lParam & 0xFF) : 0xFF;
						output.button.aux = keyb.getModifiers();
						//keyb.win_rshift = rshift =! 0;
						//keyb.win_lshift = lshift =! 0;
						
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
						mouse.lastPosition[0] = output.mouseSE.x;
						mouse.lastPosition[1] = output.mouseSE.y;
						//lastMousePos[0] = output.mouseSE.x;
						//lastMousePos[1] = output.mouseSE.y;
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
						output.mouseME.xD = output.mouseME.x - mouse.lastPosition[0];
						output.mouseME.yD = output.mouseME.y - mouse.lastPosition[1];
						mouse.lastPosition[0] = output.mouseME.x;
						mouse.lastPosition[1] = output.mouseME.y;
						break;
					case WM_LBUTTONUP, WM_LBUTTONDOWN, WM_LBUTTONDBLCLK, WM_MBUTTONUP, WM_MBUTTONDOWN, WM_MBUTTONDBLCLK,
					WM_RBUTTONUP, WM_RBUTTONDOWN, WM_RBUTTONDBLCLK, WM_XBUTTONUP, WM_XBUTTONDOWN, WM_XBUTTONDBLCLK:
						output.type = InputEventType.MouseClick;
						output.source = mouse;
						output.mouseCE.x = GET_X_LPARAM(msg.lParam);
						output.mouseCE.y = GET_Y_LPARAM(msg.lParam);
						mouse.lastPosition[0] = output.mouseCE.x;
						mouse.lastPosition[1] = output.mouseCE.y;
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
						UINT dwSize;
						GetRawInputData(cast(HRAWINPUT)msg.lParam, RID_INPUT, null, &dwSize, RAWINPUTHEADER.sizeof);
						if (!dwSize) return 1;
						void[] lpb;
						lpb.length = dwSize;

						if (GetRawInputData(cast(HRAWINPUT)msg.lParam, RID_INPUT, lpb.ptr, &dwSize, RAWINPUTHEADER.sizeof))
							return EventPollStatus.win_RawInputError;
						RAWINPUT* rawInput = cast(RAWINPUT*)lpb.ptr;
						
						switch (rawInput.header.dwType) {
							case RIM_TYPEMOUSE:
								Mouse device = getDeviceByHandle(mouseList, rawInput.header.hDevice);
								if (device !is null) {
									mouse = device;
									RAWMOUSE inputData = rawInput.data.mouse;
									int[2] absolute;
									int[2] relative;
									if (inputData.usFlags & MOUSE_MOVE_ABSOLUTE) {
										const bool isVirtualDesktop = (inputData.usFlags & MOUSE_VIRTUAL_DESKTOP) != 0;
										absolute[0] = cast(int)((inputData.lLastX / 65_535.0) * (isVirtualDesktop ? screenSize[0] : screenSize[2]));
										absolute[1] = cast(int)((inputData.lLastY / 65_535.0) * (isVirtualDesktop ? screenSize[1] : screenSize[3]));
										relative[0] = device.lastPosition[0] - absolute[0];
										relative[1] = device.lastPosition[1] - absolute[1];
									} else {
										relative[0] = inputData.lLastX;
										relative[1] = inputData.lLastY;
										absolute[0] = device.lastPosition[0] + relative[0];
										absolute[1] = device.lastPosition[1] + relative[1];
									}
									device.lastPosition[0] = absolute[0];
									device.lastPosition[1] = absolute[1];
									output.source = device;
									if (relative[0] || relative[1]) {	//Mouse move event
										InputEvent ie;
										ie = output;
										ie.type = InputEventType.MouseMove;
										ie.mouseME.x = absolute[0];
										ie.mouseME.y = absolute[1];
										ie.mouseME.xD = relative[0];
										ie.mouseME.yD = relative[1];
										ie.mouseME.buttons = device.lastButtonState;
										eventBuff ~= ie;
									}
									if (inputData.usButtonFlags & 0x03FF) {	//Mouse click event
										uint buttons = toIOTAMouseButtonFlags(device.lastButtonState, inputData.usButtonFlags);
										uint prevButtons = device.lastButtonState;
										device.lastButtonState = buttons;
										ushort buttonCntr = 1;
										while (buttons) {
											if ((buttons & 1) ^ (prevButtons & 1)) {
												InputEvent ie;
												ie = output;
												ie.type = InputEventType.MouseClick;
												ie.mouseCE.button = buttonCntr;
												ie.mouseCE.dir = (buttons & 1) ? 0 : 1;
												ie.mouseCE.x = absolute[0];
												ie.mouseCE.y = absolute[1];
												eventBuff ~= ie;
											} 
											buttonCntr = 1;
											buttons >>= 1;
											prevButtons >>= 1;
										}
									} 
									if (inputData.usButtonFlags & 0x0B00) { //Mouse wheel event
										InputEvent ie;
										ie = output;
										ie.type = InputEventType.MouseScroll;
										ie.mouseSE.x = device.lastPosition[0];
										ie.mouseSE.y = device.lastPosition[1];
										if (inputData.usButtonFlags & RI_MOUSE_WHEEL) {
											ie.mouseSE.yS = cast(short)inputData.usButtonData;
										} else {
											ie.mouseSE.xS = cast(short)inputData.usButtonData;
										}
										eventBuff ~= ie;
									} 
								}
								if (eventBuff.length) {
									output = eventBuff[0];
									eventBuff = eventBuff[1..$];
								}
								break;
							case RIM_TYPEKEYBOARD:
								RAWKEYBOARD inputData = rawInput.data.keyboard;
								Keyboard device = getDeviceByHandle(keybList, rawInput.header.hDevice);
								output.type = InputEventType.Keyboard;
								output.source = device;
								output.button.dir = cast(ubyte)(inputData.Flags & 1);
								output.button.id = translateSC(inputData.VKey, 
										(inputData.Flags & 2 ? 1<24 : 0) | ((inputData.MakeCode & 127) == 0x36 ? 1 << 18 : 0));
								output.button.aux = device.getModifiers();
								break;
							default:
								break;
						}
						
						switch (msg.wParam & 0xFF) {
							case RIM_INPUT:
								output.handle = null;
								DefWindowProcW(msg.hwnd, msg.message, msg.wParam, msg.lParam);
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