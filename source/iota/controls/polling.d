module iota.controls.polling;

public import iota.controls.types;
public import iota.controls.keyboard;
public import iota.controls.mouse;
public import iota.controls.system;
import iota.window.oswindow;
import iota.controls.keybscancodes;
import iota.controls.gamectrl;
import core.stdc.string;

/** 
 * Polls all input devices, and returns the found events in a given order.
 * Params:
 *   output = The input event that was found. 
 * Returns: 1 if an event has been polled, 0 if no events left. Other values are error codes.
 */
public int poll(ref InputEvent output) nothrow @trusted {
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
	version (iota_use_utf8) package char[4] lastChar;
	else package dchar lastChar;
	package int winCount;
	package ubyte[1024] rawInputBuf;				///RawInput data buffer
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
			if (dev.hDevice is hndl)
				return dev;
		}
		return null;
	}
	///Polls event using legacy API under Windows (no RawInput)
	package int poll_win_LegacyIO(ref InputEvent output) nothrow @nogc {
		MSG msg;
		BOOL bret = PeekMessageW(&msg, null, 0, 0, PM_REMOVE);
		if (bret) {
			version (iota_ostimestamp) output.timestamp = msg.time * 1000L;
			else output.timestamp = getTimestamp();
			output.handle = msg.hwnd;
			auto message = msg.message & 0xFF_FF;
			
			DispatchMessageW(&msg);
			
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
					} else {
						lastChar = cast(dchar)(msg.wParam);
					}
					output.textIn = TextInputEvent(&lastChar, 1, false);
					break;
				case WM_UNICHAR, WM_DEADCHAR, WM_SYSDEADCHAR:
					output.type = InputEventType.TextInput;
					output.source = keyb;
					version (iota_use_utf8) {
						lastChar = encodeUTF8Char(cast(dchar)(msg.wParam));
					} else {
						lastChar = cast(dchar)(msg.wParam);
						output.textIn = TextInputEvent(&lastChar, 1, 
								(msg.message & 0xFF_FF) == WM_DEADCHAR || (msg.message & 0xFF_FF) == WM_SYSDEADCHAR);
					}
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
			
			return 0;
		}
		return 1;
	}
	///Polls inputs using the more modern RawInput API.
	package int poll_win_RawInput(ref InputEvent output) nothrow @nogc {
		MSG msg;
		BOOL bret = PeekMessageW(&msg, null, 0, 0, PM_REMOVE);
		if (bret) {
			output.timestamp = msg.time * 1000L;
			output.handle = msg.hwnd;
			auto message = msg.message & 0xFF_FF;
			DispatchMessageW(&msg);
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
					} else {
						lastChar = cast(dchar)(msg.wParam);
					}
					output.textIn = TextInputEvent(&lastChar, 1);
					break;
				case WM_UNICHAR, WM_DEADCHAR, WM_SYSDEADCHAR:
					output.type = InputEventType.TextInput;
					output.source = keyb;
					version (iota_use_utf8) {
						lastChar = encodeUTF8Char(cast(dchar)(msg.wParam));
					} else {
						lastChar = cast(dchar)(msg.wParam);
						output.textIn = TextInputEvent(&lastChar, 1);
					}
					break;
				case WM_INPUT:		//Raw input
					UINT dwSize = 1024;
					GetRawInputData(cast(HRAWINPUT)msg.lParam, RID_INPUT, rawInputBuf.ptr, &dwSize, RAWINPUTHEADER.sizeof);
					RAWINPUT* rawInput = cast(RAWINPUT*)rawInputBuf.ptr;
					switch (rawInput.header.dwType) {
						case RIM_TYPEMOUSE:
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
							if (inputData.usButtonFlags & 0x0800) { //Mouse wheel event (horizontal)
								output.mouseHP.hScroll = cast(byte)inputData.usButtonData;
							} else if (inputData.usButtonFlags & 0x0400) { //Mouse wheel event 
								short amount = cast(short)inputData.usButtonData;
								if (amount >= byte.max) amount = byte.max;
								else if (amount <= byte.min) amount = byte.min;
								output.mouseHP.vScroll = cast(byte)amount;
							}
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
						default: //Must be RIM_TYPEHID
							// BEGIN OF OPTIONAL DATA DUMP BLOCK DO NOT REMOVE!!! //
							/* output.type = InputEventType.Debug_DataDump;
							output.clipboard.data = &rawInput.data.hid.bRawData;
							output.clipboard.length = rawInput.data.hid.dwSizeHid * rawInput.data.hid.dwCount; */
							//  END OF OPTIONAL DATA DUMP BLOCK DO NOT REMOVE!!!  //
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
			
			return 0;
		}
		return 1;
	}
} else {
	import x11.X;

	import x11.Xlib;
	import x11.Xutil;
	import x11.Xresource;
	import x11.extensions.XI;
	import x11.extensions.XI2;
	import x11.extensions.XInput;
	import x11.extensions.XInput2;
	import core.stdc.inttypes : wchar_t;
	
	package int chrCntr;
	package char[32] chrOut;
	
	package int[5] mousePosTracker;	//rootX; rootY; winX; winY; mask
	package int[5] mousePosTracker0;//Previous mouse position
	package WindowH trackedWindow;	//To track the mouse pointer without xinput2
	package WindowH rootReturn;		//Root return window for tracking
	package WindowH	childReturn;	//Child return window for tracking
	shared static this() {
		
	}
	///X11 input handling, no input extensions, only used when xinput2 is not available
	package int poll_x11_RegularIO(ref InputEvent output) nothrow @nogc @system {
		if (trackedWindow) {
			if (XQueryPointer(OSWindow.mainDisplay, trackedWindow, &rootReturn, &childReturn, &mousePosTracker[0], 
					&mousePosTracker[1], &mousePosTracker[2], &mousePosTracker[3], cast(uint*)&mousePosTracker[4]) == 0) {
				if (mousePosTracker != mousePosTracker0) {
					output.type = InputEventType.MouseMove;
					output.handle = childReturn ? childReturn : rootReturn;
					output.source = mouse;
					output.mouseME.x = mousePosTracker[2];
					output.mouseME.y = mousePosTracker[3];
					output.mouseME.xD = mousePosTracker[2] - mousePosTracker0[2];
					output.mouseME.yD = mousePosTracker[3] - mousePosTracker0[3];
					mousePosTracker0 = mousePosTracker;
					return 1;
				}
			}
		}
		tryAgain:
		XEvent xe;
		XNextEvent(OSWindow.mainDisplay, &xe);
		switch (xe.type) {
			case MappingNotify:
				XRefreshKeyboardMapping(&xe.xmapping);
				goto tryAgain;
			case ButtonPress, ButtonRelease:		//Note: Under X11, scrollwheel events are also mapped here.
				output.timestamp = xe.xbutton.time * 1000L;
				output.handle = xe.xbutton.window;
				output.source = mouse;
				trackedWindow = xe.xbutton.window;
				switch (xe.xbutton.button) {
					case 1:
						output.mouseCE.button = MouseButtons.Left;
						break;
					case 2:
						output.mouseCE.button = MouseButtons.Middle;
						break;
					case 3:
						output.mouseCE.button = MouseButtons.Right;
						break;
					case 4, 5, 6, 7:				//Mousescroll events
						if (xe.type != ButtonPress) goto tryAgain;
						output.type = InputEventType.MouseScroll;
						output.mouseSE.x = xe.xbutton.x;
						output.mouseSE.y = xe.xbutton.y;
						switch (xe.xbutton.button) {
							case 4:
								output.mouseSE.yS = -127;
								break;
							case 5:
								output.mouseSE.yS = 127;
								break;
							case 6:
								output.mouseSE.xS = -31;
								break;
							case 7:
								output.mouseSE.xS = 31;
								break;
							default:
								break;
						}
						return 1;
					case 8:
						output.mouseCE.button = MouseButtons.Prev;
						break;
					case 9:
						output.mouseCE.button = MouseButtons.Next;
						break;
					default:
						output.mouseCE.button = cast(ushort)xe.xbutton.button;
						break;
				}
				output.type = InputEventType.MouseClick;
				if (xe.type == ButtonPress) {
					output.mouseCE.dir = 1;
					mouse.lastButtonState |= 1<<(output.mouseCE.button - 1);
				} else {
					output.mouseCE.dir = 0;
					mouse.lastButtonState &= ~(1<<(output.mouseCE.button - 1));
				}
				output.mouseCE.x = xe.xbutton.x;
				output.mouseCE.y = xe.xbutton.y;
				mouse.lastPosition = [xe.xbutton.x, xe.xbutton.y];
				return 1;
			case MotionNotify, LeaveNotify:
				output.timestamp = xe.xmotion.time * 1000L;
				output.handle = xe.xmotion.window;
				trackedWindow = xe.xmotion.window;
				output.source = mouse;
				output.type = InputEventType.MouseMove;
				output.mouseME.x = xe.xmotion.x;
				output.mouseME.y = xe.xmotion.y;
				output.mouseME.xD = xe.xmotion.x - mouse.lastPosition[0];
				output.mouseME.yD = xe.xmotion.y - mouse.lastPosition[1];
				output.mouseME.buttons = (((xe.xmotion.state & 0x1f_00)>>8)&0x07) | (((xe.xmotion.state & 0x1f_00)>>12)&0x18);
				mouse.lastPosition = [xe.xmotion.x, xe.xmotion.y];
				return 1;
			case KeyPress, KeyRelease:
				output.timestamp = xe.xkey.time * 1000L;
				output.handle = xe.xkey.window;
				output.source = keyb;
				keyb.setModifiers(xe.xkey.state);
				//keyb.updateKeybMods(keyb, xe.xkey.keycode);
				const uint buttonID = translateKeyCode(xe.xkey.keycode);
				if (keyb.isTextInputEn) {
					import x11.keysym;
					
					memset(chrOut.ptr, 0, chrOut.length);
					chrCntr = 0;
					OSWindow window = OSWindow.byRef(output.handle);
					debug assert(window);
					KeySym ks;// = XKeycodeToKeysym(OSWindow.mainDisplay, cast(ubyte)xe.xkey.keycode, xe.xkey.state);
					int count = XLookupString(&xe.xkey, chrOut.ptr, 1, &ks, null);
						
					keyb.processTextCommandEvent(output, buttonID, 1);
					if (output.type != InputEventType.init) {
						if (xe.type == KeyPress) return 1;//Event is text command key
						else goto tryAgain;
					}
					output.type = InputEventType.TextInput;
					XIC inputContext = window.ic;
					if (count && inputContext !is null) {
						Status status;
						count = Xutf8LookupString(inputContext, &xe.xkey, chrOut.ptr, 4, &ks, &status);
					}
					
					while (chrOut[chrCntr] && chrCntr + 1 < chrOut.length) {
						chrCntr++;
					}
					if (!chrCntr) {
						output.type = InputEventType.Keyboard;
						output.button.auxF = float.nan;
						output.button.id = buttonID;
						output.button.aux = keyb.getModifiers();
						output.button.dir = xe.type == KeyPress ? 1 : 0;
					} else if (xe.type != KeyPress) {
						goto tryAgain;
					} else {
						output.textIn = TextInputEvent(chrOut.ptr, chrCntr, false);
					}
					
					//XFree(strOut);
				} else {
					output.type = InputEventType.Keyboard;
					output.button.auxF = float.nan;
					output.button.id = buttonID;
					output.button.aux = keyb.getModifiers();
					output.button.dir = xe.type == KeyPress ? 1 : 0;
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
				return 0;
		}
	}
	package int poll_x11_xInputExt(ref InputEvent output) nothrow @nogc {
		return 0;
	}
}
