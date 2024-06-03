# Miscellaneous Windows related things

## App manifest file

One should supply an `Application.manifest` file for Windows and compile it as a resource using the `resources.rc` file.

The command to compile the resources are:

```
rc resources.rc
```

One can add it to an SDLang package as such:

```s
dflags "resources.res" platform="windows"
```

For JSON packages, it works something like this:

```json

```

Applications work without it, but will have some limitations, e.g. an older style GUI (not always applicable).

NOTE: Do not use Windres alongside of any non-dwarf symbol build tools! The two does not mix well.