%{
#include "lib.h"
#include "miniL-parser.hpp"

using namespace std;

int yylex();
void yyerror(const char *msg);

std::string generateVar();
std::string generateLabel();

bool containsFunction(std::string str);
bool containsVariable(std::string str);

// int used as index if variable is array
std::map<std::string, int> variableTable; 
std::vector<std::string> functionTable;
%}


%union{
  char* sval;
  int ival;
  
  struct {
    char* name;
    char* code;
    bool is_array;
  } node;
}

%error-verbose

%type <node> ident function_name  declarations declaration identifiers vars var 
             statements statement ElseStatement var_stmts if_stmts while_stmts
             do_stmts read_stmts write_stmts continue_stmts break_stmts 
             return_stmts exps exp mult_exp term bool_exp bool_EXP comp

%left     COMMA
%right    ASSIGN
%right    NOT
%left     LT LTE GT GTE EQ NEQ
%left     ADD SUB
%left     MULT DIV MOD
%left     L_SQUARE_BRACKET R_SQUARE_BRACKET
%left     L_PAREN R_PAREN


%token  FUNCTION BEGIN_PARAMS END_PARAMS BEGIN_LOCALS END_LOCALS BEGIN_BODY 
        END_BODY INTEGER ARRAY OF IF THEN ENDIF ELSE WHILE DO BEGINLOOP ENDLOOP
        CONTINUE BREAK READ WRITE TRUE FALSE RETURN SEMICOLON COLON

%token <sval> IDENT
%token <ival> NUMBER

%start program

%%

program: functions {
};

functions:  %empty { 
  if (containsFunction("main") == false)
    yyerror("\"main\" function not declared");
}
| function functions { 
}
;

function:	FUNCTION function_name SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY {

  std::string init_params = $5.code;
  int param_number = 0;
  while (init_params.find(".") != std::string::npos) {
    size_t pos = init_params.find(".");
    init_params.replace(pos, 1, "=");
    std::string param = ", $" + std::to_string(param_number++) + "\n";
    init_params.replace(init_params.find("\n", pos), 1, param);
  }

  std::string statements($11.code);
  if (statements.find("continue") != std::string::npos) {
    yyerror("continue statement not within a loop");
  }
  stringstream ss;
  ss << "func " << $2.name << "\n" << $2.code << $5.code << init_params 
     << $8.code << statements << "endfunc\n";

  variableTable.clear();
  std::string temp = ss.str();
  printf("%s", temp.c_str());
};

declarations:  %empty { 
  $$.name = strdup("");
  $$.code = strdup("");
}
| declaration SEMICOLON declarations {
  std::string temp = std::string($1.code) + std::string($3.code);
  $$.code = strdup(temp.c_str());
  $$.name = strdup("");
}
;

declaration:  identifiers COLON INTEGER {
  stringstream ss;
  std::string vars($1.name);
  std::string variable;
  bool cont = true;

  size_t oldpos = 0;
  size_t pos = 0;
  while (cont) {
    pos = vars.find("|", oldpos);
    if (pos == std::string::npos) {
      variable = vars.substr(oldpos,pos);
      ss << ". " << variable << "\n";
      cont = false;
    } else {
      size_t len = pos - oldpos;
      variable = vars.substr(oldpos, len);
      ss << ". " << variable << "\n";
    }
    if( containsVariable(variable) == true ) {
      std::string t = "symbol \"" + variable + "\" is multiply-defined.";
      yyerror(t.c_str());
    } else {
      variableTable.insert(std::pair<std::string,int>(variable,0));
    }
    oldpos = pos + 1;
  }
  std::string temp = ss.str();
  $$.code = strdup(temp.c_str());
  $$.name = strdup("");  
}
| identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER {
  if ($5 <= 0) {
    yyerror("Array size can't be less than 1");
  }
  stringstream ss;
  std::string vars($1.name);
  std::string variable;
  bool cont = true;

  size_t oldpos = 0;
  size_t pos = 0;
  while (cont) {
    pos = vars.find("|", oldpos);
    if (pos == std::string::npos) {
      variable = vars.substr(oldpos, pos);
      ss << ".[] " << variable << ", " << $5 << "\n";
      cont = false;
    } else {
      size_t len = pos - oldpos;
      variable = vars.substr(oldpos, len);
      ss << ".[] " << variable << ", " << $5 << "\n";
    }
    if( containsVariable(variable) == true ) {
      std::string t = "symbol \"" + variable + "\" is multiply-defined.";
      yyerror(t.c_str());
    } else {
      variableTable.insert(std::pair<std::string,int>(variable,$5));
    }
    oldpos = pos + 1;
  }
  
  std::string temp = ss.str();
  $$.code = strdup(temp.c_str());
  $$.name = strdup("");	   
}
;

identifiers:  ident {
  $$.name = strdup($1.name);
  $$.code = strdup("");  
}
| ident COMMA identifiers { 
  std::string temp = std::string($1.name) + "|" + std::string($3.name);
  $$.name = strdup(temp.c_str());
  $$.code = strdup("");  
}
;

ident:  IDENT {
  $$.name = strdup($1);
  $$.code = strdup("");
};

statements: statement SEMICOLON statements 	{
  std::string temp = std::string($1.code) + std::string($3.code);
  $$.code = strdup(temp.c_str());
}
| statement SEMICOLON {
  std::string temp = std::string($1.code);
  $$.code = strdup(temp.c_str());
}
;

statement:  var_stmts {
}
| if_stmts {
}
| while_stmts {
}
| do_stmts {
}
| read_stmts {
}
| write_stmts { 
}
| continue_stmts  { 
}
| break_stmts { 
}
| return_stmts  { 
}
;

var_stmts:  var ASSIGN exp { 
  stringstream ss;
  ss << $1.code << $3.code ;
  std::string temp = $3.name;
  if ($1.is_array) {
    ss << "[]= ";
  } else if ($3.is_array) {
    ss << "=[] ";
  } else {
    ss << "= ";
  }
  ss << $1.name << ", " << temp << "\n";
  temp = ss.str();
  $$.code = strdup(temp.c_str());
};

if_stmts: IF bool_exp THEN statements ElseStatement ENDIF {
  stringstream ss;
  std::string label = generateLabel();
  std::string predicate = generateLabel();

  ss << $2.code << "?:= " << label << ", " << $2.name << "\n"
     << $5.code << ":= " << predicate << "\n" << ": " << label 
     << "\n" << $4.code << ": " << predicate << "\n";
  std::string temp = ss.str();
  $$.code = strdup(temp.c_str());
};

ElseStatement:   %empty {
  $$.code = strdup("");
}
| ELSE statements {
  $$.code = strdup($2.code);
};

while_stmts: WHILE bool_exp BEGINLOOP statements ENDLOOP {
  std::string beginWhile = generateLabel();
  std::string beginLoop = generateLabel();
  std::string endLoop = generateLabel();
  std::string statement = $4.code;
  std::string jump = ":= " + beginWhile;

  while (statement.find("continue") != std::string::npos) {
    statement.replace(statement.find("continue"), 8, jump);
  }
  while (statement.find("break") != std::string::npos) {
    statement.replace(statement.find("break"), 5, ":= " + endLoop);
  }
  stringstream ss;
  ss << ": " << beginWhile << "\n" << $2.code << "?:= " << beginLoop 
     << ", " << $2.name << "\n" << ":= " << endLoop << "\n" << ": " 
     << beginLoop << "\n" << statement << ":= " << beginWhile << "\n" 
     << ": " << endLoop << "\n";

  std::string temp = ss.str();
  $$.code = strdup(temp.c_str());  
};

do_stmts: DO BEGINLOOP statements ENDLOOP WHILE bool_exp {
  std::string beginLoop = generateLabel();
  std::string beginWhile = generateLabel();
  std::string breakLoop = generateLabel();
  std::string statement = $3.code;
  std::string jump = ":= " + beginWhile ;

  while (statement.find("continue") != std::string::npos) {
    statement.replace(statement.find("continue"), 8, jump);
  }
  while (statement.find("break") != std::string::npos) {
    statement.replace(statement.find("break"), 5, ":= " + breakLoop);
  }
  stringstream ss;
  ss << ": " << beginLoop << "\n" << statement << ": " << beginWhile << "\n" 
     << $6.code << "?:= " << beginLoop << ", " << $6.name << "\n";

  std::string temp = ss.str();
  $$.code = strdup(temp.c_str());  
};

read_stmts: READ vars { 
  std::string temp = $2.code;
  size_t pos = 0;
  do {
    pos = temp.find("|", pos);
    if (pos == std::string::npos)
      break;
    temp.replace(pos, 1, "<");
  } while (true);

  $$.code = strdup(temp.c_str());  
};

write_stmts: WRITE vars {
  std::string temp = $2.code;
  size_t pos = 0;
  do {
    pos = temp.find("|", pos);
    if (pos == std::string::npos)
      break;
    temp.replace(pos, 1, ">");
  } while (true);

  $$.code = strdup(temp.c_str());  
};

continue_stmts: CONTINUE {
  $$.code = strdup("continue\n");  
};

break_stmts: BREAK {
  $$.code = strdup("break\n");  
};

return_stmts: RETURN exp {
  stringstream ss;
  ss << $2.code << "ret " << $2.name << "\n";
  std::string temp = ss.str();
  $$.code = strdup(temp.c_str());
};

bool_exp: NOT bool_EXP {
  stringstream ss;
  std::string dest = generateVar();
  ss << $2.code << ". " << dest << "\n" << "! " << dest << ", " << $2.name << "\n" ;
  std::string temp = ss.str();
  $$.code = strdup(temp.c_str());
  $$.name = strdup(dest.c_str());
} 
| bool_EXP {
  $$.name = strdup($1.name);
  $$.code = strdup($1.code);
}
;

bool_EXP: exp comp exp { 
  stringstream ss;
  std::string dest = generateVar();
  ss << $1.code << $3.code << ". " << dest << "\n" 
     << $2.name << dest << ", " << $1.name << ", " << $3.name <<  "\n";
  std::string temp = ss.str();     
  $$.code = strdup(temp.c_str());
  $$.name = strdup(dest.c_str());  
}
| TRUE {
  $$.name = strdup("1");
  $$.code = strdup("");
}
| FALSE {
  $$.name = strdup("0");
  $$.code = strdup("");
}
| L_PAREN bool_exp R_PAREN {
  $$.name = strdup($2.name);
  $$.code = strdup($2.code);
}
;

comp: EQ {
  std::string temp = "== ";
  $$.name = strdup(temp.c_str());
  $$.code = strdup("");
}
| NEQ {
  std::string temp = "!= ";
  $$.name = strdup(temp.c_str());
  $$.code = strdup("");
}
| LT {
  std::string temp = "< ";
  $$.name = strdup(temp.c_str());
  $$.code = strdup("");
}
| GT {
  std::string temp = "> ";
  $$.name = strdup(temp.c_str());
  $$.code = strdup("");
}
| LTE {
  std::string temp = "<= ";
  $$.name = strdup(temp.c_str());
  $$.code = strdup("");
}
| GTE {
  std::string temp = ">= ";
  $$.name = strdup(temp.c_str());
  $$.code = strdup("");
}
;

exps:  %empty {
  $$.code = strdup("");
  $$.name = strdup("");
}
| exp COMMA exps  {
  stringstream ss;
  ss << $1.code << "param " << $1.name << "\n" << $3.code;
  std::string temp = ss.str();     
  $$.code = strdup(temp.c_str());
  $$.name = strdup("");  
}
| exp {
  stringstream ss;
  ss << $1.code << "param " << $1.name << "\n";
  std::string temp = ss.str();    
  $$.code = strdup(temp.c_str());
  $$.name = strdup("");
}
;

exp: mult_exp {
  $$.code = strdup($1.code);
  $$.name = strdup($1.name);
}
| mult_exp ADD exp {
  stringstream ss;
  $$.name = strdup(generateVar().c_str());
  ss << $1.code << $3.code << ". " << $$.name << "\n" 
     << "+ " << $$.name << ", " << $1.name << ", " << $3.name << "\n" ;
  std::string temp = ss.str();
  $$.code = strdup(temp.c_str());
}
| mult_exp SUB exp {
  stringstream ss;
  $$.name = strdup(generateVar().c_str());
  ss << $1.code << $3.code << ". " << $$.name << "\n" 
     << "- " << $$.name << ", " << $1.name << ", " << $3.name << "\n" ;
  std::string temp = ss.str();
  $$.code = strdup(temp.c_str());  
}
;

mult_exp: term {
  $$.code = strdup($1.code);
  $$.name = strdup($1.name);  
}
| term MULT mult_exp {
  stringstream ss;
  $$.name = strdup(generateVar().c_str());
  ss << ". " << $$.name << "\n" << $1.code << $3.code << "* " 
     << $$.name << ", " << $1.name << ", " << $3.name << "\n" ;
  std::string temp = ss.str();  
  $$.code = strdup(temp.c_str());  
}
| term DIV mult_exp {
  stringstream ss;
  $$.name = strdup(generateVar().c_str());
  ss << ". " << $$.name << "\n" << $1.code << $3.code << "/ " 
     << $$.name << ", " << $1.name << ", " << $3.name << "\n" ;
  std::string temp = ss.str();
  $$.code = strdup(temp.c_str());  
}
| term MOD mult_exp {
  stringstream ss;
  $$.name = strdup(generateVar().c_str());
  ss << ". " << $$.name << "\n" << $1.code << $3.code << "% " 
     << $$.name << ", " << $1.name << ", " << $3.name << "\n" ;
  std::string temp = ss.str();
  $$.code = strdup(temp.c_str());  
}
;

term: var {
  if ($$.is_array == true) {
    stringstream ss;
    std::string src = generateVar();
    ss << $1.code << ". " << src << "\n"  << "=[] " << src 
       << ", " << $1.name << "\n";
    std::string temp = ss.str();
    
    $$.code = strdup(temp.c_str());
    $$.name = strdup(src.c_str());
    $$.is_array = false;
  }
  else {
    $$.code = strdup($1.code);
    $$.name = strdup($1.name);
  }
}
| SUB var {
  stringstream ss;
  $$.name = strdup(generateVar().c_str());
  ss << $2.code << ". " << $$.name << "\n" ;

  if ($2.is_array) 
    ss << "=[] " << $$.name << ", " << $2.name << "\n" ;
  else 
    ss << "= " << $$.name << ", " << $2.name << "\n" ;

  ss << "* " << $$.name << ", " << $$.name << ", -1" << "\n";
  std::string temp = ss.str();
  $$.code = strdup(temp.c_str());
  $$.is_array = false;
}
| NUMBER {
  $$.code = strdup("");
  $$.name = strdup(std::to_string($1).c_str());  
}
| SUB NUMBER {
  std::string temp = "-" + std::to_string($2);
  $$.code = strdup("");
  $$.name = strdup(temp.c_str());  
}
| L_PAREN exp R_PAREN  {
  $$.code = strdup($2.code);
  $$.name = strdup($2.name);
}
| SUB L_PAREN exp R_PAREN {
  stringstream ss;
  $$.name = strdup($3.name);
  ss << $3.code << "* " << $3.name << ", " <<  $3.name << ", -1" << "\n" ;
  std::string temp = ss.str();
  $$.code = strdup(temp.c_str());
}
| ident L_PAREN exps R_PAREN {
  if (containsFunction(std::string($1.name)) == false) {
    stringstream ss;
    ss << "used function \"" << $1.name << "\" was not previously declared.";
    std::string temp = ss.str();
    yyerror(temp.c_str());    
  } 
  stringstream ss;
  $$.name = strdup(generateVar().c_str());
  ss << $3.code << ". " << $$.name << "\n" << "call " << $1.name 
     << ", " << $$.name << "\n" ;
  std::string temp = ss.str();
  $$.code = strdup(temp.c_str());  
}
;

vars: var {
  stringstream ss;
  std::string temp = ($1.is_array) ? ".[]| " : ".| ";
  ss << $1.code << temp << $1.name << "\n";
  temp = ss.str();

  $$.code = strdup(temp.c_str());
  $$.name = strdup("");
}
| var COMMA vars {
  stringstream ss;
  std::string temp = ($1.is_array) ? ".[]| " : ".| ";
  ss << $1.code << temp << $1.name << "\n" << $3.code;
  temp = ss.str();
  
  $$.code = strdup(temp.c_str());
  $$.name = strdup("");
}
;

var:  ident L_SQUARE_BRACKET exp R_SQUARE_BRACKET {
  if( containsVariable(std::string($1.name)) == false ) {
    stringstream ss;
    ss << "used variable \"" << $1.name << "\" was not previously declared.";
    std::string temp = ss.str();
    yyerror(temp.c_str());   
  }
  else if (variableTable.find(std::string($1.name))->second == 0) {
    stringstream ss;
    ss << "used variable \"" << $1.name << "\" is not an array";
    std::string temp = ss.str();
    yyerror(temp.c_str());                  
  }

  stringstream ss;
  ss << $1.name << ", " << $3.name;
  std::string temp = ss.str();

  $$.code = strdup($3.code);
  $$.name = strdup(temp.c_str());
  $$.is_array = true;
}
| ident {
  if( containsVariable(std::string($1.name)) == false ) {
    stringstream ss;
    ss << "used variable \"" << $1.name << "\" was not previously declared.";
    std::string temp = ss.str();
    yyerror(temp.c_str());   
  }
  else if (variableTable.find(std::string($1.name))->second > 0) {
    stringstream ss;
    ss << "used array variable \"" << $1.name << "\" is missing a specified index.";
    std::string temp = ss.str();
    yyerror(temp.c_str()); 
  }

  $$.code = strdup("");
  $$.name = strdup($1.name);
  $$.is_array = false;
}
;

function_name: IDENT {
  if (containsFunction(std::string($1)) == true) {
    stringstream ss;
    ss << "function \"" << $1 << "\" is multiply-defined";
    std::string temp = ss.str();
    yyerror(temp.c_str());   
  }
  else {
    functionTable.push_back(std::string($1));
  }
  $$.name = strdup($1);
  $$.code = strdup("");
};

%%

void yyerror(const char *msg) {
  extern int line_num, column_num; // defined and maintained in lex.c
  printf("Syntax error on line %d, column %d: %s\n", line_num, column_num, msg);
};

std::string generateVar() {
  static int num = 0;
  return "temp__" + std::to_string(num++);
}

std::string generateLabel() {
  static int num = 0;
  return "label__" + std::to_string(num++);
}

// returns true if functionTable contains variable
bool containsFunction(std::string str) {
  return std::find(functionTable.begin(), functionTable.end(), str) != functionTable.end();
}

// returns true if variable table contains variable
bool containsVariable(std::string str) {
  return variableTable.find(str) != variableTable.end();
}