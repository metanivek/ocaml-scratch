module H = Hashtbl.Make (struct
  include Optint.Int63

  let hash = Hashtbl.hash
end)

let rnd_key n =
  let i = Random.int n in
  let k = Optint.Int63.of_int i in
  (k, i)

let init s n =
  let h = H.create s in
  for i = 0 to n - 1 do
    H.replace h (Optint.Int63.of_int i) i
  done;
  h

let replace h n =
  let k, v = rnd_key n in
  (* Hashtbl resizes (rehash + double size) when
     the number of entries added is more than double
     the number of buckets *)
  H.replace h k v

let find h n =
  let k, _ = rnd_key n in
  H.find_opt h k |> ignore

let mem h n =
  let k, _ = rnd_key n in
  H.mem h k |> ignore

(** [run h k n f] repeats [f h n] [k] times *)
let run h k n f =
  for _i = 1 to k do
    f h n
  done

let () =
  Random.self_init ();
  (* [n] is the number of ints in our hash table *)
  let n = Sys.argv.(1) |> int_of_string in
  (* [s] is the desired initial capacity of our table

     Note: Hashtbl will round to the next largest power
     of 2 *)
  let s = Sys.argv.(2) |> int_of_string in
  (* [k] is the number of times to perform the action *)
  let k = Sys.argv.(3) |> int_of_string in
  (* [a] is the action to perform
     - init
     - replace
     - find
     - mem
  *)
  let a = Sys.argv.(4) in
  match a with
  | "init" -> run (H.create 16) k n (fun _h n -> init s n |> ignore)
  | "replace" -> run (init s n) k n replace
  | "find" -> run (init s n) k n find
  | "mem" -> run (init s n) k n mem
  | _ -> Fmt.failwith "invalid action"
