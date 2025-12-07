# iota
Input-output (audio, controls, etc) library for D. Intended as a D language native replacement for SDL, SFML, etc.

# Current state

|Component                 |Windows                             |Linux                               |MacOSX                              |
|--------------------------|------------------------------------|------------------------------------|------------------------------------|
|Audio                     |Preliminary, output stream works    |ALSA: janky, pipewire: coming soon  |N/A                       |
|MIDI                      |Input+Output, with some caveat      |Input tested, output should also work|N/A                    |
|Keyboard                  |Legacy: Works; Raw: Works           |X11: works; evdev: in progress      |Implemented              |
|Mouse                     |Legacy: Works; Raw: Works           |X11: works; evdev: in progress      |Implemented              |
|Mouse cursors             |Working                             |Working                             |Implemented              |
|Pen Tablet                |Not yet implemented                 |Not yet implemented                 |Not yet implemented      |
|Game controllers          |XInput: working; Raw: in progress; GameInput: limited |Evdev: limited |N/A         |
|Windowing                 |Working                             |X11: Working                        |Implemented              |
|Fullscreen window support |Working (video modes untested)      |X11: Working                        |Implemented              |
|OpenGL output             |Working                             |Working                             |Implemented              |

MacOSX support just got added!

Wayland is not supported yet as XWayland provides sufficient compatibility so far.

## Audio

### Windows

Only WASAPI output is supported at the moment, but it seems to work correctly. Buffer overflow protection is done through spinning in a loop alongside with the wait. It's not nice, but works, and eliminates possible issues from inconsistent buffer sizes.

Deinitialization is automatic through destructors and mostly bug free. Windows-specific error-codes are handled as should. Device disconnection does not work. Selecting any audio device besides the default one (-1) does not work

### Linux

Error handling is quite preliminary with one having to rely on returned error codes. ALSA device names are now handled.

Audio is tested and confirmed working on 64 bit Raspberry Pi devices, which probably means all 64 bit ARM SoCs are supported under Linux.

NOTE: Due to the janky nature of ALSA, it'll be only be kept as a last-resort compatibility measure.

## MIDI

### Windows

Both input and output works, but might suffer from some caveat that stems from the Windows MIDI API. There's a chance that calling a MIDI system function within the MIDI input callback will cause a lockup.

### Linux

Input tested, output also should work.

Note: Must be deinitialized manually.

## Controls

### Windows

Keyboard and mouse works without much issues while using the legacy API. A known bug is that it sometimes generates an additional empty event if the Alt key is pressed (because some people thought it's a good idea to dedicate a whole modifier key for the menubar), this can be mitigated by supplying the window a `WindowCfgFlags.IgnoreMenuKey`. Menubars are not implemented currently.

XInput is implemented and works.

GameInput works, but capability is currently limited to Xbox One gamepads. Some further capabilities are only supported via exposing some low-level stuff, such as the Dualsense vibrohaptics, which are handled as audio stream devices, but sensors and other things will need more work.

#### Raw input

This library is (mostly) equipped to handle raw input data. There was a bug that made handle lookup not working, this is no longer the case.

I plan to make game controllers working via RawInput, but that will be a bit more work due to scarce documentation...

### Linux

I/O without extensions now works, XInput2 support will be added once I find or someone provides me the API documentation. Quite hard to search, due to same name of what Microsoft has under Windows for Xbox gamepads.

#### Evdev

Libevdev support is somewhat limited.

- No input device detection due to missing feature from the library, only game controllers are supported at the moment. It is recommended that you disable any devices for your program that are not game controllers.
- Analog range is adjusted for XBox controllers, at least Dualsense controller analog range is not supported due to missing feature from the library.
- Haptics not supported at the moment.
- More than one input device block each other -> more threads will be needed.
- There's still some chance of hanging after the application was terminated -> better method of shutting down threads will be needed.
- SDL-like gameinputdb parsing is not fully implemented at the moment.

## Windowing

### Windows

Got most of the basic stuff working. Bug related to window styles fixed.

Fullscreen is working, video modes are untested as of now.

### Linux

Linux is using X11 for its windowing and I/O.

## OpenGL

It works for what I've tested it, Windows parts might have their own unique challenges later on.

# Examples

See `testsource/app.d` for audio, `inputtest/app.d` for input and basic windowing, and `miditest/app.d` for MIDI.

# To do list

* Add option for hiding mouse.
* Add Vulkan support.
* Add support for alternative runtimes/memory managers.
