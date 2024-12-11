(lang dune 3.12)

(name prose)

(generate_opam_files true)

(source
 (github smjleo/prose))

(authors "Leo Lee")

(maintainers "Leo Lee")

(license LICENSE)

(documentation https://url/to/documentation)

(using menhir 2.1)

(package
 (name prose)
 (synopsis "A short synopsis")
 (description "A longer description")
 (depends ocaml dune)
 (tags
  (topics "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
