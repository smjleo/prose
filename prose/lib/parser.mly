%token <float> PROB
%token <string> IDENT
%token COLON
%token END
%token MU
%token DOT
%token COMMA
%token OPLUS
%token AND
%token LBRACE
%token RBRACE
%token LPAREN
%token RPAREN
%token BANG
%token QUESTION
%token PLUS
%token LANGLE
%token RANGLE
%token INT
%token STR
%token BOOL
%token EOF

%{ open Ast %}
%start <context> context
%%

context:
| ctx = context_item* EOF   { ctx }

context_item:
| ctx_part = IDENT COLON ctx_type = session_type     { { ctx_part; ctx_type } }

session_type:
| END                                                { End }
| MU var = IDENT DOT cont = session_type             { Mu (var, cont) }
| var = IDENT                                        { Variable var }
| internal_type                                      { $1 }
| AND ext_choices = ext_choices                      { External ext_choices }

(* Internal choice with nondeterminism: (+) {...} + (+) {...} *)
(* Using left recursion to avoid shift/reduce conflicts *)
internal_type:
| branches = internal_branches    { Internal (List.rev branches) }

internal_branches:
| branch = internal_branch                              { [branch] }
| rest = internal_branches PLUS branch = internal_branch { branch :: rest }

internal_branch:
| OPLUS LBRACE choices = separated_list(COMMA, int_choice) RBRACE    { choices }

(* p ! prob : label<sort> . continuation *)
int_choice:
| ch_part = IDENT BANG prob = PROB COLON ch_label = IDENT DOT ch_cont = session_type
    { (prob, { ch_part; ch_label; ch_sort = Unit; ch_cont }) }
| ch_part = IDENT BANG prob = PROB COLON ch_label = IDENT LANGLE ch_sort = sort RANGLE DOT ch_cont = session_type
    { (prob, { ch_part; ch_label; ch_sort; ch_cont }) }

(* External choices *)
ext_choices:
| LBRACE choices = separated_list(COMMA, ext_choice) RBRACE    { choices }

(* p ? label(sort) . continuation *)
ext_choice:
| ch_part = IDENT QUESTION ch_label = IDENT DOT ch_cont = session_type
    { { ch_part; ch_label; ch_sort = Unit; ch_cont } }
| ch_part = IDENT QUESTION ch_label = IDENT LPAREN ch_sort = sort RPAREN DOT ch_cont = session_type
    { { ch_part; ch_label; ch_sort; ch_cont } }

sort:
| INT     { Int }
| STR     { Str }
| BOOL    { Bool }
