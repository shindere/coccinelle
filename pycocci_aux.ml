open Ast_c
open Common
open Pycaml

let rec exprrep expr = match expr with
  Ast_c.Ident s -> s
| Ast_c.Constant c -> constantrep c
| Ast_c.FunCall (e,args) -> "TODO: FunCall"
| Ast_c.CondExpr (e1,e2,e3) -> "TODO: CondExpr"
| Ast_c.Sequence (e1,e2) -> "TODO: Sequence"
| Ast_c.Assignment (e1,op,e2) -> "TODO: Assignment"
| Ast_c.Postfix (e,op) -> "TODO: Postfix"
| Ast_c.Infix (e,op) -> "TODO: Infix"
| Ast_c.Unary (e,op) -> "TODO: Unary"
| Ast_c.Binary (e1,op,e2) -> "TODO: Binary"
| Ast_c.ArrayAccess (e1,e2) -> "TODO: ArrayAccess"
| Ast_c.RecordAccess (e1,s) -> "TODO: RecordAccess"
| Ast_c.RecordPtAccess (e,s) -> "TODO: RecordPtAccess"
| Ast_c.SizeOfExpr e -> "TODO: SizeOfExpr"
| Ast_c.SizeOfType t -> "TODO: SizeOfType"
| Ast_c.Cast (t,e) -> "TODO: Cast"
| Ast_c.StatementExpr c -> "TODO: StatementExpr"
| Ast_c.Constructor (t,i) -> "TODO: Constructor"
| Ast_c.ParenExpr e -> "TODO: ParenExpr"
and constantrep c = match c with
  Ast_c.String (s,isWchar) -> s 
| Ast_c.MultiString -> "TODO: MultiString"
| Ast_c.Char (s,isWchar) -> s
| Ast_c.Int s -> s 
| Ast_c.Float (s,t) -> s

let stringrep mvb = match mvb with
  Ast_c.MetaIdVal        s -> s
| Ast_c.MetaFuncVal      s -> s
| Ast_c.MetaLocalFuncVal s -> s
| Ast_c.MetaExprVal      ((expr,_),[il]) -> (exprrep expr)
| Ast_c.MetaExprVal	 e -> "TODO: <<MetaExprVal>>"
| Ast_c.MetaExprListVal  expr_list -> "TODO: <<exprlist>>"
| Ast_c.MetaTypeVal      typ -> "TODO: type"
| Ast_c.MetaStmtVal      statement -> "TODO: stmt"
| Ast_c.MetaParamVal     params -> "TODO: <<param>>"
| Ast_c.MetaParamListVal params -> "TODO: <<paramlist>>"
| Ast_c.MetaListlenVal n -> string_of_int n
| Ast_c.MetaPosVal (pos1, pos2) -> Common.sprintf ("pos(%d,%d)") pos1 pos2
| Ast_c.MetaPosValList positions -> "TODO: <<postvallist>>"
