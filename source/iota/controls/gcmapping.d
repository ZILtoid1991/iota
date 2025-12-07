module iota.controls.gcmapping;
import iota.controls.gamectrl;
import iota.controls.types;
import std.string : toStringz, fromStringz, splitLines, split;

/**
 * Defines a mapping between the OS API and the directmedia layer.
 */
package struct RawGCMapping {
	ushort type;		///Type identifier
	ushort flags;	///Flags related to translation, e.g. resolution, hat number, hat direction
	ushort inNum;	///Input axis/button number, or hat state
	ushort outNum;	///Output axis/button number
	this (ushort type, ushort flags, ushort inNum, ushort outNum) @safe @nogc nothrow {
		this.type = type;
		this.flags = flags;
		this.inNum = inNum;
		this.outNum = outNum;
	}
	this (string src, ushort outNum, bool isButtonTarget = false) @safe @nogc nothrow {
		switch (src[0]) {
		case 'a':
			if (isButtonTarget) type = RawGCMappingType.AxisToButton;
			else type = RawGCMappingType.Axis;
			inNum = cast(ubyte)parseNum(src[1..$]);
			break;
		case 'b':
			type = RawGCMappingType.Button;
			inNum = cast(ubyte)parseNum(src[1..$]);
			break;
		case 'h':
			type = RawGCMappingType.Hat;
			flags = cast(ubyte)parseNum(src[1..2]);
			inNum = cast(ubyte)parseNum(src[3..$]);
			break;
		default: break;
		}
		this.outNum = outNum;
	}
}
package enum RawGCMappingType : ubyte {
	init,
	Button,
	Axis,
	Trigger,
	Hat,
	AxisToButton,
	Axis8Bit,
}
/**
 * Parses SDL-compatible Game Controller mapping data.
 * Params:
 *   table = Table, where the data should be read from.
 *   uniq = Unique identifier of the game controller.
 * Returns: A table for mapping, or null if mapping couldn't be found.
 */
package RawGCMapping[] parseGCM(string table, string uniq) @safe {
	import std.algorithm : countUntil;
	string[] lines = table.splitLines();
	foreach (string line ; lines) {
		string[] vals = line.split(",");
		if (vals.length > 2) {
			if (vals[0] == uniq){
				RawGCMapping[] result;
				foreach (string val ; vals) {
					sizediff_t colonIndex = countUntil(val, ":");//used to separate data identifier from the data itself
					if (colonIndex <= 0) continue;	//Safety feature for when field does not have a colon (arbitrary data?)
					switch (val[0..colonIndex]) {
					case "a", "South":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.South, true);
						break;
					case "b", "East":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.East, true);
						break;
					case "x", "West":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.West, true);
						break;
					case "y", "North":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.North, true);
						break;
					case "dpup", "DPadUp":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.DPadUp, true);
						break;
					case "dpdown", "DPadDown":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.DPadDown, true);
						break;
					case "dpleft", "DPadLeft":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.DPadLeft, true);
						break;
					case "dpright", "DPadRight":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.DPadRight, true);
						break;
					case "leftshoulder", "LeftShoulder":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.LeftShoulder, true);
						break;
					case "rightshoulder", "RightShoulder":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.RightShoulder, true);
						break;
					case "lefttrigger", "LeftTrigger":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.LeftTrigger, true);
						break;
					case "righttrigger", "RightTrigger":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.RightTrigger, true);
						break;
					case "back", "LeftNav":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.LeftNav, true);
						break;
					case "start", "RightNav":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.RightNav, true);
						break;
					case "guide", "Home":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.Home, true);
						break;
					case "leftstick", "LeftThumbstick":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.LeftThumbstick, true);
						break;
					case "rightstick", "RightThumbstick":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.RightThumbstick, true);
						break;
					case "l4", "L4":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.L4, true);
						break;
					case "r4", "R4":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.R4, true);
						break;
					case "l5", "L5":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.L5, true);
						break;
					case "r5", "R5":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.R5, true);
						break;
					case "share", "Share":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.Share, true);
						break;
					case "touchpadclick", "TouchpadClick":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.TouchpadClick, true);
						break;
					case "btnv", "Btn_V":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.Btn_V, true);
						break;
					case "btnvi", "Btn_VI":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerButtons.Btn_VI, true);
						break;
					case "leftx", "LeftThumbstickX":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerAxes.LeftThumbstickX, true);
						break;
					case "lefty", "LeftThumbstickY":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerAxes.LeftThumbstickY, true);
						break;
					case "rightx", "RightThumbstickX":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerAxes.RightThumbstickX, true);
						break;
					case "righty", "RightThumbstickY":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerAxes.RightThumbstickY, true);
						break;
					case "accelx", "AccelX":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerAxes.AccelX, true);
						break;
					case "accely", "AccelY":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerAxes.AccelY, true);
						break;
					case "accelz", "AccelZ":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerAxes.AccelZ, true);
						break;
					case "rotatex", "RotateX":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerAxes.RotateX, true);
						break;
					case "rotatey", "RotateY":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerAxes.RotateY, true);
						break;
					case "rotatez", "RotateZ":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerAxes.RotateZ, true);
						break;
					case "touchpadx", "TouchpadX":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerAxes.TouchpadX, true);
						break;
					case "touchpady", "TouchpadY":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerAxes.TouchpadY, true);
						break;
					case "rtouchpadx", "RTouchpadX":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerAxes.RTouchpadX, true);
						break;
					case "rtouchpady", "RTouchpadY":
						result ~= RawGCMapping(val[colonIndex+1..$], GameControllerAxes.RTouchpadY, true);
						break;
					default:
						break;
					}
				}
				return result;
			}
		}
	}
	return null;
}
package int parseNum(string num) @nogc @safe nothrow {
	int result;
	foreach (char c ; num) result = (result * 10) + (c - '0');
	return result;
}
