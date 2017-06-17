#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_ST_SIZE 2048

typedef struct symbolentry{
	char id[2048];
	int offset;
	int scope;
	int type;
	int var_type;
	int bconst;
	int* para_type;
	int para_count;
}SymbolEntry;
#define VAR_TYPE 0
#define FUNC_TYPE 1

#define UNKNOWN 0
#define INT 1
#define DOUBLE 2
#define CHAR 3
#define VOID 4
#define BOOL 5

#define NORMAL 0
#define CONST 1

SymbolEntry ST[MAX_ST_SIZE];
int curST_size=0;
int var_offset=0;
int cur_scope=0;
FILE *as;


int typestack[2048];
int typestackhead=0;


void pushstack(char * target)
{
	fprintf(as,"addi $sp,$sp,-4\n");
	fprintf(as,"swi %s, [$sp]\n",target);
}
void popstack(char * target)
{
	fprintf(as,"lwi %s, [$sp]\n",target);
	fprintf(as,"addi $sp,$sp,4\n");
}

/////////////////////tool/////////////////////////////

int* intarraycopy(int* src, int len)
{
	int *p = malloc(len*sizeof(int));
	memcpy(p,src,len*sizeof(int));
	return p;
}
SymbolEntry* searchST(char* id,int scope)
{
	int i=0;
  int max=-1,index=-1;
  for(i=0;i<curST_size;i++)
  {
  	    	 // fprintf(as,"check:%s,%s\n",id,ST[i].id);
    if(strcmp(id,ST[i].id)==0&&scope>=ST[i].scope)
    {
    	// fprintf(as,"check:%d\n",ST[i].offset);
    	if(ST[i].scope>max) 
    		{
    			index = i;
    			max = scope;
    		}
    }
  }
  if(index==-1)
  	return NULL;
  return &ST[index];
}
int which_type(char* type)
{
	if(strcmp(type,"int")==0)
		return INT;
	else if(strcmp(type,"double")==0)
		return DOUBLE;
	else if(strcmp(type,"char")==0)
		return CHAR;
	else if(strcmp(type,"void")==0)
		return VOID;
	else if(strcmp(type,"void")==0)
		return BOOL;
}
void printtypestackinfo(char * info)
{
	printf("===========%s============\n",info);
	int i=0;
	for(i=typestackhead-1;i>=0;i--)
	{
		if(i==typestackhead-1)
			printf("%d    <---head\n",typestack[i]);
		else
			printf("%d\n",typestack[i]);
	}
	printf("========================\n");
}
///////////////////////////////////////////////////

int findST(char* id,int scope)
{
  SymbolEntry *target = searchST(id,scope);
  if(target->bconst==CONST) yyerror("can't override constant variable");
  if(target==NULL) yyerror("can't find in ST");
  return target->offset;
}
int existinSTEntry(char *id,int scope){
	int i=0;
  for(i=0;i<curST_size;i++)
  {
  	    	 // fprintf(as,"check:%s,%s\n",id,ST[i].id);
    if(strcmp(id,ST[i].id)==0&&scope==ST[i].scope)
    {
    	return 1;
    }
  }
  return 0;
}

SymbolEntry* findnewSTEntry()
{
  if(curST_size==MAX_ST_SIZE)
    {
      yyerror("ST is full!");
    }
  curST_size++;
  var_offset-=4;
  return &ST[curST_size-1];
}
void addvarINFO(char* id,int offset,int scope,int type,int var_type,int bconst){
	if(existinSTEntry(id,scope)) yyerror("multiple declare");
  SymbolEntry* se = findnewSTEntry();
  strcpy(se->id,id);
  se->offset = offset;
  se->scope = scope;
  se->type = type;
  se->var_type = var_type;
  se->bconst = bconst;
  // fprintf(as,"====================\nid:%s\noffset:%d\n======================\n",se.id,se.offset);
}
void cleanSTEntry(int index)
{
  SymbolEntry se = ST[curST_size];
  se.id[0]='\0';
  se.offset=0;
  se.scope=0;
  se.type=0;
  se.var_type=0;
  se.para_count=0;
  curST_size--;
}

int cleanscopeSTEntry(int scope)
{
	int i=0;
	int count=0;
	for(i=curST_size-1;i>=0;i--)
	{
		if(ST[i].scope==scope)
		{
			count++;
			cleanSTEntry(i);
		}
	}
	return count;
}



void updateSTtype(char *type)
{
	int i=0;
	for(i=0;i<curST_size;i++)
	{
		if(ST[i].var_type==UNKNOWN)
		{
			ST[i].var_type = which_type(type);
		}
	}
}
int typeofid(char *id, int scope)
{
	SymbolEntry* target = searchST(id,scope);
	if(target!=NULL)
		return target->var_type;
	return UNKNOWN;
}

void checkrtntype(char* id,int scope)
{
	int idtype = typeofid(id,scope);
	if(idtype==VOID) return;
	int returntype = poptypestack();
	if(returntype!=idtype) yyerror("return value with wrong type");
}

void pushtypestack(int type)
{
	typestack[typestackhead++]=type;
	printtypestackinfo("push");
}

int poptypestack()
{
	int type;
	if(typestackhead>0)
		type=typestack[--typestackhead];
	printtypestackinfo("pop");
	return type;
}

void checkexptype()
{
	int second = poptypestack();
	int first = poptypestack();
	// printf("%d,%d\n",first,second);
	if(first!=second)
	{
		yyerror("type unmatch");
	}
	pushtypestack(first);
}
void addparatoST(char* id,int scope, int* src,int len)
{
	SymbolEntry* target = searchST(id,scope);
	if(target==NULL) yyerror("can't find in ST");
	target->para_type=intarraycopy(src,len);
	target->para_count=len;
}

int comparepara(char* id,int scope,int count)
{
	SymbolEntry* target = searchST(id,scope);
	if(target==NULL)yyerror("can't find in ST");
	if(target->para_count!=count) yyerror("para unmatch!");
	int i=0;
	int type;
	for(i=target->para_count-1;i>=0;i--)
	{
		type = poptypestack();
		if(target->para_type[i]!=type)
		{
			yyerror("para unmatch!");
		}
	}

}
