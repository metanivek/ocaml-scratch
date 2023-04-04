quick timings of array vs bigarray perf, summation and random samples

example output:
``` sh
# dune exec arrays/main.exe

Sum 1000 integers
 [Array#fold]                      6.452000s
 [Array#safe]                      0.761000s
 [Array#unsafe]                    0.531000s
 [BigArray#safe]                   15.919000s
 [BigArray#unsafe]                 14.647000s

Sample 100 out of 1000
 [Array#safe_sample]               0.421000s
 [Array#unsafe_sample]             0.371000s
 [BigArray#safe]                   1.222000s
 [BigArray#unsafe]                 0.992000s
 ```
