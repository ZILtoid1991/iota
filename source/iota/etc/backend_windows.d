module iota.etc.backend_windows;

version (Windows):

import core.sys.windows.windows;
import core.sys.windows.objidl;
import core.sys.windows.wtypes;

/*
 * Contains bindings to the audio module for Windows NT-based systems. (WASAPI, DirectSound)
 *
 * Some parts are borrowed from the previous WASAPI library.
 */

/// Helper function to create GUID from string.
///
/// BCDE0395-E52F-467C-8E3D-C4579291692E -> GUID(0xBCDE0395, 0xE52F, 0x467C, [0x8E, 0x3D, 0xC4, 0x57, 0x92, 0x91, 0x69, 0x2E])
GUID makeGuid(string str)() {
	static assert(str.length==36, "Guid string must be 36 chars long");
	enum GUIDstring = "GUID(0x" ~ str[0..8] ~ ", 0x" ~ str[9..13] ~ ", 0x" ~ str[14..18] ~
			", [0x" ~ str[19..21] ~ ", 0x" ~ str[21..23] ~ ", 0x" ~ str[24..26] ~ ", 0x" ~ str[26..28]
			~ ", 0x" ~ str[28..30] ~ ", 0x" ~ str[30..32] ~ ", 0x" ~ str[32..34] ~ ", 0x" ~ str[34..36] ~ "])";
	return mixin(GUIDstring);
}
