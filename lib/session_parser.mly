%token <int> INT
%token <float> PROB
%token <string> IDENT
%token ARROW
%token SEND
%token RECV
%token PLUS
%token DOT
%token LPAREN
%token RPAREN
%token LBRACE
%token RBRACE
%token IMPLIES
%token PIPE
%token NIL
%token IF
%token THEN
%token ELSE
%token MU
%token FLIP
%token HEAD
%token TAIL
%token TRUE
%token FALSE
%token OR
%token NEG
%token SUCC
%token LT
%token NONDET
%token EOF

%{ open Ast %}

%right NONDET
%left OR
%left PLUS  
%left LT
%right NEG SUCC

%start <session> session
%%

session:
| items = session_item* EOF   { items }

session_item:
| sess_part = IDENT ARROW sess_process = process
  { { sess_part; sess_process } }

process:
| NIL                                                    { Nil }
| MU var = IDENT DOT cont = process                      { Mu (var, cont) }
| var = IDENT                                            { Proc_var var }
| send_part = IDENT SEND send_label = IDENT LPAREN send_expr = expr RPAREN DOT send_cont = process
  { Send { send_part; send_label; send_expr; send_cont } }
| recv_list = recv_choices                               { Receive recv_list }
| IF expr = expr THEN then_proc = process ELSE else_proc = process
  { If_then_else (expr, then_proc, else_proc) }
| FLIP LPAREN prob = PROB RPAREN LBRACE HEAD IMPLIES head_proc = process PIPE TAIL IMPLIES tail_proc = process RBRACE
  { Flip (prob, head_proc, tail_proc) }
| LPAREN p = process RPAREN                              { p }

recv_choices:
| recv = recv_choice                                     { [recv] }
| LBRACE recv_choice_list = separated_list(PLUS, recv_choice) RBRACE
  { recv_choice_list }

recv_choice:
| recv_part = IDENT RECV recv_label = IDENT LPAREN recv_var = IDENT RPAREN DOT recv_cont = process
  { { recv_part; recv_label; recv_var; recv_cont } }

expr:
| TRUE                                                   { True }
| FALSE                                                  { False }
| n = INT                                                { Int n }
| var = IDENT                                            { Expr_var var }
| e1 = expr OR e2 = expr                                 { Or (e1, e2) }
| NEG e = expr                                           { Neg e }
| e1 = expr PLUS e2 = expr                               { Add (e1, e2) }
| SUCC e = expr                                          { Succ e }
| e1 = expr LT e2 = expr                                 { Less_than (e1, e2) }
| e1 = expr NONDET e2 = expr                             { Nondeterminism (e1, e2) }
| LPAREN e = expr RPAREN                                 { e }
