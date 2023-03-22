module iota.audio.backend.linux2;

version(linux):

import iota.audio.backend.linux;
import core.stdc.stdlib;
/** 
 * Lists all device names for ALSA
 * Params:
 *   devname = Device name. `pcm`: PCM devices, `rawmidi`: MIDI devices.
 *   direction = Device direction.
 * Returns: An array of strings with the names of the devices
 */
string[] listdev(char* devname, out ubyte[] direction) {
	import std.string : fromStringz;
	char**	hints;
	int		err;
	char**	n;
	char*	name;
	char*	dir;
	string[] result;

	//Enumerate sound devices
	err = snd_device_name_hint(-1, devname, cast(void***)&hints);
	if (err != 0) {
		return null;
	}

	n = hints;
	while (*n) {
		name = snd_device_name_get_hint(*n, "NAME");
		dir = snd_device_name_get_hint(*n, "IOID");
		result ~= fromStringz(name).idup;
		if (fromStringz(dir) == "Input") {
			direction ~= 0x01;
		} else {
			direction ~= 0x00;
		}
		free(name);
		free(dir);
		n++;
	}
	snd_device_name_free_hint(hints);
	return result;
}