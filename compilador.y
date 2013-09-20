/* Declaraciones */
%{
#include <stdio.h>

}%

%token ID
%token CTE

%start programa


/* Reglas */
%%

programa: ID;

%%

int yyparse();

int yylex(void) {
	return 1;
}

int yyerror(char *s) {
	printf("%s\n", s);
}

int main () {
	yyparse();
}