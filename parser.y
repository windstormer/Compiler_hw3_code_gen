%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int lineCount;
extern char lastsentence[3000];
extern char* yytext;

%}
%start program

%token ID TYPE CHAR_TYPE
%token IN DOU TF CHA STR NUL
%token ENDLINE
%token CONS VOI
%token LOR LAND LNOT COMP DP DM
%token FOR
%token IF ELSE
%token DO WHILE
%token BREAK CONTINUE RETURN
%token SWITCH CASE DEFAULT
%token DIGWRITE DELAY HIGH LOW

%left LOR
%left LAND
%nonassoc '!'
%left COMP
%left '+' '-'
%left '*' '/' '%'
%nonassoc unary
%left DP DM
%left '[' ']'

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
function_use: TYPE ID '(' para ')'
            | VOI ID '(' para ')'
            ;

normal_use: ID '=' expression
          | ID Arr_use '=' expression
          | expression
          ;

///////declaration///////////////////////

declaration: TYPE lots_of_ID_declaration
           | VOI lots_of_func_declare
           ;                    

lots_of_ID_declaration: ID_declaration ',' lots_of_ID_declaration
                      | ID_declaration
                      ;

ID_declaration: ID normal_init
              | ID Arr_declare Arr_init
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
          | TYPE ID Arr_declare
          ;

////////////////////////////////////
normal_init: '=' init_expression
           |
           ;

Arr_use: '[' expression ']'
       | Arr_use '[' expression ']'
       ;

Arr_declare: '[' IN ']'
           | Arr_declare '[' IN ']'
           ;

Arr_init: '=' '{' no_or_more_expression '}'
        | 
        ;  
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
UNUM: '-' INT_DOUBLE_ID %prec unary
    | '+' INT_DOUBLE_ID %prec unary
    | NUM
    ;
// int_char: IN
//         | CHA
//         ;

///////////////expression////////////////
no_or_more_expression: lots_of_expression
                     |
                     ;
lots_of_expression: expression ',' lots_of_expression
                  | expression
                  ;  

expression: expression '+' expression
          | expression '-' expression
          | expression '*' expression
          | expression '/' expression
          | expression '%' expression
          | ID DP
          | ID DM
          | expression COMP expression
          | expression LOR expression
          | expression LAND expression
          | '(' expression ')'
          | ID
          | UNUM
          | '!' expression 
          | ID Arr_use
          // | func_invocation
          ;

init_expression: init_expression '+' init_expression
          | init_expression '-' init_expression
          | init_expression '*' init_expression
          | init_expression '/' init_expression
          | init_expression '%' init_expression
          | ID DP
          | ID DM
          | init_expression COMP init_expression
          | init_expression LOR init_expression
          | init_expression LAND init_expression
          | '(' init_expression ')'
          | ID
          | UNUM
          | '!' init_expression
          | ID Arr_use
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