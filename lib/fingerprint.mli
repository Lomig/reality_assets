(** [is_fingerprinted filename] checks if the given filename already contains
    an MD5 fingerprint. Returns [true] if the file is fingerprinted,
    [false] otherwise. *)
val is_fingerprinted : string -> bool

(** [add_to filename] returns a new filename with the MD5 fingerprint added.
    If the file is already fingerprinted, returns the original filename unchanged. *)
val add_to : string -> string

(** [remove_from filename] returns a new filename with the MD5 fingerprint removed.
    If the file is not fingerprinted, returns the original filename unchanged. *)
val remove_from : string -> string

(** [rename_file filename] renames the file by adding an MD5 fingerprint to its name.
    If the file is already fingerprinted, does nothing. *)
val rename_file : string -> unit
