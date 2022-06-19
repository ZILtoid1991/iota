module iota.window.windows;

/* version (Windows) {
	import core.sys.windows.windows;
	import core.sys.windows.wtypes;
    import core.thread;
    ///Multi-threaded event loop system, because MS wants you to write your program in a way that it would be hard if not 
    ///impossible to port to other systems.
    public class MessageLoopThread : Thread {
        void msgLoop() {
            MSG msg;
            BOOL bRet;
            while (true) {
                bRet = GetMessageW();
            }
        }

    }
} */