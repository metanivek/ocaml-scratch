module Mtime = struct
  include Mtime

  (* let span_to_us span = Mtime.Span.to_float_ns span *. 1e-3 *)
  let span_to_ms span = Mtime.Span.to_float_ns span *. 1e-6
  (* let span_to_s span = Mtime.Span.to_float_ns span *. 1e-9 *)
end

let measure_read size_range chunk_num max_offset f =
  let lower, upper = size_range in
  let range = upper - lower in
  let c0 = Mtime_clock.counter () in
  for _ = 1 to chunk_num do
    let offset = Random.full_int max_offset in
    let len = lower + Random.full_int range in
    let read_len = f offset len in
    assert (len = read_len)
  done;
  let duration = Mtime_clock.count c0 |> Mtime.span_to_ms in
  Fmt.epr "%.4fms\t%.4fms@." duration (duration /. Float.of_int chunk_num);
  ()

let rec with_retry uring (f : 'a Uring.t -> 'a Uring.completion_option) =
  match f uring with
  | None -> with_retry uring f       (* Interrupted *)
  | Some { result; data } -> result, data

let () =
  let path = Sys.argv.(1) in
  let file = Unix.openfile path [ Unix.O_RDONLY ] 0 in
  let len = (Unix.fstat file).st_size in
  let range = (50, 100) in
  let chunk_num = 50 in
  let measure = measure_read range chunk_num (len - snd range) in

  Fmt.epr "Uring (wait)@.";
  let uring = Uring.create ~queue_depth:64 () in
  let () = measure @@ fun pos len ->
    let buf = Cstruct.create len in
    let _job = Uring.read uring ~file_offset:(Optint.Int63.of_int pos) file buf `Read in
    let _ = Uring.submit uring in
    let result, _ = with_retry uring Uring.wait in
    result
  in

  Fmt.epr "Uring (poll)@.";
  let uring = Uring.create ~queue_depth:64 ~polling_timeout:1000 () in
  let () = measure @@ fun pos len ->
    let buf = Cstruct.create len in
    let _job = Uring.read uring ~file_offset:(Optint.Int63.of_int pos) file buf `Read in
    let _ = Uring.submit uring in
    let result, _ = with_retry uring Uring.get_cqe_nonblocking in
    result
  in

  ()
