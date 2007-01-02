(* **********************************************************************
 *
 * Wrapping for FUNCTORS and MODULES
 * 
 *
 * $Id$
 *
 * **********************************************************************)

type info = int

type ('pred, 'mvar) wrapped_ctl = 
    ('pred * 'mvar Ast_ctl.modif,  'mvar, info) Ast_ctl.generic_ctl

type ('value, 'pred) wrapped_binding = 
  | ClassicVal of 'value
  | PredVal of 'pred Ast_ctl.modif

type ('pred,'state,'mvar,'value) labelfunc =
    'pred -> ('state * ('mvar, 'value) Ast_ctl.generic_substitution) list

type ('pred,'state,'mvar,'value,'wit) wrapped_labelfunc =
    ('pred * 'mvar Ast_ctl.modif) -> 
      ('state * 
       ('mvar, ('value,'pred) wrapped_binding) Ast_ctl.generic_substitution *
       'wit)
	list




(* ********************************************************************** *)
(* Module type: CTL_ENGINE_BIS (wrapper for CTL_ENGINE)                   *)
(* ********************************************************************** *)

(* This module must convert the labelling function passed as parameter, by
   using convert_label. Then create a SUBST2 module handling the
   wrapped_binding.  Then it can instantiates the generic CTL_ENGINE
   module. Call sat.  And then process the witness tree to remove all that
   is not revelevant for the transformation phase.
*)

module CTL_ENGINE_BIS =
  functor (SUB : Ctl_engine.SUBST) ->
    functor (G : Ctl_engine.GRAPH) ->
      functor(P : Ctl_engine.PREDICATE) ->
struct

  exception TODO_CTL of string  (* implementation still not quite done so... *)
  exception NEVER_CTL of string		  (* Some things should never happen *)

  module A = Ast_ctl

  type predicate = P.t
  module WRAPPER_ENV =
  struct
    type mvar = SUB.mvar
    type value = (SUB.value,predicate) wrapped_binding
    let eq_mvar = SUB.eq_mvar
    let eq_val wv1 wv2 = 
      match (wv1,wv2) with
	| (ClassicVal(v1),ClassicVal(v2)) -> SUB.eq_val v1 v2
	| (PredVal(v1),PredVal(v2))       -> v1 = v2   (* FIX ME: ok? *)
	| _                               -> false
    let merge_val wv1 wv2 = 
      match (wv1,wv2) with
	| (ClassicVal(v1),ClassicVal(v2)) -> ClassicVal(SUB.merge_val v1 v2)
	| _                               -> wv1       (* FIX ME: ok? *)


    let print_mvar x = SUB.print_mvar x
    let print_value x = 
      match x with
	ClassicVal v -> SUB.print_value v
      | PredVal(A.Modif v) -> P.print_predicate v
      | PredVal(A.UnModif v) -> P.print_predicate v
      |	PredVal(A.Control) -> Format.print_string "no value"
  end

  module WRAPPER_PRED = 
    struct 
      type t = P.t * SUB.mvar Ast_ctl.modif
      let print_predicate (pred, modif) = 
        begin
          P.print_predicate pred;
	  (match modif with
	    Ast_ctl.Modif x | Ast_ctl.UnModif x ->
	      Format.print_string " with <modifTODO>"
	  | Ast_ctl.Control -> ())
        end
    end

  (* Instantiate a wrapped version of CTL_ENGINE *)
  module WRAPPER_ENGINE =
    Ctl_engine.CTL_ENGINE (WRAPPER_ENV) (G) (WRAPPER_PRED)

  (* Wrap a label function *)
  let (wrap_label: ('pred,'state,'mvar,'value) labelfunc -> 
	('pred,'state,'mvar,'value,'wit) wrapped_labelfunc)
      = fun oldlabelfunc ->  fun (p, predvar) ->
	let penv = 
	  match predvar with
	    | A.Modif(x)   -> [A.Subst(x,PredVal(A.Modif(p)))]
	    | A.UnModif(x) -> [A.Subst(x,PredVal(A.UnModif(p)))]
	    | A.Control    -> [] in
	let conv_sub sub =
	  match sub with
	    | A.Subst(x,v)    -> A.Subst(x,ClassicVal(v))
	    | A.NegSubst(x,v) -> A.NegSubst(x,ClassicVal(v)) in
	let conv_trip (s,env) = (s,penv @ (List.map conv_sub env),[]) in
        List.map conv_trip (oldlabelfunc p)

  (* ---------------------------------------------------------------- *)

  (* FIX ME: what about negative witnesses and negative substitutions *)
  exception NEGATIVE_WITNESS
  let unwrap_wits prev_env wits modifonly =
    let mkth th =
      Common.map_filter
	(function A.Subst(x,ClassicVal(v)) -> Some (x,v) | _ -> None)
	th in
    let rec no_negwits = function
	A.Wit(st,th,anno,wit) -> List.for_all no_negwits wit
      | A.NegWit(_) -> false in
    let rec loop neg acc = function
	A.Wit(st,[A.Subst(x,PredVal(A.Modif(v)))],anno,wit) ->
	  (match wit with
	    [] -> [(st,acc,v)]
	  | _ -> raise (NEVER_CTL "predvar tree should have no children"))
      | A.Wit(st,[A.Subst(x,PredVal(A.UnModif(v)))],anno,wit)
	when not modifonly ->
	  (match wit with
	    [] -> [(st,acc,v)]
	  | _ -> raise (NEVER_CTL "predvar tree should have no children"))
      | A.Wit(st,th,anno,wit) ->
	  List.concat (List.map (loop neg ((mkth th) @ acc)) wit)
      | A.NegWit(st,th,anno,wit) ->
	  if List.for_all no_negwits wit
	  then raise NEGATIVE_WITNESS
	  else raise (TODO_CTL "nested negative witnesses") in
    List.concat
      (List.map
	 (function wit ->
	   try loop false prev_env wit
	   with NEGATIVE_WITNESS -> [])
	 wits)
  ;;

  exception INCOMPLETE_BINDINGS of SUB.mvar
  let collect_used_after used_after envs =
    let print_var var = SUB.print_mvar var; Format.print_flush() in
    List.concat
      (List.map
	 (function used_after_var ->
	   let vl =
	     List.fold_left
	       (function rest ->
		 function env ->
		   try
		     let vl = List.assoc used_after_var env in
		     match rest with
		       None -> Some vl
		     | Some old_vl when SUB.eq_val vl old_vl -> rest
		     | Some old_vl -> print_var used_after_var;
			 Format.print_newline();
			 SUB.print_value old_vl;
			 Format.print_newline();
			 SUB.print_value vl;
			 Format.print_newline();
			 failwith "incompatible values"
		   with Not_found -> rest)
	       None envs in
	   match vl with
	     None -> [] (*raise (INCOMPLETE_BINDINGS used_after_var)*)
	   | Some vl -> [(used_after_var, vl)])
	 used_after)
      
  (* ------------------ Partial matches ------------------ *)
  (* Limitation: this only gives information about terms with PredVals, which
     can be optimized to only those with modifs *)
  let collect_predvar_bindings res =
    let wits = List.concat (List.map (fun (_,_,w) -> w) res) in
    let rec loop = function
	A.Wit(st,th,anno,wit) ->
	  (Common.map_filter
	    (function A.Subst(_,(PredVal(_) as x)) -> Some (st,x) | _ -> None)
	    th) @
	  (List.concat (List.map loop wit))
      | A.NegWit(st,th,anno,wit) -> loop (A.Wit(st,th,anno,wit)) in
    List.fold_left Common.union_set [] (List.map loop wits)

  let check_conjunction phipsi res_phi res_psi res_phipsi = () (*
    let phi_code = collect_predvar_bindings res_phi in
    let psi_code = collect_predvar_bindings res_psi in
    let all_code = collect_predvar_bindings res_phipsi in
    let check str = function
	[] -> ()
      |	l ->
	  Printf.printf "Warning: The conjunction derived from SP line %d:\n"
	    (Ast_ctl.get_line phipsi);
	  Printf.printf
	    "drops code matched on the %s side at the following nodes\naccording to the corresponding predicates\n" str;
	  List.iter
	    (function (n,x) ->
	      G.print_node n; Format.print_flush(); Printf.printf ": ";
	      WRAPPER_ENV.print_value x; Format.print_flush();
	      Printf.printf "\n")
	    l in
    check "left" (Common.minus_set phi_code all_code);
    check "right" (Common.minus_set psi_code all_code) *)

  (* ----------------------------------------------------- *)

  (* The wrapper for sat from the CTL_ENGINE *)
  let satbis_noclean (grp,lab,states) (phi,reqopt) :
      ('pred,'anno) WRAPPER_ENGINE.triples =
    WRAPPER_ENGINE.sat (grp,wrap_label lab,states) phi reqopt check_conjunction
      
  (* Returns the "cleaned up" result from satbis_noclean *)
  let (satbis :
         G.cfg *
	 (predicate,G.node,SUB.mvar,SUB.value) labelfunc *
         G.node list -> 
	   ((predicate,SUB.mvar) wrapped_ctl *
	      (WRAPPER_PRED.t list * WRAPPER_PRED.t list)) ->
	     (WRAPPER_ENV.mvar list * (SUB.mvar * SUB.value) list) ->
               ((G.node * (SUB.mvar * SUB.value) list * predicate) list *
		  bool *
		  (WRAPPER_ENV.mvar * SUB.value) list,
		SUB.mvar) Common.either) =
    fun m phi (used_after, binding) ->
      let noclean = satbis_noclean m phi in
      let res =
	Common.uniq
	  (List.concat
	     (List.map (fun (_,_,w) -> unwrap_wits binding w true) noclean)) in
      let unmodif_res =
	Common.uniq
	  (List.concat
	     (List.map (fun (_,_,w) -> unwrap_wits binding w false)
		noclean)) in
      Printf.printf "modified:\n";
      List.iter (function x -> Printf.printf "%s\n" (Dumper.dump x)) res;
      try
	Common.Left
	  (res,not(noclean = []),
	   (* throw in the old binding.  By construction it doesn't conflict
           with any of the new things, and it is useful if there are no new
	   things.  One could then wonder whether unwrap_wits needs
	   binding as an argument. *)
	      collect_used_after used_after
		(binding ::
		 (List.map (function (_,env,_) -> env) unmodif_res)))
      with INCOMPLETE_BINDINGS x -> Common.Right x

let print_bench _ = WRAPPER_ENGINE.print_bench()

(* END OF MODULE: CTL_ENGINE_BIS *)
end
