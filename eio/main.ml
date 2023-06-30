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

let measure_read_lwt size_range chunk_num max_offset f =
  let open Lwt.Syntax in
  let lower, upper = size_range in
  let range = upper - lower in
  let c0 = Mtime_clock.counter () in
  let* () =
    List.init chunk_num Fun.id
    |> Lwt_list.iter_s (fun _ ->
           let offset = Random.full_int max_offset in
           let len = lower + Random.full_int range in
           let* read_len = f offset len in
           assert (len = read_len);
           Lwt.return_unit)
  in
  let duration = Mtime_clock.count c0 |> Mtime.span_to_ms in
  Fmt.epr "%.4fms\t%.4fms@." duration (duration /. Float.of_int chunk_num);
  Lwt.return_unit

let () =
  let path = Sys.argv.(1) in
  let file = Unix.openfile path [ Unix.O_RDONLY ] 0 in
  let len = (Unix.fstat file).st_size in
  let range = (50, 100) in
  let chunk_num = 50 in
  let measure = measure_read range chunk_num (len - snd range) in
  let measure_lwt = measure_read_lwt range chunk_num (len - snd range) in

  Fmt.epr "Unix.read@.";
  let () =
    measure @@ fun pos len ->
    let buf = Bytes.create len in
    let _ = Unix.lseek file pos Unix.SEEK_SET in
    Unix.read file buf 0 len
  in

  Fmt.epr "Index.pread@.";
  let () =
    measure @@ fun pos length ->
    let buffer = Bytes.create length in
    Index_unix.Syscalls.pread ~fd:file ~fd_offset:(Optint.Int63.of_int pos)
      ~buffer ~buffer_offset:0 ~length
  in

  Unix.close file;

  Fmt.epr "Eio.File.pread@.";
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let flow = Eio.Path.open_in ~sw Eio.Path.(env#fs / path) in
  let () =
    measure @@ fun pos len ->
    let buf = Cstruct.create len in
    Eio.File.pread flow ~file_offset:(Optint.Int63.of_int pos) [ buf ]
  in

  Fmt.epr "Eio.File.pread (with polling)@.";
  Eio_linux.run ~polling_timeout:5000 @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let flow = Eio.Path.open_in ~sw Eio.Path.(env#fs / path) in
  let () =
    measure @@ fun pos len ->
    let buf = Cstruct.create len in
    Eio.File.pread flow ~file_offset:(Optint.Int63.of_int pos) [ buf ]
  in

  Fmt.epr "Lwt_unix.pread@.";
  Lwt_main.run
    (let open Lwt.Syntax in
     let* file = Lwt_unix.openfile path [ Unix.O_RDONLY ] 0 in
     let* () =
       measure_lwt @@ fun pos len ->
       let buffer = Bytes.create len in
       Lwt_unix.pread file buffer ~file_offset:pos 0 len
     in
     Lwt.return_unit)
