# iota
Input-output (audio, controls, etc) library for D. Intended as a D language native replacement for SDL, SFML, etc.

# Current state

|Component                 |Windows                             |Linux                               |
|--------------------------|------------------------------------|------------------------------------|
|Audio                     |Preliminary, output stream works    |Output works + some issues          |
|MIDI                      |Input+Output, with some caveat      |Not yet implemented                 |
|Keyboard                  |Works                               |Not yet implemented                 |
|Mouse                     |Works                               |Not yet implemented                 |
|Pen Tablet                |Not yet implemented                 |Not yet implemented                 |
|Game controllers          |Not yet implemented                 |Not yet implemented                 |
|Windowing                 |A bit buggy                         |Not yet implemented                 |

MacOSX is not yet supported due to lack of hardware. Please consider contributing to this project!

## Audio

### Windows

Only WASAPI output is supported at the moment, but it seems to work correctly. Buffer overflow protection is done through spinning in a loop alongside with the wait. It's not nice, but works, and eliminates possible issues from inconsistent buffer sizes.

Deinitialization is automatic through destructors and bug free. Windows-specific error-codes are handled as should.

### Linux

Error handling is quite preliminary with one having to rely on returned error codes. ALSA documentation is quite scarce, and often don't contain more than what one can get out from function names, let alone the possible returned error codes. Device selection might contain non-PCM devices, so initializing with default device (-1) is recommended instead for now.

Audio is tested and confirmed working on 64 bit Raspberry Pi devices, which probably means all 64 bit ARM SoCs are supported under Linux.

## MIDI

### Windows

Both input and output works, but might suffer from some caveat that stems from the Windows MIDI API. There's a chance that calling a MIDI system function within the MIDI input callback will cause a lockup.

## Others

Preliminary work on keyboard, mouse, etc. controls have been started.

# Examples

See `testsource/app.d` for audio!