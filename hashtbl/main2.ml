let rnd_char _ =
  let code = Random.int 255 in
  Char.unsafe_chr code

let insert h i =
  let k = 5 + Random.int 20 in
  let str = Bytes.init k rnd_char |> Bytes.unsafe_to_string in
  Hashtbl.replace h str i;
  str

let populate h s =
  let keys = Array.make s "" in
  for i = 0 to s - 1 do
    let key = insert h i in
    Array.set keys i key
  done;
  keys

let measure_find size tbl keys n =
  let len = Array.length keys in
  let c0 = Mtime_clock.counter () in
  for i = 0 to n - 1 do
    let key = Array.get keys (i mod len) in
    Hashtbl.find_opt tbl key |> ignore
  done;
  let span1 = Mtime_clock.count c0 |> Mtime.Span.to_ms in
  Fmt.epr "%d\t%.2f\t%.6f@." size span1 (span1 /. Int.to_float n)

let measure_add size tbl n =
  let c0 = Mtime_clock.counter () in
  for i = 0 to n - 1 do
    insert tbl i |> ignore
  done;
  let span1 = Mtime_clock.count c0 |> Mtime.Span.to_ms in
  Fmt.epr "%d\t%.2f\t%.6f@." size span1 (span1 /. Int.to_float n)

let () =
  Printexc.record_backtrace true;
  Random.self_init ();
  Fmt.epr "@.";
  Fmt.epr "size\ttotal\tper op@.";
  let sizes = [ 100_000; 500_000; 8_000_000 ] in
  let n = 100_000 in
  let data =
    List.map
      (fun s ->
        let h = Hashtbl.create 997 in
        let keys = populate h s in
        (s, h, keys))
      sizes
  in
  Fmt.epr "FIND@.";
  data |> List.iter (fun (size, tbl, keys) -> measure_find size tbl keys n);
  Fmt.epr "ADD@.";
  data |> List.iter (fun (size, tbl, _keys) -> measure_add size tbl n)
