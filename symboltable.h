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
}SymbolEntry;
#define VAR_TYPE 0
#define FUNC_TYPE 1

#define INT 0
#define DOUBLE 1
#define VOID 2

SymbolEntry ST[MAX_ST_SIZE];
int curST_size=0;
int var_offset=0;
int cur_scope=1;
FILE *as;

int findST(char* id)
{
  int i=0;

  for(i=0;i<curST_size;i++)
  {
  	    	 // fprintf(as,"check:%s,%s\n",id,ST[i].id);
    if(strcmp(id,ST[i].id)==0)
    {
    	// fprintf(as,"check:%d\n",ST[i].offset);
      return ST[i].offset;
    }
  }
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
void addvarINFO(char* id,int offset,int scope,int type,int var_type){
  SymbolEntry* se = findnewSTEntry();
  strcpy(se->id,id);
  se->offset = offset;
  se->scope = scope;
  se->type = type;
  se->var_type = var_type;
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
