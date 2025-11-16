module iota.etc.stdlib;

import numem;
import core.stdc.string;

string fromCSTR(const(char)* cstr) @nogc nothrow {
	size_t len = strlen(cstr);
	char[] result = nu_malloca!char(len);
	memcpy(result.ptr, cstr, len);
	return cast(string)result;
}
