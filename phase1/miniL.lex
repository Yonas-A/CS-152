/* cs152-miniL phase1 */
   
%{   
/* c code for variables and including headers definition*/

  #include <stdlib.h> /* exit, EXIT_FAILURE */
  int line_num = 1, column_num = 0;
%}

/* some common rules */

digit           [0-9]
alpha           [a-zA-Z]
alnum           [a-zA-Z0-9]
alnumUndrs      [a-zA-Z0-9_]
alUndrs         [a-zA-Z_]


IDENT           {alpha}({alnum}*[_]*{alnum})*{alnum}*

  /* ---------- rules for errors ---------- */

error1a         _{alnumUndrs}+ 
  /* indentifier starting with a digit with underscore*/

error1b         {digit}+{alUndrs}+{digit}* 
  /* indentifier starting with a digit with underscore*/

error2          {alnum}+_    
  /* indentifier ending with underscore */

%%

  /* ---------- Reserved Words ---------- */

"function"      {printf("FUNCTION\n"); column_num += yyleng;} 
"beginparams"   {printf("BEGIN_PARAMS\n"); column_num += yyleng; }
"endparams"     {printf("END_PARAMS\n"); column_num += yyleng; }
"beginlocals"   {printf("BEGIN_LOCALS\n"); column_num += yyleng; }
"endlocals"     {printf("END_LOCALS\n"); column_num += yyleng; }
"beginbody"     {printf("BEGIN_BODY\n"); column_num += yyleng; }
"endbody"       {printf("END_BODY\n"); column_num += yyleng; }
"integer"       {printf("INTEGER\n"); column_num += yyleng; }
"array"         {printf("ARRAY\n"); column_num += yyleng; }
"of"            {printf("OF\n"); column_num += yyleng; }
"if"            {printf("IF\n"); column_num += yyleng; }
"then"          {printf("THEN\n"); column_num += yyleng; }
"endif"         {printf("ENDIF\n"); column_num += yyleng; }
"else"          {printf("ELSE\n"); column_num += yyleng; }
"while"         {printf("WHILE\n"); column_num += yyleng; }
"do"            {printf("DO\n"); column_num += yyleng; }
"beginloop"     {printf("BEGINLOOP\n"); column_num += yyleng; }
"endloop"       {printf("ENDLOOP\n"); column_num += yyleng; }
"continue"      {printf("CONTINUE\n"); column_num += yyleng; }
"break"         {printf("BREAK\n"); column_num += yyleng; }
"read"          {printf("READ\n"); column_num += yyleng; }
"write"         {printf("WRITE\n"); column_num += yyleng; }
"not"           {printf("NOT\n"); column_num += yyleng; }
"true"          {printf("TRUE\n"); column_num += yyleng; }
"false"         {printf("FALSE\n"); column_num += yyleng; }
"return"        {printf("RETURN\n"); column_num += yyleng; }

  /* ---------- Arithmetic Operators ---------- */

"-"             {printf("SUB\n"); column_num += yyleng; } 
"+"             {printf("ADD\n"); column_num += yyleng; }
"*"             {printf("MULT\n"); column_num += yyleng; }
"/"             {printf("DIV\n"); column_num += yyleng; }
"%"             {printf("MOD\n"); column_num += yyleng; }

  /* ---------- Comparison Operators ---------- */

"=="            {printf("EQ\n"); column_num += yyleng;} 
"<>"            {printf("NEQ\n"); column_num += yyleng;}
"<"             {printf("LT\n"); column_num += yyleng;}
">"             {printf("GT\n"); column_num += yyleng;}
"<="            {printf("LTE\n"); column_num += yyleng;}
">="            {printf("GTE\n"); column_num += yyleng;} 

  /* ---------- Identifiers and Numbers ---------- */

{IDENT}         {printf("IDENT %s\n", yytext); column_num += yyleng;} 

{digit}+        {printf("NUMBER %s\n", yytext); column_num += yyleng;}

  /* ---------- Other Special Symbolss ---------- */

;               {printf("SEMICOLON\n"); column_num += yyleng;} 
:               {printf("COLON\n"); column_num += yyleng;}
,               {printf("COMMA\n"); column_num += yyleng;}
\(              {printf("L_PAREN\n"); column_num += yyleng;}
\)              {printf("R_PAREN\n"); column_num += yyleng;}
\[              {printf("L_SQUARE_BRACKET\n"); column_num += yyleng;} 
\]              {printf("R_SQUARE_BRACKET\n"); column_num += yyleng;}
:=              {printf("ASSIGN\n"); column_num += yyleng;}


"##"[^\n]*      /* eat up one-line comments */

[ \t]+          column_num += yyleng;
\n              ++line_num; column_num = 0;


  /* ---------- Lexical errors ---------- */



{error1a} | 
{error1b}       {printf("Error at line %d, column %d: identifier \"%s\" must begin with a letter\n", line_num, column_num, yytext); exit(EXIT_FAILURE);}

{error2}        {printf("Error at line %d, column %d: identifier \"%s\" cannot end with an underscore\n", line_num, column_num, yytext); exit(EXIT_FAILURE);}

.               {printf("Error at line %d, column %d: unrecognized symbol \"%s\"\n", line_num, column_num, yytext); exit(EXIT_FAILURE);}
%%              

/* C functions used in lexer */

int main(int argc, char ** argv)
{
  yylex();
}
