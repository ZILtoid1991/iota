# 0.4.0-beta.5

* Libevdev support now works with select game controllers.
* GameInput support added on Windows.

# 0.4.0-beta.4

* Added wrappers for `wglCreateContextAttribsARB` and `glXCreateContextAttribsARB`.

# 0.4.0-beta.3

* Preliminary Mac support

# 0.4.0-beta.2

* Fixed an issue with Windows not accounting for the frames when creating a window.

# 0.4.0-beta

* Fixed a bug that caused x11 to lock up until new event is generated.
* Basic 32 bit icons now work on Windows, mask generation doesn't.

# 0.4.0-alpha

* Fixed bug regarding of x11 windows. Also `OSWindow` now requires manual destruction via `destroy(osWindowInstance)` to ensure the destructor runs as it should.
* Added preliminary support for libevdev (does not work, hangs aplication).
* Added preliminary support wor window icons under Windows (does not work, documentation on 32 bit icons does not exist!).

# 0.3.2

# 0.3.1

* Fixed issue regarding of an initializer ctor causing crashes on Windows if compiled with LDC2.
* Added some extra cursor types.
* Known bug: Hotplugging xinput devices don't work. Removal works, adding one does not.

# 0.3.0

* Added cursor support.
* Added fullscreen and preliminary video mode (Windows only) support.
* Dropped UTF-32 support and making UTF-8 the default.
* Fixed issues with wrong keycodes on Linux.

# 0.3.0-beta.2

* Resizing fixed for OpenGL under Linux.

# 0.3.0-beta

* Basic OpenGL support.
* Fixed windowing issue of having an old-style GUI display.

# 0.3.0-alpha2

* Linux MIDI support added.
* Improved ALSA device support (it can now differentiate between multiple devices).

# 0.3.0-alpha1

* High-precision timestamps have been made standard.

# 0.3.0-alpha

* Control I/O on Windows works without many bugs using legacy API, RawInput works with a bug that doesn't allow it to differentiate between devices.
* XInput support for Windows added.
* Windowing added, but some features are not yet implemented.

# 0.2.0

* Added MIDI input and output for Windows.
* Preliminary work on control I/O has begun.
* Audio testcase is now properly named.

# 0.1.0

* Added `AudioSpecs.toString()`
* Added enum `PredefinedFormats`
* Added ALSA implementation.

# 0.1.0-alpha

Initial release.
