# iota
Input-output (audio, controls, etc) library for D. Intended as a D language native replacement for SDL, SFML, etc.

# Current state

|Component                 |Windows                             |Linux                               |
|--------------------------|------------------------------------|------------------------------------|
|Audio                     |Preliminary, output stream works    |Output works                        |
|MIDI                      |Input+Output, with some caveat      |Input tested, output should also work|
|Keyboard                  |Legacy: Works; Raw: Buggy           |In progress                         |
|Mouse                     |Legacy: Works; Raw: Buggy           |In progress                         |
|Pen Tablet                |Not yet implemented                 |Not yet implemented                 |
|Game controllers          |XInput : works                      |Not yet implemented                 |
|Windowing                 |A bit buggy                         |In progress                         |
|OpenGL output             |In progress, not working yet        |In progress                         |

MacOSX is not yet supported due to lack of hardware. Please consider contributing to this project!

## Audio

### Windows

Only WASAPI output is supported at the moment, but it seems to work correctly. Buffer overflow protection is done through spinning in a loop alongside with the wait. It's not nice, but works, and eliminates possible issues from inconsistent buffer sizes.

Deinitialization is automatic through destructors and bug free. Windows-specific error-codes are handled as should.

### Linux

Error handling is quite preliminary with one having to rely on returned error codes. ALSA device names are now handled.

Audio is tested and confirmed working on 64 bit Raspberry Pi devices, which probably means all 64 bit ARM SoCs are supported under Linux.

## MIDI

### Windows

Both input and output works, but might suffer from some caveat that stems from the Windows MIDI API. There's a chance that calling a MIDI system function within the MIDI input callback will cause a lockup.

### Linux

Input tested, output also should work.

Note: Must be deinitialized manually.

## Controls

### Windows

Keyboard and mouse works without much issues while using the legacy API. A known bug is that it sometimes generates an additional empty event if the Alt key is pressed (because some people thought it's a good idea to dedicate a whole modifier key for the menubar), this will be fixed in a later release, likely by optionally disabling it.

XInput is implemented and works. There should be a way to detect whether a device is rumble capable or not, but it doesn't work, so it's assumed that all controllers have this capability.

#### Raw input

This library is (mostly) equipped to handle raw input data, but currently it has some bugs. For some reason, it cannot differentiate between input devices at the moment, as all the device handles are null.

## Windowing

### Linux

Linux is using X11 for its windowing and I/O.

# Examples

See `testsource/app.d` for audio, `inputtest/app.d` for input and basic windowing, and `miditest/app.d` for MIDI.