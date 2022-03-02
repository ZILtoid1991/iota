module iota.audio.midi;

import iota.audio.types;

version (Windows) {
    import core.sys.windows.windows;
    import core.sys.windows.wtypes;
}

package string[] inDevs;
package string[] outDevs;

public int initMIDI() {
    version (Windows) {
        uint nOutDevices = midiOutGetNumDevs();
        uint nInDevices = midiInGetNumDevs();
    }
}