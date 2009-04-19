open Common 

(* This module tries to detect some cpp idioms so that we can parse as-is
 * files by adjusting or commenting some tokens. Parsing hack style. 
 * Sometime we use some indentation information,
 * sometimes we do some kind of lalr(k) by finding patterns. Often try to
 * work on better token representation, like ifdef-paren-ized, brace-ized,
 * paren-ized, so can do easier pattern matching to more easily match
 * complex cpp idiom pattern (cf token_views_c.ml). 
 * We also try to get more contextual information such as whether the 
 * token is in a initializer as some common patterns have different
 * use depending on context.
 * 
 * 
 * Example of cpp idioms:
 *  - if 0 for commenting stuff (not always code, sometimes just real comments)
 *  - ifdef old version
 *  - ifdef funheader
 *  - ifdef statements, ifdef expression, ifdef-mid
 *  - macro toplevel (with or without ptvirg)
 *  - macro foreach
 *  - macro higher order
 *  - macro declare
 *  - macro debug
 *  - macro no ptvirg
 *  - macro string, and macro function string taking param and ##
 *  - macro attribute
 * 
 * Cf the TMacroXxx in parser_c.mly and MacroXxx in ast_c.ml
 * 
 * Also try to infer typedef.
 * 
 * Also do other stuff involving cpp like expanding some macros, 
 * or try parse well define body by finding the end of define virtual 
 * end-of-line token. But now most of the code is actually in cpp_token_c.ml
 * It is related to what is in the yacfe configuration file (e.g. standard.h)
 *)

val regexp_macro: Str.regexp
val regexp_annot: Str.regexp
val regexp_declare: Str.regexp
val regexp_foreach: Str.regexp
val regexp_typedef: Str.regexp

(* usually correspond to what is inside your standard.h *)
val _defs : (string, Cpp_token_c.define_def) Hashtbl.t ref

(* can reset this global *)
val ifdef_paren_cnt: int ref

val fix_tokens_cpp : Parser_c.token list -> Parser_c.token list

(* next stream tokens -> passed stream tokens -> final next token *)
val lookahead : 
  pass:int -> 
  Parser_c.token list -> Parser_c.token list -> Parser_c.token


