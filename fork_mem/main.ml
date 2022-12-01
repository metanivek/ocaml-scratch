let print_stats () =
  let rusage = Rusage.get Self in
  let maxrss = Int64.to_int rusage.maxrss in
  let gc_stat = Gc.stat () in
  Printf.printf "Rusage.maxrss = %#d kB; Gc.stat.heap_words = %#d\n" maxrss
    gc_stat.heap_words;
  Out_channel.flush_all ();
  let _ =
    Cmd.run_default ("ps -o pid,rss -p " ^ (Unix.getpid () |> Int.to_string))
  in
  Printf.printf "\n"

let junk = ref None

let () =
  Printf.printf "\n\n --- Looking at memory usage when forking. ---\n\n";
  Printf.printf "Starting stats\n";
  print_stats ();
  Printf.printf "Create large junk array\n";
  junk := Some (Array.init 100_000_000 Fun.id);
  print_stats ();
  Printf.printf "Forking...\n";
  Out_channel.flush_all ();

  match Unix.fork () with
  | 0 ->
      Printf.printf " >> child; PID = %d\n" (Unix.getpid ());
      print_stats ();
      Printf.printf "Set array ref to None\n";
      junk := None;
      print_stats ();
      Printf.printf "Perform Gc.compact\n";
      Gc.compact ();
      print_stats ()
  | pid ->
      Printf.printf " >> parent\n";
      (* wait for child to finish before printing our stats,
         just so things print in order :) *)
      let _ = Unix.waitpid [] pid in
      print_stats ();
      ()

(*
Output looks something like...

# dune exec ./fork_mem.exe
Done: 95% (19/20, 1 left) (jobs: 1)

 --- Looking at memory usage when forking. ---

Starting stats
Rusage.maxrss = 19_404 kB; Gc.stat.heap_words = 126_976
    PID   RSS
  94202  3036

Create large junk array
Rusage.maxrss = 792_476 kB; Gc.stat.heap_words = 220_127_232
    PID   RSS
  94202 792700

Forking...
 >> child; PID = 94219
Rusage.maxrss = 790_208 kB; Gc.stat.heap_words = 220_127_232
    PID   RSS
  94219 791380

Set array ref to None
Rusage.maxrss = 791_380 kB; Gc.stat.heap_words = 220_127_232
    PID   RSS
  94219 791404

Perform Gc.compact
Rusage.maxrss = 791_976 kB; Gc.stat.heap_words = 33_000_448
    PID   RSS
  94219 10644

 >> parent
Rusage.maxrss = 792_700 kB; Gc.stat.heap_words = 220_127_232
    PID   RSS
  94202 792720
*)
