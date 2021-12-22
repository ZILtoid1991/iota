module iota.audio.alsa;

version (linux):

package import iota.audio.backend.linux;

import iota.audio.device;
import iota.audio.output;

import core.time;

import core.stdc.stdlib;

import core.thread;

/// Name of all devices
package static char*[] devicenames;
/// The last ALSA specific error code
public static int lastErrorCode;

/// Automatic cleanup.
shared static ~this() {
	flushNames();
}
/** 
 * Flushes all device names automatically.
 */
package void flushNames() {
	foreach (key ; devicenames)
		free(key);
}
/** 
 * Implements an ALSA device.
 */
public class ALSADevice {
	protected snd_ctl_t*		ctlHandle;
	package this (snd_ctl_t* ctlHandle) {
		this.ctlHandle = ctlHandle;
	}
	~this() {
		snd_ctl_close(ctlHandle);
	}
}