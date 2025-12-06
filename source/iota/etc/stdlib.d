module iota.etc.stdlib;

import numem;
import core.stdc.string;

string fromCSTR(const(char)* cstr) @nogc nothrow {
	size_t len = strlen(cstr);
	char[] result = nu_malloca!char(len);
	memcpy(result.ptr, cstr, len);
	return cast(string)result;
}

T[] mutCopy(T)(const T[] src) @nogc nothrow {
	T[] result = nu_malloca!T(src.length);
	memcpy(result.ptr, src.ptr, src.length * T.sizeof);
	return result;
}
