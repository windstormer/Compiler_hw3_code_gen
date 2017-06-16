%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symboltable.h"

extern int lineCount;
extern char lastsentence[3000];
extern char* yytext;


%}
%start program

%union {
  int intval;
  double doubleval;
  char textval[2048];
}

%token <textval> ID TYPE CHAR_TYPE
%token <intval> DOU
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

// %type <intval> INT_DOUBLE_ID

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
     | RETURN expression ';' {popstack("$r0");}
     | left_c local_S right_c
     ;

left_c: '{' {cur_scope++;}
      ;
right_c: '}' {cur_scope--;}
       ;
///////////////for hw3/////////////////
digwrite: DIGWRITE '(' IN ',' high_low ')' {
                                              fprintf(as, "movi $r0, %d\n",$3 );
                                              fprintf(as,"bal digitalWrite\n");
                                           }
        ;
delay: DELAY '(' INT_DOUBLE_ID ')' {
                                      popstack("$r0");
                                      fprintf(as,"bal delay\n");
                                   }
     ;

high_low: HIGH {fprintf(as, "movi $r1, 1\n");}
        | LOW {fprintf(as, "movi $r1, 0\n");}
        ;

//////////use//////////////////////
function_use: TYPE ID '(' para ')' {cur_scope++;}
            | VOI ID '(' para ')' {cur_scope--;}
            ;

normal_use: ID '=' expression { 
                                popstack("$r0");
                                fprintf(as,"swi $r0, [$fp+(%d)]\n",findST($1)); 
                              }
          // | ID Arr_use '=' expression
          | expression
          ;

///////declaration///////////////////////

declaration: TYPE lots_of_ID_declaration
           | VOI lots_of_func_declare
           ;                    

lots_of_ID_declaration: ID_declaration ',' lots_of_ID_declaration
                      | ID_declaration
                      ;

ID_declaration: ID {
                    fprintf(as,"addi $sp,$sp,-4\n");
                    addvarINFO($1,var_offset,cur_scope,VAR_TYPE,INT);
                   }
              | ID '=' init_expression {
                                          // fprintf(as,"ID=%s\n",$1);
                                        addvarINFO($1,var_offset,cur_scope,VAR_TYPE,INT);
                                        popstack("$r0");
                                        fprintf(as,"addi $sp,$sp,-4\n");
                                        fprintf(as,"swi $r0, [$fp+(%d)]\n",findST($1));
                                         
                                       }
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
NUM: IN {pushtostack($1);}
   // | DOU 
   // | TF
   // | CHA
   // | STR
   // | NUL
   ;

INT_DOUBLE_ID: IN {
                    fprintf(as, "movi r0, %d\n",$1 );
                    pushstack("$r0");
                  }
          // | DOU
          | ID {                  
                  fprintf(as,"lwi $r0, [$fp+(%d)]\n",findST($1));
                  pushstack("$r0");
                }
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

expression: expression '+' expression { doexpression('+'); }
          | expression '-' expression { doexpression('-'); }
          | expression '*' expression { doexpression('*'); }
          | expression '/' expression { doexpression('/'); }
          | expression '%' expression { doexpression('%'); }
          // | ID DP 
          // | ID DM
          // | expression COMP expression {doexpression($2);}
          // | expression LOR expression {doexpression($2);}
          // | expression LAND expression {doexpression($2);}
          | '(' expression ')'
          | ID {
                  fprintf(as,"lwi $r0, [$fp+(%d)]\n",findST($1));
                  pushstack("$r0");
               }
          | NUM 
          | '-' expression %prec unary
          // | '!' expression 
          // | ID Arr_use
          // | func_invocation
          ;

init_expression: init_expression '+' init_expression {doexpression('+');}
          | init_expression '-' init_expression {doexpression('-');}
          | init_expression '*' init_expression {doexpression('*');}
          | init_expression '/' init_expression {doexpression('/');}
          | init_expression '%' init_expression {doexpression('%');}
          // | ID DP
          // | ID DM
          // | init_expression COMP init_expression {doexpression($2);}
          // | init_expression LOR init_expression {doexpression($2);}
          // | init_expression LAND init_expression {doexpression($2);}
          | '(' init_expression ')'
          | ID {
                  fprintf(as,"lwi $r0, [$fp+(%d)]\n",findST($1));
                  pushstack("$r0");
               }
          | NUM 
          | '-' expression %prec unary
          // | '!' init_expression
          // | ID Arr_use
          ;

%%
int main(void){
  as = fopen("assembly","w+");
	yyparse();
  fclose(as);
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

void doexpression(char op)
{
  popstack("$r1");
  popstack("$r0");
  if(op=='+')
  {
    fprintf(as,"add $r0,$r0,$r1\n");
    pushstack("$r0");
  }else if(op=='-')
  {
    fprintf(as,"sub $r0,$r0,$r1\n");
    pushstack("$r0");
  }else if(op=='*')
  {
    fprintf(as,"mul $r0,$r0,$r1\n");
    pushstack("$r0");
  }else if(op=='/')
  {
    fprintf(as,"divsr $r0,$r2,$r0,$r1\n");
    pushstack("$r0");
  }else if(op=='%')
  {
    fprintf(as,"divsr $r0,$r2,$r0,$r1\n");
    pushstack("$r2");
  }
    
}

void pushtostack(int input)
{
  fprintf(as,"movi $r0, %d\n",input);
  pushstack("$r0");
}

