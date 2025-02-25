# RealityAssets

RealityAssets is an opinionated asset management library for OCaml web development using the [Dream](https://github.com/aantron/dream) framework. It provides asset fingerprinting, JavaScript import maps, and integrates seamlessly with [StimulusJS](https://stimulus.hotwired.dev/), all without requiring traditional asset bundling.

## Features

- **Asset Fingerprinting**: Ensures cache-busting by renaming assets with a unique fingerprint.
- **Import Maps**: Uses [ImportMaps](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/script/type/importmap) instead of bundling JavaScript.
- **StimulusJS Integration**: Automatically installs StimulusJS for managing frontend JavaScript.
- **File Structure Enforcement**: Provides a CLI command to set up the expected project structure.
- **Dune Integration**: Adds rules to copy assets to the `static/` directory.
- **Works With RealityTailwindCSS**: Designed to complement [RealityTailwindCSS](https://github.com/Lomig/reality_tailwindcss), but flexible enough to support other approaches.

## Installation

To install RealityAssets, add it to your `opam` dependencies:

```sh
opam pin reality_assets.1.0.0 git+https://github.com/Lomig/reality_assets.git#main
```

Then, run the CLI install command to set up the necessary folder structure:

```sh
reality-assets install
```

This will create the following directory structure in your project:

```
project-root/
│── lib/
│   └── client/
│       ├── javascript/      # JavaScript source files
│       └── assets.ml        # Auto-generated OCaml module for asset handling
│── static/                  # Public assets folder
```

## Usage

### Asset Fingerprinting

RealityAssets fingerprints JavaScript files at web service startup, renaming them with a unique hash to ensure cache invalidation. However, files located in folders named "pinned" are not fingerprinted and retain their original names.

To manually trigger fingerprinting:

```ocaml
let asset_map = RealityAssets.fingerprint ()
```

### Generating Import Maps

The function creates the import map based on fingerprinted files from the static directory as well as the provided manual list with imports from external URLs or pinned packages

```ocaml
let importmaps = RealityAssets.generate_importmap [
  "@hotwired/stimulus", "https://cdn.skypack.dev/@hotwired/stimulus@v3.2.2";
  "@hotwired/stimulus-loading", "/static/pinned/stimulus-loading@v0.0.1.js"
]
```

### Using the Functor Interface

RealityAssets provides a functor to create an asset management module, but it also preconfigures client/assets.ml with sensible defaults upon installation. If needed, you can still use the functor for a custom setup tailored to your application's requirements:

```ocaml
module Assets = Assets.Make(struct
  let asset_map = asset_map
  let importmaps = importmaps
  let js_entrypoint = "the_name_of_the_module_to_import"
end)
```

### HTML Integration

RealityAssets provides functions to insert import maps and JavaScript entrypoints into HTML using [PureHTML](https://github.com/yourrepo/purehtml):

#### PureHTML Usage

```ocaml
let html_node = Assets.PureHTML.importmap_tag
```

#### String-Based HTML Generation

```ocaml
let html_string = Assets.String.importmap_tag
```

## Configuration

RealityAssets defaults to using `static/` as the asset directory, but this can be changed as needed.

To specify a different path within your project for asset fingerprinting:

```ocaml
let asset_map = Assets.fingerprint ~path:"custom_static/" ()
```

To generate an import map with a custom path:

```ocaml
let importmaps = RealityAssets.generate_importmap ~path:"custom_static/" [
  (* Your manual imports here *)
]
```

## License

RealityAssets is licensed under the GPL 3 License. See the `LICENSE` file for more details.

