module iota.controls.polling;

public import iota.controls.types;
public import iota.controls.keyboard;
public import iota.controls.mouse;
import iota.window.oswindow;
import iota.controls.keybscancodes;

/** 
 * Polls all input devices, and returns the found events in a given order.
 * Params:
 *   output = The input event that was found. 
 * Returns: 1 if an event has been polled, 0 if no events left. Other values are error codes.
 */
public int poll(ref InputEvent output) nothrow {
    
    return 0;
}
Keyboard keyb;          ///Main keyboard, or the only keyboard on APIs not supporting differentiating between keyboards.
Mouse mouse;            ///Main mouse, or the only mouse on APIs not supporting differentiating between mice.
version (Windows) {
    import core.sys.windows.windows;
	import core.sys.windows.wtypes;
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
    ///Polls event using legacy API under Windows (no RawInput)
    package int poll_win_LegacyIO(ref InputEvent output) nothrow @nogc {
        MSG msg;
        BOOL bret = PeekMessageW(&msg, OSWindow.refCount[winCount].getHandle, 0, 0, PM_REMOVE);
		if (bret) {
            output.timestamp = msg.time;
			output.handle = OSWindow.refCount[winCount].getHandle;
            auto message = msg.message & 0xFF_FF;
            if (!(Keyboard.isMenuKeyDisabled() && (message == WM_SYSKEYDOWN || message == WM_SYSKEYUP)) || 
					(Keyboard.isMetaKeyDisabled() && (message == WM_KEYDOWN || message == WM_KEYUP) && (msg.wParam == VK_LWIN 
					|| msg.wParam == VK_RWIN)) ||
					(Keyboard.isMetaKeyCombDisabled() && (message == WM_KEYDOWN || message == WM_KEYUP) && 
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
    
		    	case WM_MOVE:
		    		output.type = InputEventType.WindowMove;
		    		output.window.x = LOWORD(msg.lParam);
		    		output.window.y = HIWORD(msg.lParam);
		    		output.window.width = 0;
		    		output.window.height = 0;
		    		output.source = this;
		    		break;
		    	case WM_SIZE:
		    		output.type = InputEventType.WindowResize;
		    		output.window.x = 0;
		    		output.window.y = 0;
		    		output.window.width = LOWORD(msg.lParam);
		    		output.window.height = HIWORD(msg.lParam);
		    		output.source = this;
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
        }
        return 0;
    }

    package int poll_win_RawInput(ref InputEvent output) nothrow @nogc {
        return 0;
    }
}
