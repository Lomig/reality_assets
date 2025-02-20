(** Asset management types and functions *)
type assetmap

val assetmap_pp : assetmap Fmt.t

(** Import map structure containing JSON and module list *)

type importmaps =
  { list : string (** JSON string containing the import map *)
  ; modules : string list (** List of module paths *)
  }

(** Input signature for the Make functor *)
module type ASSETS = sig
  val asset_map : assetmap
  val importmaps : importmaps
  val js_entrypoint : string
end

(** Functor to create an asset management module *)
module Make (_ : ASSETS) : sig
  (** [path ?path filename] returns the fingerprinted path for the given filename.
      @param path Optional path prefix, defaults to "static/"
      @return Path to the fingerprinted asset, starting with "/" *)
  val path : ?path:string -> string -> string

  (** HTML generation functions using Pure_html *)
  module PureHTML : sig
    val importmap_tag : Pure_html.node
    val js_entrypoint_tag : Pure_html.node
  end

  (** String-based HTML generation functions *)
  module String : sig
    val importmap_tag : string
    val js_entrypoint_tag : string
  end
end

(** [fingerprint ?path ()] creates a map of original filenames to their fingerprinted versions.
    Also performs the actual file renaming operations.
    @param path Optional path prefix, defaults to "static/"
    @return Map from original filenames to fingerprinted filenames *)
val fingerprint : ?path:string -> unit -> assetmap

(** [generate_importmap ?path import_list] generates import maps for JavaScript modules.
    @param path Optional path prefix, defaults to "static/"
    @param import_list List of module name and path pairs to include in the import map
    @return Import map structure containing JSON and module list *)
val generate_importmap : ?path:string -> (string * string) list -> importmaps
