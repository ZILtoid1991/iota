import std.stdio;
import iota.audio.device;
import iota.audio.output;

void main() {
	version (Windows) {
		writeln("Please select driver:");
		writeln("1) Windows Audio Stream API");
	}
	string arg = readln();
}
