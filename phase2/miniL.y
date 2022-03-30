%{
#include <stdio.h>
#include <stdlib.h>  
#include "miniL-parser.h"

extern int yylex();
void yyerror(const char *msg);
%}

%union{
  int ival;
  char *sval;
}

%error-verbose
%locations

%left     COMMA
%right    ASSIGN
%right    NOT
%left     LT LTE GT GTE EQ NEQ
%left     ADD SUB
%left     MULT DIV MOD
%right    UNARY_MINUS
%left     L_SQUARE_BRACKET R_SQUARE_BRACKET
%left     L_PAREN R_PAREN


%token  FUNCTION BEGIN_PARAMS END_PARAMS BEGIN_LOCALS END_LOCALS BEGIN_BODY 
        END_BODY INTEGER ARRAY OF IF THEN ENDIF ELSE WHILE DO BEGINLOOP ENDLOOP
        CONTINUE BREAK READ WRITE TRUE FALSE RETURN SEMICOLON COLON

%token  <sval> IDENT
%token  <ival> NUMBER

%start program

%% 

program:  functions { printf("program -> functions\n"); }
		    | error { yyerrok; yyclearin;}
		    ;

functions:  { printf("functions -> epsilon\n"); }
		      | function functions { printf("functions -> function functions\n"); }
		      ;

function:	FUNCTION ident SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY
		      { printf("function -> FUNCTION ident SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY\n"); }
		    ;

declarations: { printf("declarations -> epsilon\n"); }
	        	| declaration SEMICOLON declarations { printf("declarations -> declaration SEMICOLON declarations\n"); }
            | declaration error { yyerrok; yyclearin; }
		        ;

declaration:  identifiers COLON INTEGER { printf("declaration -> identifiers COLON INTEGER\n"); }
            | identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER { printf("declaration -> identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER %d R_SQUARE_BRACKET OF INTEGER\n", $5); }
            ;

identifiers:  ident { printf("identifiers -> ident\n"); }
	          | ident COMMA identifiers { printf("identifiers -> ident COMMA identifiers\n"); }
		        ;

ident:  IDENT { printf("ident -> IDENT %s\n", $1); }
		    ;

statements:   statement SEMICOLON statements 	{ printf("statements -> statement SEMICOLON statement\n"); }
            | statement SEMICOLON { printf("statements -> statement SEMICOLON\n"); }
            | statement error { yyerrok; yyclearin; }
            ;

statement:  var_stmts       { printf("statement -> var_stmts\n"); }
          | if_stmts        { printf("statement -> if_stmts\n"); }
          | while_stmts     { printf("statement -> while_stmts\n"); }
          | do_stmts        { printf("statement -> do_stmts\n"); }
          | read_stmts      { printf("statement -> read_stmts\n"); }
          | write_stmts     { printf("statement -> write_stmts\n"); }
          | continue_stmts  { printf("statement -> continue_stmts\n"); }
          | break_stmts     { printf("statement -> break_stmts\n"); }
          | return_stmts    { printf("statement -> return_stmts\n"); }
          ;

var_stmts:  var ASSIGN exp { printf("var_stmts -> var ASSIGN exp\n"); }
    ;

if_stmts: IF bool_exp THEN statements ENDIF { printf("if_stmts -> IF bool_exp THEN statements ENDIF\n"); }
        | IF bool_exp THEN statements ELSE statements ENDIF { printf("if_stmts -> IF bool_exp THEN statements ELSE statements ENDIF\n"); }
        ;

while_stmts: WHILE bool_exp BEGINLOOP statements ENDLOOP { printf("while_stmts -> WHILE bool_exp BEGINLOOP statements ENDLOOP\n"); }
          ;

do_stmts: DO BEGINLOOP statements ENDLOOP WHILE bool_exp { printf("do_stmts -> Do BEGINLOOP statements ENDLOOP WHILE bool_exp\n"); }
    ;

read_stmts: READ var { printf("read_stmts -> READ var\n"); }
    ;

write_stmts: WRITE var { printf("write_stmts -> WRITE var\n"); }
		;

continue_stmts: CONTINUE { printf("continue_stmts -> CONTINUE\n"); }
    ;

break_stmts: BREAK { printf("break_stmts -> BREAK\n"); }
    ;

return_stmts: RETURN exp { printf("return_stmts -> RETURN exp\n"); }
    ;

bool_exp:   NOT bool_EXP { printf("bool_exp -> NOT  bool_EXP\n"); }
          | bool_EXP { printf("bool_exp -> bool_EXP\n"); }
          ;

bool_EXP:  exp comp exp { printf("bool_EXP -> exp comp exp\n"); }
         | TRUE { printf("bool_EXP -> TRUE\n"); }
         | FALSE { printf("bool_EXP -> FALSE\n"); }
         | L_PAREN bool_exp R_PAREN { printf("bool_EXP ->L_PAREN bool_exp R_PAREN\n"); }
         ;

comp:     EQ    { printf("comp -> EQ\n"); }
        | NEQ   { printf("comp -> NEQ\n"); }
        | LT    { printf("comp -> LT\n"); }
        | GT    { printf("comp -> GT\n"); }
        | LTE   { printf("comp -> LTE\n"); }
        | GTE   { printf("comp -> GTE\n"); }
        ;
exps:   exp { printf("exps -> exp\n"); }
        /* exp COMMA { printf("exps -> exp COMMA\n"); } */
      | exp COMMA exps { printf("exps -> exp COMMA exps\n"); }
      ;

exp:  mult_exp { printf("exp -> mult_exp\n"); }
    | mult_exp ADD exp { printf("exp -> mult_exp ADD exp\n"); }
    | mult_exp SUB exp { printf("exp -> mult_exp SUB exp\n"); }
    ;

mult_exp:   term { printf("mult_exp -> term\n"); }
          | term MULT mult_exp { printf("mult_exp -> term MULT mult_exp\n"); }
          | term DIV mult_exp { printf("mult_exp -> term DIV mult_exp\n"); }
          | term MOD mult_exp { printf("mult_exp -> term MOD mult_exp\n"); }
          ;

term:   var  { printf("term -> var\n"); }
      | SUB NUMBER %prec UNARY_MINUS{ printf("term -> SUB NUMBER %d prec UNARY_MINUS\n", $2); }
      | NUMBER { printf("term -> NUMBER %d\n", $1); }
      | L_PAREN exp R_PAREN  { printf("term -> L_PAREN exp R_PAREN\n"); }
      | ident L_PAREN exps R_PAREN { printf("term -> ident L_PAREN exps R_PAREN\n"); }
      ;

vars: var { printf("vars -> var\n"); }
    | var COMMA vars { printf("vars -> var COMMA vars\n"); }

var:  ident { printf("var -> ident\n"); }
    | ident L_SQUARE_BRACKET exp R_SQUARE_BRACKET { printf("var -> ident L_SQUARE_BRACKET exp R_SQUARE_BRACKET\n"); }
    ;

%% 

int main(int argc, char **argv) {
  yyparse();
  return 0;
}

void yyerror(const char *msg) {
  extern int line_num, column_num; // defined and maintained in lex.c

  printf("Syntax error on line %d, column %d: %s\n", line_num, column_num, msg);
  exit(1);
}