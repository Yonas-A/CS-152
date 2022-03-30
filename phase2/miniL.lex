%{
#include <stdlib.h>
#include "miniL-parser.h"
int line_num = 1, column_num = 1;
%}

/* common rules */

digit           [0-9]
alpha           [a-zA-Z]
alnum           [a-zA-Z0-9]
alnumUndrs      [a-zA-Z0-9_]
alUndrs         [a-zA-Z_]


IDENT           {alpha}({alnum}*[_]*{alnum})*{alnum}*

  /* ---------- rules for errors ---------- */

error1a         _{alnumUndrs}+
  /* Identifier starting with an underscore */
error1b         {digit}+{alUndrs}+{digit}*
  /* Identifier starting with a digit */
error2          {alnum}+_
  /* Identifier ending with underscore */

%%

  /* ---------- Reserved Words ---------- */

"function"      { column_num += yyleng; return FUNCTION; } 
"beginparams"   { column_num += yyleng; return BEGIN_PARAMS; }
"endparams"     { column_num += yyleng; return END_PARAMS; }
"beginlocals"   { column_num += yyleng; return BEGIN_LOCALS; }
"endlocals"     { column_num += yyleng; return END_LOCALS; }
"beginbody"     { column_num += yyleng; return BEGIN_BODY; }
"endbody"       { column_num += yyleng; return END_BODY; }
"integer"       { column_num += yyleng; return INTEGER; }
"array"         { column_num += yyleng; return ARRAY; }
"of"            { column_num += yyleng; return OF; }
"if"            { column_num += yyleng; return IF; }
"then"          { column_num += yyleng; return THEN; }
"endif"         { column_num += yyleng; return ENDIF; }
"else"          { column_num += yyleng; return ELSE; }
"while"         { column_num += yyleng; return WHILE; }
"do"            { column_num += yyleng; return DO; }
"beginloop"     { column_num += yyleng; return BEGINLOOP; }
"endloop"       { column_num += yyleng; return ENDLOOP; }
"continue"      { column_num += yyleng; return CONTINUE; }
"break"         { column_num += yyleng; return BREAK; }
"read"          { column_num += yyleng; return READ; }
"write"         { column_num += yyleng; return WRITE; }
"not"           { column_num += yyleng; return NOT; }
"true"          { column_num += yyleng; return TRUE; }
"false"         { column_num += yyleng; return FALSE; }
"return"        { column_num += yyleng; return RETURN; }

"-"             { column_num += yyleng; return SUB; } 
"+"             { column_num += yyleng; return ADD; }
"*"             { column_num += yyleng; return MULT; }
"/"             { column_num += yyleng; return DIV; }
"%"             { column_num += yyleng; return MOD; }

"=="            { column_num += yyleng; return EQ; } 
"<>"            { column_num += yyleng; return NEQ; }
"<"             { column_num += yyleng; return LT; }
">"             { column_num += yyleng; return GT; }
"<="            { column_num += yyleng; return LTE; }
">="            { column_num += yyleng; return GTE; } 

{digit}+        { column_num += yyleng; yylval.ival = atoi(yytext); return NUMBER;}
{IDENT}         { column_num += yyleng; yylval.sval = strdup(yytext); return IDENT; } 

";"             { column_num += yyleng; return SEMICOLON; } 
":"             { column_num += yyleng; return COLON; }
","             { column_num += yyleng; return COMMA; }
"("             { column_num += yyleng; return L_PAREN; }
")"             { column_num += yyleng; return R_PAREN; }
"["             { column_num += yyleng; return L_SQUARE_BRACKET; } 
"]"             { column_num += yyleng; return R_SQUARE_BRACKET; }
":="            { column_num += yyleng; return ASSIGN; }

[ \t]+          { column_num += yyleng; }
"##"[^\n]*      { } /* single line comments */
[\n]            { ++line_num; column_num = 1; }

{error1a} | 
{error1b}       {printf("Error at line %d, column %d: identifier \"%s\" must begin with a letter\n", line_num, column_num, yytext); exit(1);}

{error2}        {printf("Error at line %d, column %d: identifier \"%s\" cannot end with an underscore\n", line_num, column_num, yytext); exit(1);}

.               {printf("Error at line %d, column %d: unrecognized symbol \"%s\"\n", line_num, column_num, yytext); exit(1);}

%%
