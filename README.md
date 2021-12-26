# iota
Input-output (audio, controls, etc) library for D. Intended as a D language native replacement for SDL, SFML, etc.

# Current state

|Component                 |Windows                             |Linux                               |
|--------------------------|------------------------------------|------------------------------------|
|Audio                     |Preliminary, output stream works    |Under development                   |
|MIDI                      |Not yet implemented                 |Not yet implemented                 |
|Keyboard                  |Not yet implemented                 |Not yet implemented                 |
|Mouse                     |Not yet implemented                 |Not yet implemented                 |
|Game controllers          |Not yet implemented                 |Not yet implemented                 |

## Audio

### Windows

Only WASAPI output is supported at the moment, but it seems to work correctly. Buffer overflow protection is done through spinning in a loop alongside with the wait. It's not nice, but works, and eliminates possible issues from inconsistent buffer sizes.

Deinitialization is automatic through destructors and bug free. Windows-specific error-codes are handled as should.

# Examples

See `testsource/app.d` for audio!