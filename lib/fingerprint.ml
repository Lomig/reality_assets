open Containers

(*===========================================================================*
 * Module
 *===========================================================================*)

let fingerprinted_file_pattern =
  let open Re in
  seq
    [ rep1 (alt [ alnum; char '_'; char '-'; char '.'; char ' '; char '/' ])
    ; str "-"
    ; repn (alt [ rg '0' '9'; rg 'a' 'f'; rg 'A' 'F' ]) 32 (Some 32)
    ; str "."
    ; rep1 alnum
    ; stop
    ]
  |> compile
;;

let is_fingerprinted = Re.execp fingerprinted_file_pattern

let md5_of_file filename =
  IO.with_in filename (fun ic ->
    let digest = Digest.channel ic (-1) |> Digest.to_hex in
    digest)
;;

let add_to filename =
  match is_fingerprinted filename with
  | true -> filename
  | false ->
    let extension = Filename.extension filename in
    let basename = Filename.remove_extension filename in
    let fingerprint = md5_of_file filename in
    basename ^ "-" ^ fingerprint ^ extension
;;

let remove_from filename =
  match is_fingerprinted filename with
  | false -> filename
  | true ->
    let extension = Filename.extension filename in
    let basename = Filename.remove_extension filename in
    let basename_length = String.length basename in
    let fingerprint_length = 32 in
    let new_basename = String.sub basename 0 (basename_length - fingerprint_length - 1) in
    new_basename ^ extension
;;

let rename_file filename =
  match is_fingerprinted filename with
  | true -> ()
  | false -> Sys.rename filename (add_to filename)
;;

(*===========================================================================*
 * Inline Tests
 *===========================================================================*)

(*-- is_fingerprinted -------------------------------------------------------*)
let%test_module "is_fingerprinted" =
  (module struct
    let%expect_test "it returns true for fingerprinted filenames" =
      let _ =
        Format.printf "%a" Bool.pp
        @@ is_fingerprinted "file-1234567890abcdef1234567890abcdef.txt"
      in
      [%expect {| true |}]
    ;;

    let%expect_test "it returns false for fingerprinted names with the wrong separator" =
      let _ =
        Format.printf "%a" Bool.pp
        @@ is_fingerprinted "file_1234567890abcdef1234567890abcdef.txt"
      in
      [%expect {| false |}]
    ;;

    let%expect_test "it returns false for non-fingerprinted filenames" =
      let _ = Format.printf "%a" Bool.pp @@ is_fingerprinted "file.txt" in
      [%expect {| false |}]
    ;;
  end)
;;

(*-- add_to -----------------------------------------------------------------*)
let%test_module "add_to" =
  (module struct
    let%expect_test "it adds an MD5 fingerprint to the filename" =
      IO.with_out "file.txt" (fun oc -> IO.write_line oc "Hello, World!");
      let _ = Format.printf "%s" @@ add_to "file.txt" in
      Sys.remove "file.txt";
      [%expect {| file-bea8252ff4e80f41719ea13cdf007273.txt |}]
    ;;

    let%expect_test
        "it does not add an MD5 fingerprint to an already fingerprinted filename"
      =
      let fingerprinted_name = "file-bea8252ff4e80f41719ea13cdf007273.txt" in
      IO.with_out fingerprinted_name (fun oc -> IO.write_line oc "Hello, World!");
      let _ = Format.printf "%s" @@ add_to fingerprinted_name in
      Sys.remove fingerprinted_name;
      [%expect {| file-bea8252ff4e80f41719ea13cdf007273.txt |}]
    ;;
  end)
;;

(*-- remove_from ------------------------------------------------------------*)
let%test_module "remove_from" =
  (module struct
    let%expect_test "it removes an MD5 fingerprint from the filename" =
      let _ =
        Format.printf "%s" @@ remove_from "file-1234567890abcdef1234567890abcdef.txt"
      in
      [%expect {| file.txt |}]
    ;;

    let%expect_test
        "it does not remove an MD5 fingerprint from a non-fingerprinted filename"
      =
      let _ = Format.printf "%s" @@ remove_from "file.txt" in
      [%expect {| file.txt |}]
    ;;
  end)
;;

(*-- rename_file ------------------------------------------------------------*)
let%test_module "rename_file" =
  (module struct
    let%expect_test "it renames the file by adding an MD5 fingerprint" =
      IO.with_out "file.txt" (fun oc -> IO.write_line oc "Hello, World!");
      let _ = rename_file "file.txt" in
      let _ =
        Sys.readdir "."
        |> Array.to_list
        |> List.filter (fun f -> String.starts_with ~prefix:"file" f)
        |> List.hd
        |> Format.printf "%s"
      in
      Sys.remove "file-bea8252ff4e80f41719ea13cdf007273.txt";
      [%expect {| file-bea8252ff4e80f41719ea13cdf007273.txt |}]
    ;;

    let%expect_test "it does not rename an already fingerprinted file" =
      let fingerprinted_name = "file-bea8252ff4e80f41719ea13cdf007273.txt" in
      IO.with_out fingerprinted_name (fun oc -> IO.write_line oc "Hello, World!");
      let _ = rename_file fingerprinted_name in
      let _ =
        Sys.readdir "."
        |> Array.to_list
        |> List.filter (fun f -> String.starts_with ~prefix:"file" f)
        |> List.hd
        |> Format.printf "%s"
      in
      Sys.remove fingerprinted_name;
      [%expect {| file-bea8252ff4e80f41719ea13cdf007273.txt |}]
    ;;
  end)
;;
