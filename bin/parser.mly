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
| MU var = IDENT DOT cont = session_type             { Mu (var, cont)}
| var = IDENT                                        { Variable var }
| int_part = IDENT OPLUS int_choices = int_choices   { Internal { int_part; int_choices } }
| ext_part = IDENT AND ext_choices = ext_choices     { External { ext_part; ext_choices } }

int_choices:
| LBRACE choices = separated_list(COMMA, int_choice) RBRACE    { choices }
| choice = choice                                              { [(1.0, choice)] }

int_choice:
| prob = PROB COLON choice = choice                            { (prob, choice) }

ext_choices:
| LBRACE choices = separated_list(COMMA, choice) RBRACE        { choices }
| choice = choice                                              { [choice] }

choice:
| ch_label = IDENT DOT ch_cont = session_type    { { ch_label; ch_sort = Unit; ch_cont } }
| ch_label = IDENT LPAREN ch_sort = sort RPAREN DOT ch_cont = session_type
  { { ch_label; ch_sort; ch_cont } }

sort:
| INT     { Int }
| STR     { Str }
| BOOL    { Bool }
