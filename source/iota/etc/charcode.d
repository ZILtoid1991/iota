module iota.etc.charcode;

/** 
 * Encodes a 32 bit character in UTF-8 format. Useful for translating between system and application level stuff.
 * Params:
 *   c = The character to be encoded
 * Returns: An encoded character sequence if the character could been interpreted as a valid character code, all 
 * zeros otherwise.
 */
char[4] encodeUTF8Char(dchar c) @nogc @safe pure nothrow {
    char[4] result = [0x00, 0x00, 0x00, 0x00];
    if (c < 0x80) {
        result[0] = cast(char)c & 0x7F;
    } else if (c < 0x800) {
        result[0] = cast(char)(c>>6) & 0x1F | 0xC0;
        result[1] = cast(char)c & 0x3F | 0x80;
    } else if (c < 0x01_00_00) {
        result[0] = cast(char)(c>>12) & 0x0F | 0xE0;
        result[1] = cast(char)(c>>6) & 0x3F | 0x80;
        result[2] = cast(char)c & 0x3F | 0x80;
    } else if (c < 0x11_00_00) {
        result[0] = cast(char)(c>>18) & 0x07 | 0xF0;
        result[1] = cast(char)(c>>12) & 0x3F | 0x80;
        result[2] = cast(char)(c>>6) & 0x3F | 0x80;
        result[3] = cast(char)c & 0x3F | 0x80;
    }

    return result;
}
/** 
 * Decodes a UTF-8 character into a 32 bit one. Useful for translating between system and application level stuff.
 * Params:
 *   c = The character string to be decoded
 * Returns: The decoded character.
 */
dchar decodeUTF8Char(char[4] c) @nogc @safe pure nothrow {
    dchar result;
    switch (c[0] & 0xf0) {
        case 0xc0, 0xd0:
            result = (c[1] & 0x3f) | ((c[0] & 0x1f)<<6);
            break;
        case 0xe0:
            result = (c[2] & 0x3f) | ((c[1] & 0x3f)<<6) | ((c[0] & 0x0f)<<12);
            break;
        case 0xf0:
            result = (c[3] & 0x3f) | ((c[2] & 0x3f)<<6) | ((c[1] & 0x3f)<<12) | ((c[0] & 0x07)<<18);
            break;
        default:
            result = c[0];
            break;
    }

    return result;
}