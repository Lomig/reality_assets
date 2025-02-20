open Containers
module StringMap = Map.Make (String)

(*===========================================================================*
 * Asset Module Functor
 *===========================================================================*)

type assetmap = string StringMap.t

let assetmap_pp = StringMap.pp String.pp String.pp

type importmaps =
  { list : string
  ; modules : string list
  }

module type ASSETS = sig
  val asset_map : string StringMap.t
  val importmaps : importmaps
  val js_entrypoint : string
end

module Make (A : ASSETS) = struct
  let path ?(path = "static/") filename =
    match StringMap.find_opt (path ^ filename) A.asset_map with
    | Some fingerprinted_filename -> "/" ^ fingerprinted_filename
    | None -> "/" ^ path ^ filename
  ;;

  module PureHTML = struct
    open Pure_html
    open HTML

    let importmap_tag =
      let importmap_list = script [ type_ "importmap" ] "%s" A.importmaps.list in
      let preloaded_modules =
        List.map
          (fun file -> link [ rel "modulepreload"; href "%s" file ])
          A.importmaps.modules
      in
      null @@ (importmap_list :: preloaded_modules)
    ;;

    let js_entrypoint_tag =
      script [ type_ "module"; defer ] {|import "%s"|} A.js_entrypoint
    ;;
  end

  module String = struct
    let importmap_tag =
      let importmap_list =
        Format.sprintf {|<script type="importmap">%s<script>|} A.importmaps.list
      in
      let preloaded_modules =
        List.map
          (fun file -> Format.sprintf {|<link rel="modulepreload" href="%s">|} file)
          A.importmaps.modules
      in
      List.to_string ~sep:"\n" (fun s -> s) (importmap_list :: preloaded_modules)
    ;;

    let js_entrypoint_tag =
      Format.sprintf {|<script type="module" defer >import "%s"</script>|} A.js_entrypoint
    ;;
  end
end

(*===========================================================================*
 * Asset Module Initialization
 *===========================================================================*)

(*-- Helpers ----------------------------------------------------------------*)

let recursive_file_list dir =
  let rec aux acc = function
    | [] -> acc
    | file :: files ->
      (match Sys.is_directory file with
       | true when String.equal (Filename.basename file) "pinned" -> aux acc files
       | true ->
         let new_files =
           Sys.readdir file |> Array.to_list |> List.map (Filename.concat file)
         in
         aux acc (files @ new_files)
       | false -> aux (file :: acc) files)
  in
  aux [] [ dir ]
;;

let has_asset_been_updated filename asset_map =
  let original_filename = Fingerprint.remove_from filename in
  Fingerprint.is_fingerprinted filename
  && (Sys.file_exists original_filename
      ||
      match StringMap.find_opt original_filename asset_map with
      | Some fingerprint -> String.(fingerprint <> filename)
      | None -> false)
;;

(*-- Asset Map --------------------------------------------------------------*)

let fingerprint ?(path = "static/") () =
  recursive_file_list path
  |> List.fold_left
       (fun asset_map filename ->
          match has_asset_been_updated filename asset_map with
          | true ->
            Sys.remove filename;
            asset_map
          | false ->
            let original_filename = Fingerprint.remove_from filename in
            let fingerprinted_filename = Fingerprint.add_to filename in
            Fingerprint.rename_file filename;
            StringMap.add original_filename fingerprinted_filename asset_map)
       StringMap.empty
;;

(*-- Import Maps ------------------------------------------------------------*)

module ImportMap = struct
  type t = (string * string) list

  let to_json (list : t) =
    `Assoc [ "imports", `Assoc (list |> List.map (fun (k, v) -> k, `String v)) ]
    |> Yojson.Safe.pretty_to_string ~std:true
  ;;

  let to_module (list : t) = List.map (fun (_, v) -> v) list

  let asset_rewrite path original_filename fingerprinted_filename =
    let basename = Filename.basename original_filename |> Filename.remove_extension in
    let directory = String.chop_prefix ~pre:path @@ Filename.dirname original_filename in
    let name_without_underscore =
      Option.get_or ~default:basename @@ String.chop_prefix ~pre:"_" basename
    in
    let module_name =
      match directory, String.equal basename "_index" with
      | Some dir, true -> Filename.basename dir
      | None, true -> "index"
      | Some dir, false -> dir ^ "/" ^ name_without_underscore
      | None, false -> name_without_underscore
    in
    module_name, "/" ^ fingerprinted_filename
  ;;

  let from_asset_map path asset_map =
    StringMap.fold
      (fun k v acc ->
         match Filename.extension k with
         | ".js" -> asset_rewrite path k v :: acc
         | _ -> acc)
      asset_map
      []
  ;;
end

let generate_importmap ?(path = "static/") (import_list : ImportMap.t) =
  let importmap =
    fingerprint ~path () |> ImportMap.from_asset_map path |> List.append import_list
  in
  { list = ImportMap.to_json importmap; modules = ImportMap.to_module importmap }
;;
