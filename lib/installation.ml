open Containers

let dune_file_content =
  {|
;------------------------------------------------------------------------------
; Reality Assets
;------------------------------------------------------------------------------

(rule
 (target building_js_assets)
 (deps
  (source_tree %{project_root}/lib/client/javascript))
 (action
  (progn
   (run echo "Building JS...")
   (run
    cp
    -R
    %{project_root}/../../lib/client/javascript/.
    %{project_root}/../../static/)
   (run touch building_js_assets))))|}
;;

let assets_file_content =
  {|let imports =
    [ "@hotwired/stimulus", "https://cdn.skypack.dev/@hotwired/stimulus@v3.2.2"
    ; "@hotwired/stimulus-loading", "/static/pinned/stimulus-loading@v0.0.1.js"
    ]
  ;;

  module AssetConfig = struct
    let asset_map = Assets.fingerprint ()
    let importmaps = Assets.generate_importmap imports
    let js_entrypoint = "application"
  end

  include Assets.Make (AssetConfig)|}
;;

let stimulus_index_js =
  {|// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)|}
;;

let stimulus_application_js =
  {|import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }|}
;;

let print_step msg =
  Printf.printf "\027[0;34m→\027[0m %s...\n" msg;
  flush stdout
;;

let print_success msg =
  Printf.printf "\027[0;32m✓\027[0m %s\n" msg;
  flush stdout
;;

let print_error msg =
  Printf.printf "\027[0;31m✗\027[0m %s\n" msg;
  flush stdout
;;

let rec find_project_root current_dir =
  let dune_project = Filename.concat current_dir "dune-project" in
  if Sys.file_exists dune_project
  then Some current_dir
  else (
    let parent = Filename.dirname current_dir in
    if String.equal parent current_dir then None else find_project_root parent)
;;

let ensure_directory dir =
  if not (Sys.file_exists dir)
  then (
    print_step (Printf.sprintf "Creating directory %s" dir);
    Sys.mkdir dir 0o755;
    print_success "Directory created")
;;

let project_root () =
  print_step "Looking for Dune project root";
  match find_project_root (Sys.getcwd ()) with
  | None ->
    print_error "Not in a Dream project (no dune-project file found)";
    exit 1
  | Some project_root ->
    print_success (Printf.sprintf "Found project root at %s" project_root);
    project_root
;;

let check_if_dream_project project_root =
  print_step "Looking for Dream project";
  let regexp =
    Re.seq
      [ Re.str "(depends"
      ; Re.rep (Re.alt [ Re.alnum; Re.str " "; Re.str "-"; Re.str "_" ])
      ; Re.seq [ Re.bow; Re.str "dream"; Re.eow ]
      ; Re.rep (Re.alt [ Re.alnum; Re.str " "; Re.str "-"; Re.str "_" ])
      ; Re.str ")"
      ]
    |> Re.compile
  in
  let project_file = Filename.concat project_root "dune-project" in
  let file_content = IO.with_in project_file IO.read_all in
  match Re.execp regexp file_content with
  | true -> project_root
  | false ->
    print_error "Not in a Dream project (dune-project does not depend on Dream)";
    exit 1
;;

let append_to_dune project_root =
  print_step "Updating bin/dune configuration";
  let regexp = Re.seq [ Re.str "; Reality Assets" ] |> Re.compile in
  let dune_file = Filename.concat project_root "bin/dune" in
  let file_content = IO.with_in dune_file IO.read_all in
  (match Re.execp regexp file_content with
   | true -> print_error "Reality Assets already installed"
   | false ->
     IO.with_out_a dune_file (fun file -> IO.write_line file dune_file_content);
     print_success "Updated bin/dune configuration");
  project_root
;;

let create_dirs project_root =
  print_step "Creating directories";
  let dirs =
    [ Filename.concat project_root "static"
    ; Filename.concat project_root "lib"
    ; Filename.concat project_root "lib/client"
    ; Filename.concat project_root "lib/client/javascript"
    ; Filename.concat project_root "lib/client/javascript/controllers"
    ; Filename.concat project_root "lib/client/javascript/pinned"
    ]
  in
  List.iter ensure_directory dirs;
  print_success "Directories created";
  project_root
;;

let add_assets_file project_root =
  print_step "Adding assets.ml";
  let assets_file = Filename.concat project_root "lib/client/assets.ml" in
  if Sys.file_exists assets_file
  then print_error "assets.ml already exists"
  else (
    IO.with_out_a assets_file (fun file -> IO.write_line file assets_file_content);
    print_success "Added assets.ml");
  project_root
;;

let add_application_js project_root =
  print_step "Adding application.js";
  let application_js =
    Filename.concat project_root "lib/client/javascript/application.js"
  in
  if Sys.file_exists application_js
  then print_error "application.js already exists"
  else (
    IO.with_out_a application_js (fun file ->
      IO.write_line
        file
        {|import "controllers"

// Your JavaScript here|});
    print_success "Added application.js");
  project_root
;;

let add_stimulus_files project_root =
  print_step "Adding Stimulus files";
  let index_js =
    Filename.concat project_root "lib/client/javascript/controllers/_index.js"
  in
  let application_js =
    Filename.concat project_root "lib/client/javascript/controllers/_application.js"
  in
  if Sys.file_exists index_js || Sys.file_exists application_js
  then print_error "Stimulus files already exist"
  else (
    IO.with_out_a index_js (fun file -> IO.write_line file stimulus_index_js);
    IO.with_out_a application_js (fun file -> IO.write_line file stimulus_application_js);
    print_success "Added Stimulus files");
  project_root
;;

let add_pinned_libraries project_root =
  let open Cohttp_lwt_unix in
  let open Cohttp in
  print_step "Pinning libraries";
  let output =
    Filename.concat project_root "lib/client/javascript/pinned/stimulus-loading@v0.0.1.js"
  in
  let url =
    "https://raw.githubusercontent.com/hotwired/stimulus-rails/refs/tags/v1.3.4/app/assets/javascripts/stimulus-loading.js"
  in
  let response, body = Lwt_main.run @@ Client.get (Uri.of_string url) in
  let status = Response.status response in
  match Code.(is_success (Code.code_of_status status)) with
  | false ->
    print_error "Failed to pin 'Stimulus Loading'";
    project_root
  | true ->
    let content = Lwt_main.run @@ Cohttp_lwt.Body.to_string body in
    CCIO.with_out output (fun oc -> CCIO.write_line oc content);
    print_success "Pinned 'Stimulus Loading'";
    project_root
;;

let install () =
  let _ =
    project_root ()
    |> check_if_dream_project
    |> append_to_dune
    |> create_dirs
    |> add_assets_file
    |> add_application_js
    |> add_stimulus_files
    |> add_pinned_libraries
  in
  print_success "Reality Assets completed successfully!"
;;
