%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symboltable.h"

extern int lineCount;
extern char lastsentence[3000];
extern char* yytext;

SymbolEntry ST[MAX_ST_SIZE];
int curST_size=0;
int var_offset=0;
int cur_scope=0;
%}
%start program

%union {
  int intval;
  double doubleval;
  char* textval;
}

%token <textval> ID TYPE CHAR_TYPE
%token <doubleval> DOU
%token <textval> TF CHA STR NUL
%token <intval> IN
%token ENDLINE
%token <textval> CONS VOI
%token <textval> LOR LAND LNOT COMP DP DM
%token <textval> FOR
%token <textval> IF ELSE
%token <textval> DO WHILE
%token <textval> BREAK CONTINUE RETURN
%token <textval> SWITCH CASE DEFAULT
%token <textval> DIGWRITE DELAY HIGH LOW


%left LOR
%left LAND
%nonassoc '!'
%left COMP
%left '+' '-'
%left '*' '/' '%'
%nonassoc unary
%left DP DM
%left '[' ']'

%type <doubleval> expression INT_DOUBLE_ID NUM UNUM init_expression

%%
program: global program
       |
       ;


global: declaration ';'
      | const_declaration ';'
      | function_use '{' local_S '}'
      ;

local_S: local_S local
       | local
       ;

local: declaration ';'
     | const_declaration ';'
     | normal_use ';'
     | digwrite ';'
     | delay ';'
     | RETURN expression ';'
     ;

///////////////for hw3/////////////////
digwrite: DIGWRITE '(' IN ',' high_low ')'
        ;
delay: DELAY '(' INT_DOUBLE_ID ')'
     ;

high_low: HIGH
        | LOW
        ;

//////////use//////////////////////
function_use: TYPE ID '(' para ')' {cur_scope++;}
            | VOI ID '(' para ')' {cur_scope--;}
            ;

normal_use: ID '=' expression 
          // | ID Arr_use '=' expression
          | expression {printf("ans = %f\n",$1);}
          ;

///////declaration///////////////////////

declaration: TYPE lots_of_ID_declaration
           | VOI lots_of_func_declare
           ;                    

lots_of_ID_declaration: ID_declaration ',' lots_of_ID_declaration
                      | ID_declaration
                      ;

ID_declaration: ID normal_init
              // | ID Arr_declare Arr_init
              | func_declar
              ;
///////////////////////const//////////////////////
const_declaration: CONS TYPE const_lots_of_ID_declaration
                 ;

const_lots_of_ID_declaration: const_ID_declaration ',' const_lots_of_ID_declaration
                            | const_ID_declaration
                            ;

const_ID_declaration: ID '=' NUM
                    ;                  

//////////////////////////function////////////////////

lots_of_func_declare: func_declar ',' lots_of_func_declare
                    | func_declar
                    ;

func_declar: ID '(' para ')'
           ;

para: para_style ',' para
    | para_style
    | 
    ;

para_style: TYPE ID
          // | TYPE ID Arr_declare
          ;

////////////////////////////////////
normal_init: '=' init_expression
           |
           ;

// Arr_use: '[' expression ']'
//        | Arr_use '[' expression ']'
//        ;

// Arr_declare: '[' IN ']'
//            | Arr_declare '[' IN ']'
//            ;

// Arr_init: '=' '{' no_or_more_expression '}'
//         | 
//         ;  
///////////////Value select//////////////   
NUM: IN 
   | DOU 
   | TF
   | CHA
   | STR
   | NUL
   ;

INT_DOUBLE_ID: IN
          | DOU
          | ID
          ;

UNUM: '-' INT_DOUBLE_ID %prec unary { $$ = -$2; }
    | '+' INT_DOUBLE_ID %prec unary { $$ = $2; }
    | NUM {$$=$1;}
    ;
// int_char: IN
//         | CHA
//         ;

///////////////expression////////////////
// no_or_more_expression: lots_of_expression
//                      |
//                      ;
// lots_of_expression: expression ',' lots_of_expression
//                   | expression
//                   ;  

expression: expression '+' expression 
          | expression '-' expression { $$=$1 - $3; }
          | expression '*' expression { $$=$1 * $3; }
          | expression '/' expression { $$=$1 / $3; }
          | expression '%' expression 
          | ID DP 
          | ID DM
          | expression COMP expression
          | expression LOR expression 
          | expression LAND expression 
          | '(' expression ')' { $$=$2; }
          | ID
          | UNUM
          | '!' expression 
          // | ID Arr_use
          // | func_invocation
          ;

init_expression: init_expression '+' init_expression { $$=$1 + $3; }
          | init_expression '-' init_expression { $$=$1 - $3; }
          | init_expression '*' init_expression { $$=$1 * $3; }
          | init_expression '/' init_expression { $$=$1 / $3; }
          | init_expression '%' init_expression
          | ID DP
          | ID DM
          | init_expression COMP init_expression
          | init_expression LOR init_expression
          | init_expression LAND init_expression
          | '(' init_expression ')' {$$=$2;}
          | ID
          | UNUM {$$=$1;}
          | '!' init_expression
          // | ID Arr_use
          ;

%%
int main(void){
	yyparse();
  fprintf(stdout,"No syntax error!\n");
	return 0;
}
int yyerror(char *s){
	fprintf( stderr, "Error message: %s\n",s);

	fprintf( stderr, "*** Error at line %d: %s\n", lineCount+1, lastsentence );
	fprintf( stderr, "\n" );
	fprintf( stderr, "Unmatched token: %s\n", yytext );
	fprintf( stderr, "*** syntax error\n");
	exit(-1);
}
int findST(char* id)
{
  int i=0;
  for(i=0;i<curST_size;i++)
  {
    if(strcmp(id,ST[i].id)==0)
    {
      return ST[i].offset;
    }
  }
}

SymbolEntry findnewSTEntry()
{
  if(curST_size==MAX_ST_SIZE)
    {
      yyerror("ST is full!");
    }
  curST_size++;
  var_offset-=4;
  return ST[curST_size-1];
}
void addINFO(char* id,int offset,int scope,int value,int type,int var_type){
  SymbolEntry se = findnewSTEntry();
  se.id = id;
  se.offset = offset;
  se.scope = scope;
  se.value = value;
  se.type = type;
  se.var_type = var_type;
}
void cleanSTEntry(int index)
{
  SymbolEntry se = ST[curST_size];
  se.id[0]='\0';
  se.offset=0;
  se.scope=0;
  se.value=0;
  se.type=0;
  se.var_type=0;
  curST_size--;
}