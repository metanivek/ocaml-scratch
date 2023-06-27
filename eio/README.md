``` sh
# dune exec ./main.exe -- ./test.dat
Unix.read
0.0383ms        0.0008ms
Index.pread
0.0173ms        0.0003ms
Eio.File.pread
0.0591ms        0.0012ms
```
