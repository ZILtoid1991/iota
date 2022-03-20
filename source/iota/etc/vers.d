module iota.etc.vers;

version (iota_use_utf8) {
    alias io_str_t = string;
    alias io_chr_t = char;
} else {
    alias io_str_t = dstring;
    alias io_chr_t = dchar;
}