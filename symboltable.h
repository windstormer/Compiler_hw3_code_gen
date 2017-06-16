#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_ST_SIZE 2048

typedef struct symbolentry{
	char* id;
	int offset;
	int scope;
	int value;
	int type;
	int var_type;
}SymbolEntry;
#define VAR_TYPE 0
#define FUNC_TYPE 1

#define INT 0
#define DOUBLE 1
#define VOID 2
