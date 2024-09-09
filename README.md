# iota
Input-output (audio, controls, etc) library for D. Intended as a D language native replacement for SDL, SFML, etc.

# Current state

|Component                 |Windows                             |Linux                               |
|--------------------------|------------------------------------|------------------------------------|
|Audio                     |Preliminary, output stream works    |ALSA: janky, pipewire: coming soon  |
|MIDI                      |Input+Output, with some caveat      |Input tested, output should also work|
|Keyboard                  |Legacy: Works; Raw: Works           |X11: mostly works                   |
|Mouse                     |Legacy: Works; Raw: Works           |X11: working                        |
|Pen Tablet                |Not yet implemented                 |Not yet implemented                 |
|Game controllers          |XInput: working                     |Not yet implemented                 |
|Windowing                 |Working                             |X11: Working                        |
|Fullscreen window support |Working (video modes untested)      |Does not work                       |
|OpenGL output             |Working                             |Working                             |

MacOSX is not yet supported due to lack of hardware. Please consider contributing to this project!

## Audio

### Windows

Only WASAPI output is supported at the moment, but it seems to work correctly. Buffer overflow protection is done through spinning in a loop alongside with the wait. It's not nice, but works, and eliminates possible issues from inconsistent buffer sizes.

Deinitialization is automatic through destructors and bug free. Windows-specific error-codes are handled as should.

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

#### Raw input

This library is (mostly) equipped to handle raw input data. There was a bug that made handle lookup not working, this is no longer the case.

I plan to make game controllers working via RawInput, but that will be a bit more work due to scarce documentation...

### Linux

I/O without extensions now works, XInput2 support will be added once I find or someone provides me the API documentation. Quite hard to search, due to same name of what Microsoft has under Windows for Xbox gamepads.

## Windowing

### Windows

Got most of the non-basic stuff working. Bug related to window styles fixed.

### Linux

Linux is using X11 for its windowing and I/O. Has one known bug:
* When the window is closed, X11 replies with `X connection to :0.0 broken (explicit kill or server shutdown).`

## OpenGL

It works for what I've tested it, Windows parts might have their own unique challenges later on.

# Examples

See `testsource/app.d` for audio, `inputtest/app.d` for input and basic windowing, and `miditest/app.d` for MIDI.