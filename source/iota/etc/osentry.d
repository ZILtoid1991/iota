module iota.etc.osentry;

/*
 * This module contains operation system specific entry points.
 *
 * Just put `mixin(IOTA_OSENTRY)` or `mixin(IOTA_OSENTRY_CMDARGS)` into your app.d file, then rename your main function
 * to `prgEntry`.
 */

version (Windows) {
	alias iota_cmd_arg_t = wstring[];
	import core.sys.windows.windows;
	///hInstance is reference counted here instead of using various workarounds to get it.
	public static HINSTANCE	mainInst;
	///Creates a generic entry point with no command line arguments.
	static enum string IOTA_OSENTRY = q{
		import core.runtime;
		import core.sys.windows.windows;
		import std.string;
		extern (Windows)
		int WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
					LPSTR lpCmdLine, int nCmdShow) {
			int result;
			mainInst = hInstance;
			try	{
				Runtime.initialize();
				result = prgEntry();
				Runtime.terminate();
			} catch (Throwable e) {
				MessageBoxA(null, e.toString().toStringz(), null,
							MB_ICONEXCLAMATION);
				result = 0;     // failed
			}

			return result;
		}

		
	};
	///Creates a generic entry point with command line arguments.
	///Should be unicode compatible.
	static enum string IOTA_OSENTRY_CMDARGS = q{
		import core.runtime;
		import core.sys.windows.windows;
		import core.sys.windows.shellapi;
		import std.string;
		extern (Windows)
		int wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
					LPWSTR lpCmdLine, int nCmdShow) {
			int result;
			mainInst = hInstance;
			try	{
				Runtime.initialize();
				wstring[] args;
				int numArgs;
				LPWSTR* argList = CommandLineToArgvW(lpCmdLine, &numArgs);
				for (int i ; i < numArgs ; i++) {
					args ~= fromStringz(argList[i]).idup;
				}

				result = prgEntry(args);
				Runtime.terminate();
			} catch (Throwable e) {
				MessageBoxA(null, e.toString().toStringz(), null,
							MB_ICONEXCLAMATION);
				result = 0;     // failed
			}

			return result;
		}

		
	};
}