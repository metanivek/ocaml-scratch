module Store_conf : Irmin_pack.Conf.S = struct
  let entries = 2
  (* change entries (must be power of 2) to see different structures *)

  let stable_hash = 0
  let contents_length_header = Some `Varint
  let inode_child_order = `Hash_bits
  let forbid_empty_dir_persistence = true
end

module Hash = Irmin.Hash.BLAKE2B

module Path = struct
  type step = string [@@deriving irmin]
end

module Metadata = Irmin.Metadata.None

module Key = struct
  include Irmin.Key.Of_hash (Hash)

  let unfindable_of_hash hash = hash
end

module Node = Irmin.Node.Generic_key.Make (Hash) (Path) (Metadata) (Key) (Key)
module Inode = Irmin_pack.Inode.Make_internal (Store_conf) (Hash) (Key) (Node)

let main () =
  Fmt.pr "\nexploring inodes\n";
  let add c n =
    let module String_hasher = Irmin.Hash.Typed (Hash) (Irmin.Contents.String)
    in
    let h = String_hasher.hash c in
    let k = Key.of_hash h in
    Inode.Val.add n c (`Contents (k, ()))
  in
  let n =
    Inode.Val.empty ()
    |> add "test1"
    |> add "test2"
    |> add "test3"
    |> add "test4"
    |> add "test5"
  in
  Fmt.pr "\ninode concrete representation:\n%a\n"
    Irmin.Type.(pp_json ~minify:false Inode.Val.Concrete.t)
    (Inode.Val.to_concrete n);
  let h = Inode.Val.hash_exn n in
  Fmt.pr "inode hash = %a\n" Inode.pp_hash h

let () = main ()
