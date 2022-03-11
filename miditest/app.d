import std.stdio;
import std.conv : to;
import iota.audio.midi;
import core.thread;

void main(string[] args) {
	int status = initMIDI();
	if (status) {
		writeln("MIDI initialization failed. Error code:", status);
		return;
	}
	writeln("Available inputs:");
	foreach (size_t i, string s ; getMIDIInputDevs()) {
		writeln(i,") ", s);
	}
	int inputDev = to!int(readln()[0..$-1]);
	MIDIInput midiIn;
	writeln("Available outputs:");
	writeln("c) Console");
	foreach (size_t i, string s ; getMIDIOutputDevs()) {
		writeln(i,") ", s);
	}
	string outputDev = readln();
	
	status = openMIDIInput(midiIn, inputDev);
	if (status) {
		writeln("MIDI input initialization failed. Error code:", status);
		return;
	}
	if (outputDev == "c\n") {
		status = midiIn.start();
		if (status) {
			writeln("Error starting MIDI input. Error code:", status);
			return;
		}
		writeln("MIDI read begun!");
		for (size_t c ; c < 1000 ; c++) {
			ubyte[] midiBuf = midiIn.read();
			if (midiBuf.length)
				writeln(midiBuf);
			Thread.sleep(dur!"msecs"(10));
		}
		writeln("MIDI read ended without a fatal error!");
	} else {
		MIDIOutput midiOut;
		status = openMIDIOutput(midiOut, to!uint(outputDev[0..$-1]));
		if (status) {
			writeln("MIDI output initialization failed. Error code:", status);
			return;
		}
		status = midiIn.start();
		if (status) {
			writeln("Error starting MIDI input. Error code:", status);
			return;
		}
		status = midiOut.start();
		if (status) {
			writeln("Error starting MIDI output. Error code:", status);
			return;
		}
		writeln("MIDI input redirection begun!");
		for (size_t c ; c < 1000 ; c++) {
			ubyte[] midiBuf = midiIn.read();
			if (midiBuf.length)
				midiOut.write(midiBuf);
			Thread.sleep(dur!"msecs"(10));
		}
	}
}