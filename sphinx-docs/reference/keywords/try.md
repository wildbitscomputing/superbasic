# try

Tries to execute a command, usually involving the Kernel, returning an error
code if it fails or 0 if successful. Currently supports `BLOAD` and `BSAVE`.

```basic
100   try bload "myfile",$10000 to ec
110   print ec
```
