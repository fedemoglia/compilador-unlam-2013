%{
#include <stdio.h>
%}

%token ID
%token CTE

%start programa
%%
programa :
	ID { }
;
%%

int yyparse();
int yylex();

int main() {
	printf("LA");
	return 0;
	yyparse();
}   
  
int yylex() {
	return 1;
}

int yyerror(char *s) {
	printf("EEERRR %s\n", s);
}
