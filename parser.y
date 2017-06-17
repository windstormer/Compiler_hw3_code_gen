%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symboltable.h"


extern int lineCount;
extern char lastsentence[3000];
extern char* yytext;
int labelcount=0;
int paralist[2048];
int paralist_n=0;


int parause_n=0;
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

%type <textval> function_head

%%
program: global program
       |
       ;


global: declaration ';'
      | const_declaration ';'
      | function_head global_left_c local_S global_right_c {checkrtntype($1,cur_scope);cleanscopeSTEntry(cur_scope);}
      ;

global_left_c: '{' {cur_scope++;}
             ;
global_right_c: '}' {cur_scope--;}
              ;

local_S: local_declares local_use
       | local_use
       | local_declares
       |
       ;

local_declares: local_declares local_declare
              | local_declare
              ;
local_use: local_use local
         | local
         ;
local_declare: declaration ';'
     | const_declaration ';'
     ;

local: normal_use ';'
     | digwrite ';'
     | delay ';'
     | RETURN expression ';' {popstack("$r0");}
     | BREAK ';'
     | CONTINUE ';'
     | left_c local_S right_c
     | IF '(' expression small_right_c left_c local_S right_c {
                                                      fprintf(as,".L%d:\n",labelcount);
                                                      labelcount++;
                                                    }
     | IF '(' expression small_right_c left_c local_S if_right_c ELSE left_c local_S right_c {
                                                                                      fprintf(as,".L%d:\n",labelcount+1);
                                                                                      labelcount+=2;
                                                                                   }
     | WHILE while_left_c expression small_right_c left_c local_S right_c {
                                                              fprintf(as,"j .L%d\n", labelcount+1);
                                                              fprintf(as,".L%d:\n", labelcount);
                                                              labelcount+=2;
                                                             }
     ;
small_right_c: ')' 
             ;
while_left_c: '(' {fprintf(as,".L%d:\n", labelcount+1); } 
            ;
if_right_c: '}' {
                  int count=cleanscopeSTEntry(cur_scope);
                  fprintf(as,"addi $sp,$sp,%d\n", 4*count);
                  cur_scope--;
                  fprintf(as,"j .L%d\n",labelcount+1);
                  fprintf(as,".L%d:\n",labelcount);
                }
          ;
left_c: '{' {cur_scope++;}
      ;
right_c: '}' {    
                  int count=cleanscopeSTEntry(cur_scope);
                  fprintf(as,"addi $sp,$sp,%d\n", 4*count);
                  cur_scope--;
             }
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
function_head: TYPE ID '(' para ')' {
                                      cur_scope++;
                                      addvarINFO($2,var_offset,cur_scope,FUNC_TYPE,UNKNOWN,NORMAL);
                                      updateSTtype($1);
                                      strcpy($$,$2);
                                      addparatoST($2,cur_scope,paralist,paralist_n);
                                      paralist_n=0;
                                    }
            | VOI ID '(' para ')' {
                                    cur_scope--;
                                    addvarINFO($2,var_offset,cur_scope,FUNC_TYPE,VOID,NORMAL);
                                    strcpy($$,$2);
                                    addparatoST($2,cur_scope,paralist,paralist_n);
                                    paralist_n=0;
                                  }
            ;

normal_use: ID '=' expression { 
                                popstack("$r0");
                                fprintf(as,"swi $r0, [$fp+(%d)]\n",findST($1,cur_scope)); 
                                poptypestack();
                              }
          // | ID Arr_use '=' expression
          | expression 
          ;

///////declaration///////////////////////

declaration: TYPE lots_of_ID_declaration {updateSTtype($1);}
           | VOI lots_of_func_declare {updateSTtype($1);}
           ;                    

lots_of_ID_declaration: ID_declaration ',' lots_of_ID_declaration
                      | ID_declaration
                      ;

ID_declaration: ID {
                    fprintf(as,"addi $sp,$sp,-4\n");
                    addvarINFO($1,var_offset,cur_scope,VAR_TYPE,UNKNOWN,NORMAL);
                   }
              | ID '=' init_expression {
                                          // fprintf(as,"ID=%s\n",$1);
                                        addvarINFO($1,var_offset,cur_scope,VAR_TYPE,UNKNOWN,NORMAL);
                                        popstack("$r0");
                                        fprintf(as,"addi $sp,$sp,-4\n");
                                        fprintf(as,"swi $r0, [$fp+(%d)]\n",findST($1,cur_scope));
                                        poptypestack();
                                       }
              // | ID Arr_declare Arr_init
              | func_declar
              ;
///////////////////////const//////////////////////
const_declaration: CONS TYPE const_lots_of_ID_declaration {updateSTtype($2);}
                 ;

const_lots_of_ID_declaration: const_ID_declaration ',' const_lots_of_ID_declaration
                            | const_ID_declaration
                            ;

const_ID_declaration: ID '=' NUM {addvarINFO($1,var_offset,cur_scope,VAR_TYPE,UNKNOWN,CONST);}
                    ;                  

//////////////////////////function////////////////////

lots_of_func_declare: func_declar ',' lots_of_func_declare
                    | func_declar
                    ;

func_declar: ID '(' para ')' {
                                addvarINFO($1,var_offset,cur_scope,FUNC_TYPE,UNKNOWN,NORMAL);
                                addparatoST($1,cur_scope,paralist,paralist_n);
                                paralist_n=0;
                             } 
           ;

para: para_style ',' para
    | para_style
    | 
    ;

para_style: TYPE ID {paralist[paralist_n++]=which_type($1);}
          // | TYPE ID Arr_declare
          ;
func_invocation: ID '(' no_or_more_expression ')' {
                                                    comparepara($1,cur_scope,parause_n);
                                                    pushtypestack(typeofid($1,cur_scope));
                                                    parause_n=0;
                                                  }
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
NUM: IN {pushtostack($1);pushtypestack(INT);}
   | DOU {pushtypestack(DOUBLE);}
   | TF {pushtypestack(BOOL);}
   | CHA {pushtypestack(CHAR);}
   // | STR
   // | NUL
   ;

INT_DOUBLE_ID: IN {
                    fprintf(as, "movi r0, %d\n",$1 );
                    pushstack("$r0");
                  }
          // | DOU
          | ID {                  
                  fprintf(as,"lwi $r0, [$fp+(%d)]\n",findST($1,cur_scope));
                  pushstack("$r0");
                }
          ;

// int_char: IN
//         | CHA
//         ;

///////////////expression////////////////
no_or_more_expression: lots_of_expression
                     |
                     ;
lots_of_expression: function_expression ',' lots_of_expression 
                  | function_expression
                  ;
function_expression: expression {parause_n++;}
                   ;  

expression: expression '+' expression { doexpression('+'); checkexptype();}
          | expression '-' expression { doexpression('-'); checkexptype();}
          | expression '*' expression { doexpression('*'); checkexptype();}
          | expression '/' expression { doexpression('/'); checkexptype();}
          | expression '%' expression { doexpression('%'); checkexptype();}
          | ID DP {
                    fprintf(as,"lwi $r0, [$fp+(%d)]\n", findST($1,cur_scope));
                    pushstack("$r0");
                    fprintf(as,"addi $r0, $r0, 1\n");
                    fprintf(as,"swi $r0, [$fp+(%d)]\n", findST($1,cur_scope));
                  } 
          | ID DM {
                    fprintf(as,"lwi $r0, [$fp+(%d)]\n", findST($1,cur_scope));
                    pushstack("$r0");
                    fprintf(as,"addi $r0, $r0, -1\n");
                    fprintf(as,"swi $r0, [$fp+(%d)]\n", findST($1,cur_scope));
                  } 
          | expression COMP expression {docomparation($2); checkexptype();}
          // | expression LOR expression {doexpression($2);}
          // | expression LAND expression {doexpression($2);}
          | '(' expression ')'
          | ID {
                  fprintf(as,"lwi $r0, [$fp+(%d)]\n",findST($1,cur_scope));
                  pushstack("$r0");
                  pushtypestack(typeofid($1,cur_scope));
               }
          | NUM 
          | '-' expression %prec unary {
                                          fprintf(as,"movi $r0, -1\n");
                                          pushstack("$r0");
                                          doexpression('*');
                                       }
          | '!' expression {
                              popstack("$r0");
                              fprintf(as,"bnez $r0, .L%d\n", labelcount);
                           }
          // | ID Arr_use
          | func_invocation
          ;

init_expression: init_expression '+' init_expression { doexpression('+'); checkexptype();}
          | init_expression '-' init_expression { doexpression('-'); checkexptype();}
          | init_expression '*' init_expression { doexpression('*'); checkexptype();}
          | init_expression '/' init_expression { doexpression('/'); checkexptype();}
          | init_expression '%' init_expression { doexpression('%'); checkexptype();}
          | ID DP {
                    fprintf(as,"lwi $r0, [$fp+(%d)]\n", findST($1,cur_scope));
                    pushstack("$r0");
                    fprintf(as,"addi $r0, $r0, 1\n");
                    fprintf(as,"swi $r0, [$fp+(%d)]\n", findST($1,cur_scope));
                  } 
          | ID DM {
                    fprintf(as,"lwi $r0, [$fp+(%d)]\n", findST($1,cur_scope));
                    pushstack("$r0");
                    fprintf(as,"addi $r0, $r0, -1\n");
                    fprintf(as,"swi $r0, [$fp+(%d)]\n", findST($1,cur_scope));
                  } 
          | init_expression COMP init_expression {docomparation($2); checkexptype();}
          // | init_expression LOR init_expression {doexpression($2);}
          // | init_expression LAND init_expression {doexpression($2);}
          | '(' init_expression ')'
          | ID {
                  fprintf(as,"lwi $r0, [$fp+(%d)]\n",findST($1,cur_scope));
                  pushstack("$r0");
                  pushtypestack(typeofid($1,cur_scope));
               }
          | NUM 
          | '-' init_expression %prec unary {
                                          fprintf(as,"movi $r0, -1\n");
                                          pushstack("$r0");
                                          doexpression('*');
                                       }
          | '!' init_expression {
                              popstack("$r0");
                              fprintf(as,"bnez $r0, .L%d\n", labelcount);
                           }
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

void docomparation(char* comp)
{
  popstack("$r1");
  popstack("$r0");
  if(strcmp(comp,">=")==0)
  {
    fprintf(as,"slts $ta,$r0,$r1\n");
    fprintf(as,"bnez $ta, .L%d\n",labelcount);
  }else if(strcmp(comp,">")==0)
  {
    fprintf(as,"slts $ta,$r1,$r0\n");
    fprintf(as,"beqz $ta, .L%d\n",labelcount);
  }else if(strcmp(comp,"<=")==0)
  {
    fprintf(as,"slts $ta,$r1,$r0\n");
    fprintf(as,"bnez $ta, .L%d\n",labelcount);
  }else if(strcmp(comp,"<")==0)
  {
    fprintf(as,"slts $ta,$r0,$r1\n");
    fprintf(as,"beqz $ta, .L%d\n",labelcount);
  }else if(strcmp(comp,"==")==0)
  {
    fprintf(as,"bne $r0, $r1, .L%d\n",labelcount);
  }else if(strcmp(comp,"!=")==0)
  {
    fprintf(as,"beq $r0, $r1, .L%d\n",labelcount);
  }
}
