@script:ocaml r@
p;
@@

p := make_position "mdeclp.c" "one" 1 4 1 7

@@
position r.p;
identifier f;
@@

- f@p(...) { ... }
