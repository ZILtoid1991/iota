module iota.audio.backend.linux2;

version(linux):

import iota.audio.backend.linux;
import core.stdc.stdlib;
public import iota.audio.types : DeviceDirection;
/** 
 * Lists all device names for ALSA
 * Params:
 *   devname = Device name. "pcm\n": PCM devices, "rawmidi\n": MIDI devices.
 *   direction = Device direction.
 * Returns: An array of strings with the names of the devices
 */
string[] listdev(string devname, out ubyte[] direction) {
	import std.string : fromStringz, toStringz;
	void**	hints;
	int		err;
	char*	name;
	char*	dir;
	string[] result;

	//Enumerate sound devices
	err = snd_device_name_hint(-1, toStringz(devname), &hints);
	if (err == 0) {
		for (int i ; hints[i] ; i++) {
			name = snd_device_name_get_hint(hints[i], "NAME");
			if (name is null) continue;
			dir = snd_device_name_get_hint(hints[i], "IOID");
			result ~= fromStringz(name).idup;
			if (fromStringz(dir) == "Input") {
				direction ~= DeviceDirection.Input;
			} else if (fromStringz(dir) == "Output") {
				direction ~= DeviceDirection.Output;
			} else {
				direction ~= DeviceDirection.IO;
			}
			/+debug {
				import std.stdio;
				writeln(fromStringz(name), ";" , fromStringz(dir));
			}+/
			free(name);
			free(dir);
			
		}
		snd_device_name_free_hint(cast(void**)hints);
	}
	/+debug {
		import std.stdio;
		if (err)
			writeln(fromStringz(snd_strerror(err)));
	}+/
	return result;
}