open! Containers
module StringMap = Map.Make (String)

(*===========================================================================*
 * Assets Module
 *===========================================================================*)

let create_files () =
  Sys.mkdir "test_assets" 0o755;
  Sys.mkdir "test_assets/controllers" 0o755;
  Sys.mkdir "test_assets/a_folder" 0o755;
  IO.with_out "test_assets/file1.js" (fun oc -> IO.write_line oc "file1");
  IO.with_out "test_assets/file1.css" (fun oc -> IO.write_line oc "file1 another ext");
  IO.with_out "test_assets/file2.css" (fun oc -> IO.write_line oc "file2");
  IO.with_out "test_assets/controllers/file1.js" (fun oc -> IO.write_line oc "file1 dir");
  IO.with_out "test_assets/controllers/file3.js" (fun oc -> IO.write_line oc "file3");
  IO.with_out "test_assets/controllers/_file4.js" (fun oc -> IO.write_line oc "file4");
  IO.with_out "test_assets/controllers/_index.js" (fun oc -> IO.write_line oc "file5");
  IO.with_out "test_assets/a_folder/_file1.js" (fun oc -> IO.write_line oc "file1 _")
;;

let delete_files () =
  Sys.remove "test_assets/file1-5149d403009a139c7e085405ef762e1a.js";
  Sys.remove "test_assets/file1-14bb9537e0a9810bdb0dd1c5470075b4.css";
  Sys.remove "test_assets/file2-3d709e89c8ce201e3c928eb917989aef.css";
  Sys.remove "test_assets/controllers/file1-d6de7dda18e17ed6844177361885b573.js";
  Sys.remove "test_assets/controllers/file3-60b91f1875424d3b4322b0fdd0529d5d.js";
  Sys.remove "test_assets/controllers/_file4-857c6673d7149465c8ced446769b523c.js";
  Sys.remove "test_assets/controllers/_index-f1ad8dddbf5c5f61ce4cb6fd502f4625.js";
  Sys.remove "test_assets/a_folder/_file1-a25b4de866d9174a3ab79704b35efd13.js";
  Sys.rmdir "test_assets/a_folder";
  Sys.rmdir "test_assets/controllers";
  Sys.rmdir "test_assets"
;;

(*-- fingerprint ------------------------------------------------------------*)
let%expect_test "it fingerprints files and return a map of them" =
  create_files ();
  let asset_map = RealityAssets.fingerprint ~path:"test_assets/" () in
  let _ = Format.printf "%a" RealityAssets.assetmap_pp asset_map in
  delete_files ();
  [%expect
    {|
    "test_assets/a_folder/_file1.js"
    -> "test_assets/a_folder/_file1-a25b4de866d9174a3ab79704b35efd13.js",
    "test_assets/controllers/_file4.js"
    -> "test_assets/controllers/_file4-857c6673d7149465c8ced446769b523c.js",
    "test_assets/controllers/_index.js"
    -> "test_assets/controllers/_index-f1ad8dddbf5c5f61ce4cb6fd502f4625.js",
    "test_assets/controllers/file1.js"
    -> "test_assets/controllers/file1-d6de7dda18e17ed6844177361885b573.js",
    "test_assets/controllers/file3.js"
    -> "test_assets/controllers/file3-60b91f1875424d3b4322b0fdd0529d5d.js",
    "test_assets/file1.css"
    -> "test_assets/file1-14bb9537e0a9810bdb0dd1c5470075b4.css",
    "test_assets/file1.js"
    -> "test_assets/file1-5149d403009a139c7e085405ef762e1a.js",
    "test_assets/file2.css"
    -> "test_assets/file2-3d709e89c8ce201e3c928eb917989aef.css"
    |}]
;;

let%expect_test "it rename the files in the source directory" =
  create_files ();
  let _ = RealityAssets.fingerprint ~path:"test_assets/" () in
  let _ =
    Sys.readdir "test_assets"
    |> Array.to_list
    |> List.filter (fun f -> not @@ Sys.is_directory @@ "test_assets/" ^ f)
    |> Format.printf "%a" @@ List.pp String.pp
  in
  print_endline ",";
  let _ =
    Sys.readdir "test_assets/controllers"
    |> Array.to_list
    |> List.map (fun f -> "controllers/" ^ f)
    |> Format.printf "%a" @@ List.pp String.pp
  in
  print_endline ",";
  let _ =
    Sys.readdir "test_assets/a_folder"
    |> Array.to_list
    |> List.map (fun f -> "a_folder/" ^ f)
    |> Format.printf "%a" @@ List.pp String.pp
  in
  delete_files ();
  [%expect
    {|
    "file1-5149d403009a139c7e085405ef762e1a.js",
    "file1-14bb9537e0a9810bdb0dd1c5470075b4.css",
    "file2-3d709e89c8ce201e3c928eb917989aef.css",
    "controllers/_file4-857c6673d7149465c8ced446769b523c.js",
    "controllers/_index-f1ad8dddbf5c5f61ce4cb6fd502f4625.js",
    "controllers/file3-60b91f1875424d3b4322b0fdd0529d5d.js",
    "controllers/file1-d6de7dda18e17ed6844177361885b573.js",
    "a_folder/_file1-a25b4de866d9174a3ab79704b35efd13.js"
    |}]
;;

let%expect_test "if a fingerprinted file has been updated, it replaces it in the map" =
  create_files ();
  IO.with_out "test_assets/file1-5149d403009a139c7e085405ef762e1a.js" (fun oc ->
    IO.write_line oc "file1");
  IO.with_out
    "test_assets/controllers/file1-0009d403009a139c7e085405ef762000.js"
    (fun oc -> IO.write_line oc "file1");
  IO.with_out "test_assets/a_folder/_file1-00000003009a139c7e085405ef762000.js" (fun oc ->
    IO.write_line oc "file1");
  let asset_map = RealityAssets.fingerprint ~path:"test_assets/" () in
  let _ = Format.printf "%a" RealityAssets.assetmap_pp asset_map in
  delete_files ();
  [%expect
    {|
    "test_assets/a_folder/_file1.js"
    -> "test_assets/a_folder/_file1-a25b4de866d9174a3ab79704b35efd13.js",
    "test_assets/controllers/_file4.js"
    -> "test_assets/controllers/_file4-857c6673d7149465c8ced446769b523c.js",
    "test_assets/controllers/_index.js"
    -> "test_assets/controllers/_index-f1ad8dddbf5c5f61ce4cb6fd502f4625.js",
    "test_assets/controllers/file1.js"
    -> "test_assets/controllers/file1-d6de7dda18e17ed6844177361885b573.js",
    "test_assets/controllers/file3.js"
    -> "test_assets/controllers/file3-60b91f1875424d3b4322b0fdd0529d5d.js",
    "test_assets/file1.css"
    -> "test_assets/file1-14bb9537e0a9810bdb0dd1c5470075b4.css",
    "test_assets/file1.js"
    -> "test_assets/file1-5149d403009a139c7e085405ef762e1a.js",
    "test_assets/file2.css"
    -> "test_assets/file2-3d709e89c8ce201e3c928eb917989aef.css"
    |}]
;;

let%expect_test "if a fingerprinted file has been updated, it replaces it in the folder" =
  create_files ();
  IO.with_out "test_assets/file1-0009d403009a139c7e085405ef762e1a.js" (fun oc ->
    IO.write_line oc "file1");
  let _ = RealityAssets.fingerprint ~path:"test_assets/" () in
  let _ =
    Sys.readdir "test_assets"
    |> Array.to_list
    |> List.filter (fun f -> not @@ Sys.is_directory @@ "test_assets/" ^ f)
    |> Format.printf "%a" @@ List.pp String.pp
  in
  print_endline ",";
  let _ =
    Sys.readdir "test_assets/controllers"
    |> Array.to_list
    |> List.map (fun f -> "controllers/" ^ f)
    |> Format.printf "%a" @@ List.pp String.pp
  in
  print_endline ",";
  let _ =
    Sys.readdir "test_assets/a_folder"
    |> Array.to_list
    |> List.map (fun f -> "a_folder/" ^ f)
    |> Format.printf "%a" @@ List.pp String.pp
  in
  delete_files ();
  [%expect
    {|
    "file1-5149d403009a139c7e085405ef762e1a.js",
    "file1-14bb9537e0a9810bdb0dd1c5470075b4.css",
    "file2-3d709e89c8ce201e3c928eb917989aef.css",
    "controllers/_file4-857c6673d7149465c8ced446769b523c.js",
    "controllers/_index-f1ad8dddbf5c5f61ce4cb6fd502f4625.js",
    "controllers/file3-60b91f1875424d3b4322b0fdd0529d5d.js",
    "controllers/file1-d6de7dda18e17ed6844177361885b573.js",
    "a_folder/_file1-a25b4de866d9174a3ab79704b35efd13.js"
    |}]
;;

let%expect_test "if a non-updated fingerprinted file exists, it keeps it in the map" =
  create_files ();
  IO.with_out "test_assets/new_file-0009d403009a139c7e085405ef762e1a.js" (fun oc ->
    IO.write_line oc "new_file");
  let asset_map = RealityAssets.fingerprint ~path:"test_assets/" () in
  let _ = Format.printf "%a" RealityAssets.assetmap_pp asset_map in
  Sys.remove "test_assets/new_file-0009d403009a139c7e085405ef762e1a.js";
  delete_files ();
  [%expect
    {|
    "test_assets/a_folder/_file1.js"
    -> "test_assets/a_folder/_file1-a25b4de866d9174a3ab79704b35efd13.js",
    "test_assets/controllers/_file4.js"
    -> "test_assets/controllers/_file4-857c6673d7149465c8ced446769b523c.js",
    "test_assets/controllers/_index.js"
    -> "test_assets/controllers/_index-f1ad8dddbf5c5f61ce4cb6fd502f4625.js",
    "test_assets/controllers/file1.js"
    -> "test_assets/controllers/file1-d6de7dda18e17ed6844177361885b573.js",
    "test_assets/controllers/file3.js"
    -> "test_assets/controllers/file3-60b91f1875424d3b4322b0fdd0529d5d.js",
    "test_assets/file1.css"
    -> "test_assets/file1-14bb9537e0a9810bdb0dd1c5470075b4.css",
    "test_assets/file1.js"
    -> "test_assets/file1-5149d403009a139c7e085405ef762e1a.js",
    "test_assets/file2.css"
    -> "test_assets/file2-3d709e89c8ce201e3c928eb917989aef.css",
    "test_assets/new_file.js"
    -> "test_assets/new_file-0009d403009a139c7e085405ef762e1a.js"
    |}]
;;

let%expect_test "if a non-updated fingerprinted file exists, it keeps it in the folder" =
  create_files ();
  IO.with_out "test_assets/new_file-0009d403009a139c7e085405ef762e1a.js" (fun oc ->
    IO.write_line oc "new_file");
  let _ = RealityAssets.fingerprint ~path:"test_assets/" () in
  let _ =
    Sys.readdir "test_assets"
    |> Array.to_list
    |> List.filter (fun f -> not @@ Sys.is_directory @@ "test_assets/" ^ f)
    |> Format.printf "%a" @@ List.pp String.pp
  in
  print_endline ",";
  let _ =
    Sys.readdir "test_assets/controllers"
    |> Array.to_list
    |> List.map (fun f -> "controllers/" ^ f)
    |> Format.printf "%a" @@ List.pp String.pp
  in
  print_endline ",";
  let _ =
    Sys.readdir "test_assets/a_folder"
    |> Array.to_list
    |> List.map (fun f -> "a_folder/" ^ f)
    |> Format.printf "%a" @@ List.pp String.pp
  in
  Sys.remove "test_assets/new_file-0009d403009a139c7e085405ef762e1a.js";
  delete_files ();
  [%expect
    {|
    "file1-5149d403009a139c7e085405ef762e1a.js",
    "file1-14bb9537e0a9810bdb0dd1c5470075b4.css",
    "file2-3d709e89c8ce201e3c928eb917989aef.css",
    "new_file-0009d403009a139c7e085405ef762e1a.js",
    "controllers/_file4-857c6673d7149465c8ced446769b523c.js",
    "controllers/_index-f1ad8dddbf5c5f61ce4cb6fd502f4625.js",
    "controllers/file3-60b91f1875424d3b4322b0fdd0529d5d.js",
    "controllers/file1-d6de7dda18e17ed6844177361885b573.js",
    "a_folder/_file1-a25b4de866d9174a3ab79704b35efd13.js"
    |}]
;;

let%expect_test "it does not fingerprint files from a `pinned` directory" =
  create_files ();
  Sys.mkdir "test_assets/pinned" 0o755;
  IO.with_out "test_assets/pinned/pinned_file.js" (fun oc ->
    IO.write_line oc "pinned_file");
  let asset_map = RealityAssets.fingerprint ~path:"test_assets/" () in
  let _ = Format.printf "%a" RealityAssets.assetmap_pp asset_map in
  Sys.remove "test_assets/pinned/pinned_file.js";
  Sys.rmdir "test_assets/pinned";
  delete_files ();
  [%expect
    {|
    "test_assets/a_folder/_file1.js"
    -> "test_assets/a_folder/_file1-a25b4de866d9174a3ab79704b35efd13.js",
    "test_assets/controllers/_file4.js"
    -> "test_assets/controllers/_file4-857c6673d7149465c8ced446769b523c.js",
    "test_assets/controllers/_index.js"
    -> "test_assets/controllers/_index-f1ad8dddbf5c5f61ce4cb6fd502f4625.js",
    "test_assets/controllers/file1.js"
    -> "test_assets/controllers/file1-d6de7dda18e17ed6844177361885b573.js",
    "test_assets/controllers/file3.js"
    -> "test_assets/controllers/file3-60b91f1875424d3b4322b0fdd0529d5d.js",
    "test_assets/file1.css"
    -> "test_assets/file1-14bb9537e0a9810bdb0dd1c5470075b4.css",
    "test_assets/file1.js"
    -> "test_assets/file1-5149d403009a139c7e085405ef762e1a.js",
    "test_assets/file2.css"
    -> "test_assets/file2-3d709e89c8ce201e3c928eb917989aef.css"
    |}]
;;

let%expect_test "it does not rename files in a `pinned` folder" =
  create_files ();
  Sys.mkdir "test_assets/pinned" 0o755;
  IO.with_out "test_assets/pinned/pinned_file.js" (fun oc ->
    IO.write_line oc "pinned_file");
  let _ = RealityAssets.fingerprint ~path:"test_assets/" () in
  let _ =
    Sys.readdir "test_assets"
    |> Array.to_list
    |> List.filter (fun f -> not @@ Sys.is_directory @@ "test_assets/" ^ f)
    |> Format.printf "%a" @@ List.pp String.pp
  in
  print_endline ",";
  let _ =
    Sys.readdir "test_assets/controllers"
    |> Array.to_list
    |> List.map (fun f -> "controllers/" ^ f)
    |> Format.printf "%a" @@ List.pp String.pp
  in
  print_endline ",";
  let _ =
    Sys.readdir "test_assets/a_folder"
    |> Array.to_list
    |> List.map (fun f -> "a_folder/" ^ f)
    |> Format.printf "%a" @@ List.pp String.pp
  in
  print_endline ",";
  let _ =
    Sys.readdir "test_assets/pinned"
    |> Array.to_list
    |> List.map (fun f -> "pinned/" ^ f)
    |> Format.printf "%a" @@ List.pp String.pp
  in
  Sys.remove "test_assets/pinned/pinned_file.js";
  Sys.rmdir "test_assets/pinned";
  delete_files ();
  [%expect
    {|
    "file1-5149d403009a139c7e085405ef762e1a.js",
    "file1-14bb9537e0a9810bdb0dd1c5470075b4.css",
    "file2-3d709e89c8ce201e3c928eb917989aef.css",
    "controllers/_file4-857c6673d7149465c8ced446769b523c.js",
    "controllers/_index-f1ad8dddbf5c5f61ce4cb6fd502f4625.js",
    "controllers/file3-60b91f1875424d3b4322b0fdd0529d5d.js",
    "controllers/file1-d6de7dda18e17ed6844177361885b573.js",
    "a_folder/_file1-a25b4de866d9174a3ab79704b35efd13.js",
    "pinned/pinned_file.js"
    |}]
;;

(*-- generate_importmap -----------------------------------------------------*)
let%expect_test "it generates a json, renaming indexes and removing underscores" =
  create_files ();
  let importmaps =
    RealityAssets.generate_importmap
      ~path:"test_assets/"
      [ "another_import", "path_of_another_import" ]
  in
  delete_files ();
  let _ = Format.printf "%s" importmaps.list in
  [%expect
    {|
    {
      "imports": {
        "another_import": "path_of_another_import",
        "file1": "/test_assets/file1-5149d403009a139c7e085405ef762e1a.js",
        "controllers/file3": "/test_assets/controllers/file3-60b91f1875424d3b4322b0fdd0529d5d.js",
        "controllers/file1": "/test_assets/controllers/file1-d6de7dda18e17ed6844177361885b573.js",
        "controllers": "/test_assets/controllers/_index-f1ad8dddbf5c5f61ce4cb6fd502f4625.js",
        "controllers/file4": "/test_assets/controllers/_file4-857c6673d7149465c8ced446769b523c.js",
        "a_folder/file1": "/test_assets/a_folder/_file1-a25b4de866d9174a3ab79704b35efd13.js"
      }
    }
    |}]
;;

let%expect_test "it generates a module list to preload" =
  create_files ();
  let importmaps =
    RealityAssets.generate_importmap
      ~path:"test_assets/"
      [ "another_import", "path_of_another_import" ]
  in
  delete_files ();
  let _ = Format.printf "%a" (List.pp String.pp) importmaps.modules in
  [%expect
    {|
    "path_of_another_import",
    "/test_assets/file1-5149d403009a139c7e085405ef762e1a.js",
    "/test_assets/controllers/file3-60b91f1875424d3b4322b0fdd0529d5d.js",
    "/test_assets/controllers/file1-d6de7dda18e17ed6844177361885b573.js",
    "/test_assets/controllers/_index-f1ad8dddbf5c5f61ce4cb6fd502f4625.js",
    "/test_assets/controllers/_file4-857c6673d7149465c8ced446769b523c.js",
    "/test_assets/a_folder/_file1-a25b4de866d9174a3ab79704b35efd13.js"
    |}]
;;

(*===========================================================================*
 * Functor
 *===========================================================================*)

let () = create_files ()

module TestAssetConfig = struct
  let asset_map = RealityAssets.fingerprint ~path:"test_assets/" ()
  let importmaps = RealityAssets.generate_importmap ~path:"test_assets/" []
  let js_entrypoint = "application"
end

let () = delete_files ()

module TestAssets = RealityAssets.Make (TestAssetConfig)

(*-- String Module ---------------------------------------------------------*)
let%test_module "String HTML Tags" =
  (module struct
    let%expect_test "it generates importmap tag" =
      let _ = Format.printf "%s" TestAssets.String.importmap_tag in
      [%expect
        {|
        <script type="importmap">{
          "imports": {
            "file1": "/test_assets/file1-5149d403009a139c7e085405ef762e1a.js",
            "controllers/file3": "/test_assets/controllers/file3-60b91f1875424d3b4322b0fdd0529d5d.js",
            "controllers/file1": "/test_assets/controllers/file1-d6de7dda18e17ed6844177361885b573.js",
            "controllers": "/test_assets/controllers/_index-f1ad8dddbf5c5f61ce4cb6fd502f4625.js",
            "controllers/file4": "/test_assets/controllers/_file4-857c6673d7149465c8ced446769b523c.js",
            "a_folder/file1": "/test_assets/a_folder/_file1-a25b4de866d9174a3ab79704b35efd13.js"
          }
        }<script>
        <link rel="modulepreload" href="/test_assets/file1-5149d403009a139c7e085405ef762e1a.js">
        <link rel="modulepreload" href="/test_assets/controllers/file3-60b91f1875424d3b4322b0fdd0529d5d.js">
        <link rel="modulepreload" href="/test_assets/controllers/file1-d6de7dda18e17ed6844177361885b573.js">
        <link rel="modulepreload" href="/test_assets/controllers/_index-f1ad8dddbf5c5f61ce4cb6fd502f4625.js">
        <link rel="modulepreload" href="/test_assets/controllers/_file4-857c6673d7149465c8ced446769b523c.js">
        <link rel="modulepreload" href="/test_assets/a_folder/_file1-a25b4de866d9174a3ab79704b35efd13.js">
        |}]
    ;;

    let%expect_test "it generates js entrypoint tag" =
      let _ = Format.printf "%s" TestAssets.String.js_entrypoint_tag in
      [%expect {| <script type="module" defer >import "application"</script> |}]
    ;;
  end)
;;

(*-- PureHTML Module --------------------------------------------------------*)
let%test_module "PureHTML Tags" =
  (module struct
    let%expect_test "it generates importmap tag" =
      let _ = Format.printf "%a" Pure_html.pp TestAssets.PureHTML.importmap_tag in
      [%expect
        {|
        <script type="importmap">{
          "imports": {
            "file1": "/test_assets/file1-5149d403009a139c7e085405ef762e1a.js",
            "controllers/file3": "/test_assets/controllers/file3-60b91f1875424d3b4322b0fdd0529d5d.js",
            "controllers/file1": "/test_assets/controllers/file1-d6de7dda18e17ed6844177361885b573.js",
            "controllers": "/test_assets/controllers/_index-f1ad8dddbf5c5f61ce4cb6fd502f4625.js",
            "controllers/file4": "/test_assets/controllers/_file4-857c6673d7149465c8ced446769b523c.js",
            "a_folder/file1": "/test_assets/a_folder/_file1-a25b4de866d9174a3ab79704b35efd13.js"
          }
        }</script>
        <link rel="modulepreload" href="/test_assets/file1-5149d403009a139c7e085405ef762e1a.js">
        <link rel="modulepreload" href="/test_assets/controllers/file3-60b91f1875424d3b4322b0fdd0529d5d.js">
        <link rel="modulepreload" href="/test_assets/controllers/file1-d6de7dda18e17ed6844177361885b573.js">
        <link rel="modulepreload" href="/test_assets/controllers/_index-f1ad8dddbf5c5f61ce4cb6fd502f4625.js">
        <link rel="modulepreload" href="/test_assets/controllers/_file4-857c6673d7149465c8ced446769b523c.js">
        <link rel="modulepreload" href="/test_assets/a_folder/_file1-a25b4de866d9174a3ab79704b35efd13.js">
        |}]
    ;;

    let%expect_test "it generates js entrypoint tag" =
      let _ = Format.printf "%a" Pure_html.pp TestAssets.PureHTML.js_entrypoint_tag in
      [%expect {| <script type="module" defer>import "application"</script> |}]
    ;;
  end)
;;

(*-- path function ----------------------------------------------------------*)
let%test_module "path" =
  (module struct
    let%expect_test "it returns the fingerprinted path for the given filename" =
      let _ = Format.printf "%s" @@ TestAssets.path ~path:"test_assets/" "file1.js" in
      [%expect {| /test_assets/file1-5149d403009a139c7e085405ef762e1a.js |}]
    ;;

    let%expect_test "it returns the fingerprinted path for nested files" =
      let _ =
        Format.printf "%s" @@ TestAssets.path ~path:"test_assets/" "controllers/_file4.js"
      in
      [%expect {| /test_assets/controllers/_file4-857c6673d7149465c8ced446769b523c.js |}]
    ;;

    let%expect_test "it returns the path for non-fingerprinted files" =
      let _ =
        Format.printf "%s" @@ TestAssets.path ~path:"test_assets/" "another_file.js"
      in
      [%expect {| /test_assets/another_file.js |}]
    ;;
  end)
;;
