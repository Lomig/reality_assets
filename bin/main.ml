open Containers

let help () =
  let help_text =
    {|RealityAssets - Assets Management tool for OCaml/Dream projects

USAGE:
  reality_assets [OPTION]

OPTIONS:
  install          Sets up TailwindCSS in a project, including Stimulus controllers and import maps
  help             Display this help message

EXAMPLE:
  reality_assets install

For more information, visit: https://github.com/Lomig/reality_assets|}
  in
  print_endline help_text
;;

let () =
  match Option.map String.lowercase_ascii @@ Array.get_safe Sys.argv 1 with
  | Some "install" -> Installation.install ()
  | _ -> help ()
;;
