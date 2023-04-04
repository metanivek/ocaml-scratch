let n = 1_000
let sample_size = 100

open Bigarray

let ( +! ) = Int64.add
let ( =! ) = Int64.equal
let fold_sum_array = Array.fold_left Int64.add Int64.zero

let safe_sum_array arr =
  let len = Array.length arr in
  let sum = ref Int64.zero in
  for i = 0 to len - 1 do
    sum := !sum +! Array.get arr i
  done;
  !sum

let unsafe_sum_array arr =
  let len = Array.length arr in
  let sum = ref Int64.zero in
  for i = 0 to len - 1 do
    sum := !sum +! Array.unsafe_get arr i
  done;
  !sum

let safe_sum_bigarray arr =
  let len = Array1.dim arr in
  let sum = ref Int64.zero in
  for i = 0 to len - 1 do
    sum := !sum +! arr.{i}
  done;
  !sum

let unsafe_sum_bigarray arr =
  let len = Array1.dim arr in
  let sum = ref Int64.zero in
  for i = 0 to len - 1 do
    sum := !sum +! Array1.unsafe_get arr i
  done;
  !sum

let pad s =
  let n = 35 in
  let l = String.length s in
  if l < n then s ^ String.make (n - l) ' ' else s

let print_label label = print_string @@ pad label

let last_result : Int64.t option ref = ref None

let time label f x =
  print_label label;
  let c0 = Mtime_clock.counter () in
  let res = f x in
  let duration = Mtime_clock.count c0 |> Mtime.Span.to_us in
  Printf.printf "%fs\n%!" duration;
  (match !last_result with None -> () | Some f -> assert (res =! f));
  last_result := Some res

let time_sample label f x samples =
  print_label label;
  let c0 = Mtime_clock.counter () in
  Array.iter (fun i -> ignore (f x i)) samples;
  let duration = Mtime_clock.count c0 |> Mtime.Span.to_us in
  Printf.printf "%fs\n%!" duration

let () =
  let arr = Array.init n (fun _ -> Random.int64 Int64.max_int) in
  let samples = Array.init sample_size (fun _ -> Random.full_int n) in
  let big_arr = Array1.of_array Bigarray.int64 Bigarray.c_layout arr in

  Printf.printf "\nSum %d integers\n" n;
  time " [Array#fold] " fold_sum_array arr;
  time " [Array#safe] " safe_sum_array arr;
  time " [Array#unsafe] " unsafe_sum_array arr;
  time " [BigArray#safe] " safe_sum_bigarray big_arr;
  time " [BigArray#unsafe] " unsafe_sum_bigarray big_arr;

  Printf.printf "\nSample %d out of %d\n" sample_size n;
  time_sample " [Array#safe_sample] " Array.get arr samples;
  time_sample " [Array#unsafe_sample] " Array.unsafe_get arr samples;
  time_sample " [BigArray#safe] " Array1.get big_arr samples;
  time_sample " [BigArray#unsafe] " Array1.unsafe_get big_arr samples
