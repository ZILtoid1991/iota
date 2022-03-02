module iota.audio.midiin;

public abstract class MidiInput {
    public abstract ubyte[4] read();
}