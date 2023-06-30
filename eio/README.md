``` sh
# dune exec ./main.exe -- ./test.dat
Unix.read
0.0461ms        0.0009ms
Index.pread
0.0221ms        0.0004ms
Eio.File.pread
0.0681ms        0.0014ms
Eio.File.pread (with polling)
0.2318ms        0.0046ms
Lwt_unix.pread
0.6481ms        0.0130ms
```
