module iota.controls;

public import iota.controls.types;

///Contains all input devices, including some invalidated ones.
package static InputDevice[]    deviceList;
///Contains the polling position.
package static size_t           pollPos;

/** 
 * Polls all input devices one by one.
 * Params:
 *   output = The input event is returned here.
 * Returns: 1 if there's more, 0 if all input events have been processed, or a specific error code.
 */
public int pollInputs(ref InputEvent output) @nogc nothrow {
	if (!deviceList.length) return EventPollStatus.NoDevsFound;
	if (pollPos == deviceList.length) pollPos = 0;
	int statusCode;
	while (pollPos < deviceList.length && !statusCode) {
		statusCode = deviceList[pollPos].poll(output);
		if (!statusCode) pollPos++;				//Step to next device, this one has no more events
	}
	if (statusCode != 1) return statusCode;	//There's an error code from the current input device
	return pollPos == deviceList.length ? EventPollStatus.Done : EventPollStatus.HasMore;
}
public int removeInvalidDevs() nothrow {
	return 0;
}