open Lwt.Syntax
module Store = Irmin_tezos.Store

let main root commit_hash raw_path =
  Format.printf "\nLoading store from %s\n" root;
  let config =
    Irmin_pack.config ~readonly:true ~fresh:false
      ~indexing_strategy:Irmin_pack.Indexing_strategy.minimal root
  in
  let* repo = Store.Repo.v config in

  let* heads = Store.Repo.heads repo in
  Format.printf "\nHead Commit Hashes\n";
  (heads |> List.iter @@ fun h -> Format.printf "%a\n" Store.Commit.pp_hash h);

  let* branches = Store.Branch.list repo in
  Format.printf "\nBranches\n";
  branches |> List.iter @@ Format.printf "%s\n";

  let hash = Irmin.Type.(of_string Store.Hash.t commit_hash) |> Result.get_ok in
  let* commit = Store.Commit.of_hash repo hash in
  let* head_store = Store.of_commit (Option.get commit) in
  let* tree = Store.tree head_store in
  let path =
    match String.split_on_char '/' raw_path with [ "" ] -> [] | x -> x
  in
  let* keys = Store.Tree.list ~offset:0 ~length:20 tree path in
  Format.printf "\nKeys\n";
  (keys |> List.iter @@ fun (k, _) -> Format.printf "%s\n" k);
  Lwt.return_unit

let store = ref "node/data/context"
let commit_hash = ref "CoV8SQumiVU9saiu3FVNeDNewJaJH8yWdsGF3WLdsRr2P9S7MzCj"
let path = ref ""

let speclist =
  [
    ( "-store",
      Arg.Set_string store,
      "Store path. Defaults to node/data/context." );
    ( "-hash",
      Arg.Set_string commit_hash,
      "Commit hash. Defaults to \
       CoWLnZaqauuQpm9ewRuUDEU4wWWnD9S9xzW1BQXJnDNSmcKxNf9r, the genesis \
       context hash." );
    ("-path", Arg.Set_string path, "Path to list keys. Defaults to empty.");
  ]

let () =
  Arg.parse speclist
    (fun _ -> ())
    "main.exe -store /path/to/store -hash CommitHash -path data/contracts/index";
  Lwt_main.run @@ main !store !commit_hash !path
