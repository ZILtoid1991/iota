# Miscellaneous Windows related things

## App manifest file

One should supply an `Application.manifest` file for Windows and compile it as a resource using the `resources.rc` file.

The command to compile the resources are:

```
windres resources.rc -o resources.obj
```

Applications work without it, but will have some limitiations, e.g. an older style GUI.