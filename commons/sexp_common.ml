open Common

let either_of_sexp__ =
  let _loc = "Xxx.either"
  in
    fun _of_a _of_b ->
      function
      | (Sexp.List (Sexp.Atom (("left" | "Left" as tag)) :: sexp_args) as
         sexp) ->
          (match sexp_args with
           | [ v1 ] -> let v1 = _of_a v1 in Left v1
           | _ -> Conv_error.stag_incorrect_n_args _loc tag sexp)
      | (Sexp.List (Sexp.Atom (("right" | "Right" as tag)) :: sexp_args) as
         sexp) ->
          (match sexp_args with
           | [ v1 ] -> let v1 = _of_b v1 in Right v1
           | _ -> Conv_error.stag_incorrect_n_args _loc tag sexp)
      | (Sexp.Atom ("left" | "Left") as sexp) ->
          Conv_error.stag_takes_args _loc sexp
      | (Sexp.Atom ("right" | "Right") as sexp) ->
          Conv_error.stag_takes_args _loc sexp
      | (Sexp.List (Sexp.List _ :: _) as sexp) ->
          Conv_error.nested_list_invalid_sum _loc sexp
      | (Sexp.List [] as sexp) -> Conv_error.empty_list_invalid_sum _loc sexp
      | sexp -> Conv_error.unexpected_stag _loc sexp
  
let either_of_sexp _of_a _of_b sexp = either_of_sexp__ _of_a _of_b sexp
  
let sexp_of_either _of_a _of_b =
  function
  | Left v1 -> let v1 = _of_a v1 in Sexp.List [ Sexp.Atom "Left"; v1 ]
  | Right v1 -> let v1 = _of_b v1 in Sexp.List [ Sexp.Atom "Right"; v1 ]
  
let either3_of_sexp__ =
  let _loc = "Xxx.either3"
  in
    fun _of_a _of_b _of_c ->
      function
      | (Sexp.List (Sexp.Atom (("left3" | "Left3" as tag)) :: sexp_args) as
         sexp) ->
          (match sexp_args with
           | [ v1 ] -> let v1 = _of_a v1 in Left3 v1
           | _ -> Conv_error.stag_incorrect_n_args _loc tag sexp)
      | (Sexp.List (Sexp.Atom (("middle3" | "Middle3" as tag)) :: sexp_args)
         as sexp) ->
          (match sexp_args with
           | [ v1 ] -> let v1 = _of_b v1 in Middle3 v1
           | _ -> Conv_error.stag_incorrect_n_args _loc tag sexp)
      | (Sexp.List (Sexp.Atom (("right3" | "Right3" as tag)) :: sexp_args) as
         sexp) ->
          (match sexp_args with
           | [ v1 ] -> let v1 = _of_c v1 in Right3 v1
           | _ -> Conv_error.stag_incorrect_n_args _loc tag sexp)
      | (Sexp.Atom ("left3" | "Left3") as sexp) ->
          Conv_error.stag_takes_args _loc sexp
      | (Sexp.Atom ("middle3" | "Middle3") as sexp) ->
          Conv_error.stag_takes_args _loc sexp
      | (Sexp.Atom ("right3" | "Right3") as sexp) ->
          Conv_error.stag_takes_args _loc sexp
      | (Sexp.List (Sexp.List _ :: _) as sexp) ->
          Conv_error.nested_list_invalid_sum _loc sexp
      | (Sexp.List [] as sexp) -> Conv_error.empty_list_invalid_sum _loc sexp
      | sexp -> Conv_error.unexpected_stag _loc sexp
  
let either3_of_sexp _of_a _of_b _of_c sexp =
  either3_of_sexp__ _of_a _of_b _of_c sexp
  
let sexp_of_either3 _of_a _of_b _of_c =
  function
  | Left3 v1 -> let v1 = _of_a v1 in Sexp.List [ Sexp.Atom "Left3"; v1 ]
  | Middle3 v1 -> let v1 = _of_b v1 in Sexp.List [ Sexp.Atom "Middle3"; v1 ]
  | Right3 v1 -> let v1 = _of_c v1 in Sexp.List [ Sexp.Atom "Right3"; v1 ]
  
let filename_of_sexp__ =
  let _loc = "Xxx.filename" in fun sexp -> Conv.string_of_sexp sexp
  
let filename_of_sexp sexp =
  try filename_of_sexp__ sexp
  with
  | Conv_error.No_variant_match ((msg, sexp)) -> Conv.of_sexp_error msg sexp
  
let sexp_of_filename v = Conv.sexp_of_string v
  
let dirname_of_sexp__ =
  let _loc = "Xxx.dirname" in fun sexp -> Conv.string_of_sexp sexp
  
let dirname_of_sexp sexp =
  try dirname_of_sexp__ sexp
  with
  | Conv_error.No_variant_match ((msg, sexp)) -> Conv.of_sexp_error msg sexp
  
let sexp_of_dirname v = Conv.sexp_of_string v
  
let set_of_sexp__ =
  let _loc = "Xxx.set" in fun _of_a -> Conv.list_of_sexp _of_a
  
let set_of_sexp _of_a sexp =
  try set_of_sexp__ _of_a sexp
  with
  | Conv_error.No_variant_match ((msg, sexp)) -> Conv.of_sexp_error msg sexp
  
let sexp_of_set _of_a = Conv.sexp_of_list _of_a
  
let assoc_of_sexp__ =
  let _loc = "Xxx.assoc"
  in
    fun _of_a _of_b ->
      Conv.list_of_sexp
        (function
         | Sexp.List ([ v1; v2 ]) ->
             let v1 = _of_a v1 and v2 = _of_b v2 in (v1, v2)
         | sexp -> Conv_error.tuple_of_size_n_expected _loc 2 sexp)
  
let assoc_of_sexp _of_a _of_b sexp =
  try assoc_of_sexp__ _of_a _of_b sexp
  with
  | Conv_error.No_variant_match ((msg, sexp)) -> Conv.of_sexp_error msg sexp
  
let sexp_of_assoc _of_a _of_b =
  Conv.sexp_of_list
    (fun (v1, v2) ->
       let v1 = _of_a v1 and v2 = _of_b v2 in Sexp.List [ v1; v2 ])
  
let hashset_of_sexp__ =
  let _loc = "Xxx.hashset"
  in fun _of_a -> Conv.hashtbl_of_sexp _of_a Conv.bool_of_sexp
  
let hashset_of_sexp _of_a sexp =
  try hashset_of_sexp__ _of_a sexp
  with
  | Conv_error.No_variant_match ((msg, sexp)) -> Conv.of_sexp_error msg sexp
  
let sexp_of_hashset _of_a = Conv.sexp_of_hashtbl _of_a Conv.sexp_of_bool
  
let stack_of_sexp__ =
  let _loc = "Xxx.stack" in fun _of_a -> Conv.list_of_sexp _of_a
  
let stack_of_sexp _of_a sexp =
  try stack_of_sexp__ _of_a sexp
  with
  | Conv_error.No_variant_match ((msg, sexp)) -> Conv.of_sexp_error msg sexp
  
let sexp_of_stack _of_a = Conv.sexp_of_list _of_a
  
let parse_info_of_sexp__ =
  let _loc = "Xxx.parse_info"
  in
    function
    | (Sexp.List field_sexps as sexp) ->
        let str_field = ref None and charpos_field = ref None
        and line_field = ref None and column_field = ref None
        and file_field = ref None and duplicates = ref []
        and extra = ref [] in
        let rec iter =
          (function
           | Sexp.List ([ Sexp.Atom field_name; field_sexp ]) :: tail ->
               ((match field_name with
                 | "str" ->
                     (match !str_field with
                      | None ->
                          let fvalue = Conv.string_of_sexp field_sexp
                          in str_field := Some fvalue
                      | Some _ -> duplicates := field_name :: !duplicates)
                 | "charpos" ->
                     (match !charpos_field with
                      | None ->
                          let fvalue = Conv.int_of_sexp field_sexp
                          in charpos_field := Some fvalue
                      | Some _ -> duplicates := field_name :: !duplicates)
                 | "line" ->
                     (match !line_field with
                      | None ->
                          let fvalue = Conv.int_of_sexp field_sexp
                          in line_field := Some fvalue
                      | Some _ -> duplicates := field_name :: !duplicates)
                 | "column" ->
                     (match !column_field with
                      | None ->
                          let fvalue = Conv.int_of_sexp field_sexp
                          in column_field := Some fvalue
                      | Some _ -> duplicates := field_name :: !duplicates)
                 | "file" ->
                     (match !file_field with
                      | None ->
                          let fvalue = filename_of_sexp field_sexp
                          in file_field := Some fvalue
                      | Some _ -> duplicates := field_name :: !duplicates)
                 | _ ->
                     if !Conv.record_check_extra_fields
                     then extra := field_name :: !extra
                     else ());
                iter tail)
           | sexp :: _ -> Conv_error.record_only_pairs_expected _loc sexp
           | [] -> ())
        in
          (iter field_sexps;
           if !duplicates <> []
           then Conv_error.record_duplicate_fields _loc !duplicates sexp
           else
             if !extra <> []
             then Conv_error.record_extra_fields _loc !extra sexp
             else
               (match ((!str_field), (!charpos_field), (!line_field),
                       (!column_field), (!file_field))
                with
                | (Some str_value, Some charpos_value, Some line_value,
                   Some column_value, Some file_value) ->
                    {
                      str = str_value;
                      charpos = charpos_value;
                      line = line_value;
                      column = column_value;
                      file = file_value;
                    }
                | _ ->
                    Conv_error.record_undefined_elements _loc sexp
                      [ ((!str_field = None), "str");
                        ((!charpos_field = None), "charpos");
                        ((!line_field = None), "line");
                        ((!column_field = None), "column");
                        ((!file_field = None), "file") ]))
    | (Sexp.Atom _ as sexp) -> Conv_error.record_list_instead_atom _loc sexp
  
let parse_info_of_sexp sexp = parse_info_of_sexp__ sexp
  
let sexp_of_parse_info {
                         str = v_str;
                         charpos = v_charpos;
                         line = v_line;
                         column = v_column;
                         file = v_file
                       } =
  let bnds = [] in
  let arg = sexp_of_filename v_file in
  let bnd = Sexp.List [ Sexp.Atom "file"; arg ] in
  let bnds = bnd :: bnds in
  let arg = Conv.sexp_of_int v_column in
  let bnd = Sexp.List [ Sexp.Atom "column"; arg ] in
  let bnds = bnd :: bnds in
  let arg = Conv.sexp_of_int v_line in
  let bnd = Sexp.List [ Sexp.Atom "line"; arg ] in
  let bnds = bnd :: bnds in
  let arg = Conv.sexp_of_int v_charpos in
  let bnd = Sexp.List [ Sexp.Atom "charpos"; arg ] in
  let bnds = bnd :: bnds in
  let arg = Conv.sexp_of_string v_str in
  let bnd = Sexp.List [ Sexp.Atom "str"; arg ] in
  let bnds = bnd :: bnds in Sexp.List bnds
  


let score_result_of_sexp__ =
  let _loc = "Xxx.score_result"
  in
    function
    | Sexp.Atom ("ok" | "Ok") -> Ok
    | (Sexp.List (Sexp.Atom (("pb" | "Pb" as tag)) :: sexp_args) as sexp) ->
        (match sexp_args with
         | [ v1 ] -> let v1 = Conv.string_of_sexp v1 in Pb v1
         | _ -> Conv_error.stag_incorrect_n_args _loc tag sexp)
    | (Sexp.List (Sexp.Atom ("ok" | "Ok") :: _) as sexp) ->
        Conv_error.stag_no_args _loc sexp
    | (Sexp.Atom ("pb" | "Pb") as sexp) ->
        Conv_error.stag_takes_args _loc sexp
    | (Sexp.List (Sexp.List _ :: _) as sexp) ->
        Conv_error.nested_list_invalid_sum _loc sexp
    | (Sexp.List [] as sexp) -> Conv_error.empty_list_invalid_sum _loc sexp
    | sexp -> Conv_error.unexpected_stag _loc sexp
  
let score_result_of_sexp sexp = score_result_of_sexp__ sexp
  
let sexp_of_score_result =
  function
  | Ok -> Sexp.Atom "Ok"
  | Pb v1 ->
      let v1 = Conv.sexp_of_string v1 in Sexp.List [ Sexp.Atom "Pb"; v1 ]
  
let score_of_sexp__ =
  let _loc = "Xxx.score"
  in
    fun sexp ->
      Conv.hashtbl_of_sexp Conv.string_of_sexp score_result_of_sexp sexp
  
let score_of_sexp sexp =
  try score_of_sexp__ sexp
  with
  | Conv_error.No_variant_match ((msg, sexp)) -> Conv.of_sexp_error msg sexp
  
let sexp_of_score v =
  Conv.sexp_of_hashtbl Conv.sexp_of_string sexp_of_score_result v
  

let score_list_of_sexp__ =
  let _loc = "Xxx.score_list"
  in
    fun sexp ->
      Conv.list_of_sexp
        (function
         | Sexp.List ([ v1; v2 ]) ->
             let v1 = Conv.string_of_sexp v1
             and v2 = score_result_of_sexp v2
             in (v1, v2)
         | sexp -> Conv_error.tuple_of_size_n_expected _loc 2 sexp)
        sexp
  
let score_list_of_sexp sexp =
  try score_list_of_sexp__ sexp
  with
  | Conv_error.No_variant_match ((msg, sexp)) -> Conv.of_sexp_error msg sexp
  
let sexp_of_score_list v =
  Conv.sexp_of_list
    (fun (v1, v2) ->
       let v1 = Conv.sexp_of_string v1
       and v2 = sexp_of_score_result v2
       in Sexp.List [ v1; v2 ])
    v
