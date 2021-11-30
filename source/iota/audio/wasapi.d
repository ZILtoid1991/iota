module iota.audio.wasapi;

version (Windows):

package import wasapi;

package static MMDevices wasapiHandler;
package static MMDevice[] wasapiOutDevices;

import iota.audio.device;

/** 
 * Implements a WASAPI device, and can create both input and output streams for such devices.
 */
public class WASAPIDevice : AudioDevice {
	/// References the backend
	protected IMMDevice		backend;
	/** 
	 * Creates an instance that refers to the backend. 
	 */
	this(IMMDevice backend) {
		this.backend = backend;
	}
	/** 
	 * Creates an OutputStream specific to the given driver/device, with the requested parameters, then returns it. Or
	 * null in case of an error.
	 */
	public override OutputStream createOutputStream() {
		return null;
	}
}