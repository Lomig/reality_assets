(lang dune 3.17)

(name reality_assets)

(generate_opam_files true)

(source
 (github Lomig/reality_assets))

(authors "Lomig <lomig@hey.com>")

(maintainers "Lomig <lomig@hey.com>")

(license GPL-3.0-only)

(package
 (name reality_assets)
 (synopsis "Asset management library for the Dream web framework")
 (description
  "RealityAssets simplifies asset handling in Dream-based web applications by generating fingerprinted URLs for static files, improving cache efficiency. It also streamlines JavaScript organization by integrating Stimulus controllers and import maps, enabling clean, modular front-end code. With automatic asset resolution and efficient bundling, RealityAssets helps developers maintain a modern, performant web experience.")
 (depends
  ocaml
  containers
  dream
  pure-html
  re
  yojson
  ppx_inline_test
  cohttp-lwt-unix)
 (tags
  ("stimulus" "assets" "dream" "reality")))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
