module iota.etc.vers;

version (iota_use_utf8) {
    alias io_str_t = string;
    alias io_chr_t = char;
    public import std.utf : toUTF8;
    alias toIOTAString = toUTF8;
} else {
    alias io_str_t = dstring;
    alias io_chr_t = dchar;
    public import std.utf : toUTF32;
    alias toIOTAString = toUTF32;
}