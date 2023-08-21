module iota.controls.polling;

public import iota.controls.types;
public import iota.controls.keyboard;
public import iota.controls.mouse;
public import iota.controls.system;
import iota.window.oswindow;
import iota.controls.keybscancodes;
import iota.controls.gamectrl;

/** 
 * Polls all input devices, and returns the found events in a given order.
 * Params:
 *   output = The input event that was found. 
 * Returns: 1 if an event has been polled, 0 if no events left. Other values are error codes.
 */
public int poll(ref InputEvent output) nothrow {
	int status = mainPollingFun(output);
	if (status) return status;
	version (Windows) {
		status = XInputDevice.poll(output);
		if (status) return status;
	}
	return 0;
}
package nothrow int function(ref InputEvent) mainPollingFun;
Keyboard keyb;          ///Main keyboard, or the only keyboard on APIs not supporting differentiating between keyboards.
Mouse mouse;            ///Main mouse, or the only mouse on APIs not supporting differentiating between mice.
System sys;				///System device, originator of system events.
InputDevice[] devList;	///List of input devices.

version (Windows) {
	import core.sys.windows.windows;
	import core.sys.windows.wtypes;
	version (iota_use_utf8)
		package char[4]	lastChar;
	else
		package dchar	lastChar;
	package int winCount;
	package InputEvent[3] mouse_inputEventBuff;		///RawInput IO buffer for mouse
	package int GET_X_LPARAM(LPARAM lParam) @nogc nothrow pure {
		return cast(int)(cast(short) LOWORD(lParam));
	}

	package int GET_Y_LPARAM(LPARAM lParam) @nogc nothrow pure {
		return cast(int)(cast(short) HIWORD(lParam));
	}
	package uint toIOTAMouseButtonFlags(uint src, ushort winFlags) @nogc @safe pure nothrow {
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
	///Returns the given device by RawInput handle.
	package InputDevice getDevByHandle(HANDLE hndl) nothrow @nogc {
		foreach (InputDevice dev ; devList) {
			if (dev.hDevice == hndl)
				return dev;
		}
		return null;
	}
	///Polls event using legacy API under Windows (no RawInput)
	package int poll_win_LegacyIO(ref InputEvent output) nothrow @nogc {
		MSG msg;
		BOOL bret = PeekMessageW(&msg, null, 0, 0, PM_REMOVE);
		if (bret) {
			output.timestamp = msg.time * 1000L;
			output.handle = msg.hwnd;
			auto message = msg.message & 0xFF_FF;
			if (!(Keyboard.isMenuKeyDisabled() && (message == WM_SYSKEYDOWN || message == WM_SYSKEYUP)) || 
					!(Keyboard.isMetaKeyDisabled() && (message == WM_KEYDOWN || message == WM_KEYUP) && (msg.wParam == VK_LWIN 
					|| msg.wParam == VK_RWIN)) ||
					!(Keyboard.isMetaKeyCombDisabled() && (message == WM_KEYDOWN || message == WM_KEYUP) && 
					(keyb.getModifiers | KeyboardModifiers.Meta))) {
				//MSG msg0 = msg;
				//TranslateMessage(&msg0);
				DispatchMessageW(&msg);
			}
			if (Keyboard.isTextInputEn()) {
				TranslateMessage(&msg);     //This function only translates messages that are mapped to characters, but we still need to translate any keys to text command events
				if ((msg.message & 0xFF_FF) == WM_KEYDOWN) {
					keyb.processTextCommandEvent(output, translateSC(cast(uint)msg.wParam, cast(uint)msg.lParam), 1);
					if (output.type == InputEventType.TextCommand) return 1;
				} else if ((msg.message & 0xFF_FF) == WM_KEYUP) {
					keyb.processTextCommandEvent(output, translateSC(cast(uint)msg.wParam, cast(uint)msg.lParam), 0);
					if (output.type == InputEventType.TextCommand) return 1;
				}
			}
		
			switch (msg.message & 0xFF_FF) {
				case WM_CHAR, WM_SYSCHAR:
					output.type = InputEventType.TextInput;
					output.source = keyb;
					version (iota_use_utf8) {
						lastChar[0] = cast(char)(msg.wParam);
						//output.textIn.text[0] = lastChar[0];
					} else {
						lastChar = cast(dchar)(msg.wParam);
						//output.textIn.text[0] = lastChar;
					}
					output.textIn = TextInputEvent(&lastChar, 1);
					//output.textIn.isClipboard = false;
					break;
				case WM_UNICHAR, WM_DEADCHAR, WM_SYSDEADCHAR:
					output.type = InputEventType.TextInput;
					output.source = keyb;
					version (iota_use_utf8) {
						lastChar = encodeUTF8Char(cast(dchar)(msg.wParam));
					} else {
						lastChar = cast(dchar)(msg.wParam);
						output.textIn = TextInputEvent(&lastChar, 1);
						//output.textIn.text[0] = lastChar;
					}
					//output.textIn.isClipboard = false;
					break;
				case WM_KEYDOWN, WM_KEYUP, WM_SYSKEYDOWN, WM_SYSKEYUP:
					output.type = InputEventType.Keyboard;
					output.source = keyb;
					if (message == WM_KEYDOWN || message == WM_SYSKEYDOWN) {
						output.button.dir = 1;
					} else {
						output.button.dir = 0;
					}
					output.button.id = translateSC(cast(uint)msg.wParam, cast(uint)msg.lParam);
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
	
				
				
				default:
					output = OSWindow.lastInputEvent;
					OSWindow.lastInputEvent = InputEvent.init;
					
					break;
			}
		} else {	//No more events for this window, move onto the next if any
			/* winCount++;
			if (winCount < OSWindow.refCount.length)
				goto tryAgain;	//Not the nicest solution, could have been done with recursive calls, but that would have had stack allocation.
			else	//All windows have tested for events, reset window counter, then return with 0 (finished)
				winCount = 0; */
			return 0;
		}
		return 1;
	}
	///Polls inputs using the more modern RawInput API.
	package int poll_win_RawInput(ref InputEvent output) nothrow @nogc {
		/* foreach (ref InputEvent key; mouse_inputEventBuff) {
			if (key.type != InputEventType.init) {
				output = key;
				key.type = InputEventType.init;
				return 1;
			}
		} */
		MSG msg;
		BOOL bret = PeekMessageW(&msg, null, 0, 0, PM_REMOVE);
		if (bret) {
			output.timestamp = msg.time * 1000L;
			output.handle = msg.hwnd;
			auto message = msg.message & 0xFF_FF;
			if (!(Keyboard.isMenuKeyDisabled() && (message == WM_SYSKEYDOWN || message == WM_SYSKEYUP)) || 
					!(Keyboard.isMetaKeyDisabled() && (message == WM_KEYDOWN || message == WM_KEYUP) && (msg.wParam == VK_LWIN 
					|| msg.wParam == VK_RWIN)) ||
					!(Keyboard.isMetaKeyCombDisabled() && (message == WM_KEYDOWN || message == WM_KEYUP) && 
					(keyb.getModifiers | KeyboardModifiers.Meta))) {
				DispatchMessageW(&msg);
			}
			if (Keyboard.isTextInputEn()) {
				TranslateMessage(&msg);     //This function only translates messages that are mapped to characters, but we still need to translate any keys to text command events
				if ((msg.message & 0xFF_FF) == WM_KEYDOWN) {
					keyb.processTextCommandEvent(output, translateSC(cast(uint)msg.wParam, cast(uint)msg.lParam), 1);
					if (output.type == InputEventType.TextCommand) return 1;
				} else if ((msg.message & 0xFF_FF) == WM_KEYUP) {
					keyb.processTextCommandEvent(output, translateSC(cast(uint)msg.wParam, cast(uint)msg.lParam), 0);
					if (output.type == InputEventType.TextCommand) return 1;
				}
			}
		
			switch (msg.message & 0xFF_FF) {
				case WM_CHAR, WM_SYSCHAR:
					output.type = InputEventType.TextInput;
					output.source = keyb;
					version (iota_use_utf8) {
						lastChar[0] = cast(char)(msg.wParam);
						//output.textIn.text[0] = lastChar[0];
					} else {
						lastChar = cast(dchar)(msg.wParam);
						//output.textIn.text[0] = lastChar;
					}
					output.textIn = TextInputEvent(&lastChar, 1);
					//output.textIn.isClipboard = false;
					break;
				case WM_UNICHAR, WM_DEADCHAR, WM_SYSDEADCHAR:
					output.type = InputEventType.TextInput;
					output.source = keyb;
					version (iota_use_utf8) {
						lastChar = encodeUTF8Char(cast(dchar)(msg.wParam));
					} else {
						lastChar = cast(dchar)(msg.wParam);
						output.textIn = TextInputEvent(&lastChar, 1);
						//output.textIn.text[0] = lastChar;
					}
					//output.textIn.isClipboard = false;
					break;
				
				case WM_INPUT:		//Raw input
					/* UINT hdrSize = RAWINPUT.sizeof;
					ubyte[RAWINPUT.sizeof] hdr; */
					UINT dwSize = 256;
					ubyte[256] lpb;
					/* GetRawInputData(cast(HRAWINPUT)msg.lParam, RID_INPUT, hdr.ptr, &hdrSize, RAWINPUTHEADER.sizeof); */
					GetRawInputData(cast(HRAWINPUT)msg.lParam, RID_INPUT, lpb.ptr, &dwSize, RAWINPUTHEADER.sizeof);
					RAWINPUT rawInput = *cast(RAWINPUT*)lpb.ptr;
					/* RAWINPUT* riHeader = cast(RAWINPUT*)hdr.ptr; */
					
					switch (rawInput.header.dwType) {
						case RIM_TYPEMOUSE:
							//BUG: `GetRawInputData` returns null for header.hDevice, no documentation on what causes it.
							Mouse device = cast(Mouse)getDevByHandle(rawInput.header.hDevice);
							if (device is null) device = mouse;
							/* if (device !is null) { */ 
							
								//mouse = device;
							RAWMOUSE inputData = rawInput.data.mouse;
							int[2] absolute;
							int[2] relative;
							if (inputData.usFlags & MOUSE_MOVE_ABSOLUTE) {
								const bool isVirtualDesktop = (inputData.usFlags & MOUSE_VIRTUAL_DESKTOP) != 0;
								absolute[0] = cast(int)((inputData.lLastX / 1.0) * 
										(isVirtualDesktop ? sys.screenSize[0] : sys.screenSize[2]));
								absolute[1] = cast(int)((inputData.lLastY / 1.0) * 
										(isVirtualDesktop ? sys.screenSize[1] : sys.screenSize[3]));
								relative[0] = device.lastPosition[0] - absolute[0];
								relative[1] = device.lastPosition[1] - absolute[1];
							} else {
								relative[0] = inputData.lLastX * 65_536;
								relative[1] = inputData.lLastY * 65_536;
								absolute[0] = device.lastPosition[0] + relative[0];
								absolute[1] = device.lastPosition[1] + relative[1];
							}
							device.lastPosition[0] = absolute[0];
							device.lastPosition[1] = absolute[1];
							output.source = device;
							output.type = InputEventType.HPMouse;
							//Mouse move event
							output.mouseHP.x = absolute[0];
							output.mouseHP.y = absolute[1];
							output.mouseHP.xD = relative[0];
							output.mouseHP.yD = relative[1];
							//Mouse click event
							uint buttons = toIOTAMouseButtonFlags(device.lastButtonState, inputData.usButtonFlags);
							device.lastButtonState = buttons;
							output.mouseHP.buttons = cast(ushort)buttons;
							
							if (inputData.usButtonFlags & 0x0B00) { //Mouse wheel event
								if (inputData.usButtonFlags & RI_MOUSE_WHEEL) {
									output.mouseHP.hScroll = cast(byte)inputData.usButtonData;
								} else {
									output.mouseHP.vScroll = cast(byte)inputData.usButtonData;
								}
							} 
							//}
							/* if (eventBuff.length) {
								output = eventBuff[0];
								eventBuff = eventBuff[1..$];
							} */
							break;
						case RIM_TYPEKEYBOARD:
							RAWKEYBOARD inputData = rawInput.data.keyboard;
							output.type = InputEventType.Keyboard;
							//BUG: `GetRawInputData` returns null for header.hDevice, no documentation on what causes it.
							output.source = getDevByHandle(rawInput.header.hDevice);
							if (output.source is null) output.source = keyb;
							output.button.dir = cast(ubyte)((~inputData.Flags) & 1);
							output.button.id = translatePS2MC(inputData.MakeCode, (inputData.Flags & 2) == 2);
							output.button.aux = (cast(Keyboard)output.source).getModifiers();
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
						output.source = getDevByHandle(cast(HANDLE)msg.lParam);
						output.source.status |= InputDevice.StatusFlags.IsInvalidated;
						output.source.status &= ~InputDevice.StatusFlags.IsConnected;
						output.type = InputEventType.DeviceRemoved;
					} else if (msg.wParam == 1) {	//Device added
						output.type = InputEventType.DeviceAdded;
						HANDLE devHandle = cast(HANDLE)msg.lParam;
					}
					break;
				//begin of legacy mouse events
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
				//end of legacy mouse events
				default:
					output = OSWindow.lastInputEvent;
					OSWindow.lastInputEvent = InputEvent.init;
					break;
			}
		} else {	//No more events for this window, move onto the next if any
			/* winCount++;
			if (winCount < OSWindow.refCount.length)
				goto tryAgain;	//Not the nicest solution, could have been done with recursive calls, but that would have had stack allocation.
			else	//All windows have tested for events, reset window counter, then return with 0 (finished)
				winCount = 0; */
			return 0;
		}
		return 1;
	}
} else {
	import x11.X;
	import x11.Xlib;
	import x11.Xresource;
	//import x11.Xlocale;
	
	version (iota_use_utf8) {
		package char[32] chrBuf;
		package int chrCntr;
	} else {
		package wchar[32] chrBuf;
		package int chrCntr;
		package dchar[32] chrOut;
	}
	shared static this() {
		
	}
	package int poll_x11_RegularIO(ref InputEvent output) nothrow @nogc {
		tryAgain:
		XEvent xe;
		while (XNextEvent(OSWindow.mainDisplay, &xe)) {
			switch (xe.type) {
				case MappingNotify:
					XRefreshKeyboardMapping(&ev.xmapping);
					goto tryAgain;
				case ButtonPress, ButtonRelease:		//Note: Under X11, scrollwheel events are also mapped here.
					output.timestamp = xe.xbutton.time * 1000L;
					output.handle = xe.xbutton.window;
					output.type = InputEventType.MouseClick;
					output.source = mouse;
					output.handle = xe.xbutton.window;
					output.mouseCE.button = cast(ushort)xe.xbutton.button;
					if (xe.type == ButtonPress) {
						output.mouseCE.dir = 0;
						mouse.lastButtonState |= 1<<(output.mouseCE.button - 1);
					} else {
						output.mouseCE.dir = 1;
						mouse.lastButtonState &= ~(1<<(output.mouseCE.button - 1));
					}
					output.mouseCE.x = xe.xbutton.x;
					output.mouseCE.y = xe.xbutton.y;
					mouse.lastPosition = [xe.xbutton.x, xe.xbutton.y];
					return 1;
				case MotionNotify:
					return 1;
				case KeyPress, KeyRelease:
					output.timestamp = xe.xkey.time * 1000L;
					output.handle = xe.xkey.window;
					output.source = keyb;
					updateKeybMods(keyb, xe.xkey.keycode);
					if (keyb.isTextInputEn) {
						KeySym ks;
						Status status;
						OSWindow w = OSWindow.byRef(xe.xkey.window);
						//XFilterEvent(&xe, xe.xkey.window);
						output.type = InputEventType.TextInput;
						version (iota_use_utf8) {
							Xutf8LookupString(w.ic, cast(XKeyPressedEvent*)&xe, chrBuf, chrCntr, chrBuf.length, &ks, status);
							output.textIn = TextInputEvent(chrBuf, chrCntr);
						} else {
							XwcLookupString(w.ic, cast(XKeyPressedEvent*)&xe, chrBuf, chrCntr, chrBuf.length, &ks, status);
							for (int i ; i < chrCntr ; i++) {
								chrOut[i] = chrBuf[i];
							}
							output.textIn = TextInputEvent(chrOut, chrCntr);
						}
					} else {
						output.type = InputEventType.Keyboard;
						output.button.auxF = float.nan;
						output.button.id = translateKeyCode(xe.xkey.keycode);
						keyb.setModifiers(xe.xkey.state);
						output.button.aux = keyb.getModifiers();
						
					}
					return 1;
				case ConfigureNotify:
					output.timestamp = 0;
					output.handle = xe.xconfigure.event;
					output.type = InputEventType.WindowResize;
					with (output.window) {
						x = xe.xconfigure.x;
						y = xe.xconfigure.y;
						width = xe.xconfigure.width;
						height = xe.xconfigure.height;
					}
					return 1;
				case LASTEvent:
					output.type = InputEventType.init;
					output.source = null;
					return 0;
				default:
					break;
			}
		}
		return 0;
	}
}
