%{
#include <stdio.h>
%}




/* Tokens - Reglas AL */
%token OP_DECLARACION SEPARADOR_DEC FIN_DEC SEPARADOR_GRUPO_VARIABLES
%token OP_COMPARACION OP_LOGICO_PRE OP_LOGICO OP_ASIGNACION
%token OP_SUMA OP_RESTA OP_MULTIPLICACION OP_DIVISION  
%token P_ABRE P_CIERRE I_CONDICIONAL I_FINCONDICIONAL I_BUCLE I_FINBUCLE
%token I_PROG I_FINPROG INI_FUNCION FIN_FUNCION
%token TIPO_DATO
%token ID_VAR
%token CONST_STRING CONST_REAL CONST_ENTERA
%token I_PROG_PRINCIPAL I_FIN_PROG_PRINCIPAL
%token INST_IMPRIMIR
/*OP_DECLARACION	:	DEC;
SEPARADOR_DEC 	:	:;
FIN_DEC	:	ENDEC;
SEPARADOR_GRUPO_VARIABLES 	:	,;
OP_COMPARACION	:	< | 
> | 
<= | 
>= | 
!= | 
== ;
OP_LOGICO_PRE	:	NOT;
OP_LOGICO	:	AND |
			OR ;
OP_ASIGNACION	:	= ;
OP_SUMA	:	+ ;
OP_RESTA	:	- ;
OP_MULTIPLICACION	:	* ;
OP_DIVISION	:	/ ;
P_ABRE	:	( ;
P_CIERRE	:	) ;
I_CONDICIONAL	:	IF;
I_FINCONDICIONAL	:	ENDIF;
I_BUCLE	:	WHILE;
I_FINBUCLE	:	ENDWHILE;
I_PROG_PRINCIPAL	:	MAIN;
I_FIN_PROG_PRINCIPAL	:	ENDMAIN; 
I_FINPROG	:	END;
I_PROG	:	BEGIN;
I_FINPROG	:	END;
INI_FUNCION	:	FUNCTION;
FIN_FUNCION	:	RETURN;
TIPO_DATO	:	REAL | INT;
ID_VAR	: 	:	letra | letra cadena_str;
INST_IMPRIMIR	:	PRINT;
cadena_str	:	caracter | 
cadena_str caracter;
caracter	:	letra | numero | caracter_especial;
letra		:	a | b | c | d | e | f | g | h | i | j | k | l | m | n | o | p | q | r | s | t | u | v | w | x | y | z |
			A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X |
Y | Z ;
caracter_especial:	@ | % | & | / | : | , | “ ;
numero		:	0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9;
*/

/* Start Symbol */
%start PRG;

/* Reglas AS */
%%
PRG	: I_PROG  bloque_principal lista_funciones I_FINPROG | 
 I_PROG  bloque_principal I_FINPROG ;
lista_funciones    :    funcion | lista_funciones funcion;
bloque_principal    :    I_PROG_PRINCIPAL bloque I_FIN_PROG_PRINCIPAL ;
bloque	:	lista_sentencias | declaracion lista_sentencias;

lista_sentencias : sentencia | lista_sentencias sentencia;
declaracion	:	OP_DECLARACION TIPO_DATO SEPARADOR_DEC grupo_variables FIN_DEC;
funcion	:	INI_FUNCION declaracion_funcion bloque FIN_FUNCION;
declaracion_funcion	:	ID_VAR SEPARADOR_DEC TIPO_DATO;
sentencia	:	asignacion |
			condicional |
			bucle |
output;
grupo_variables	:	ID_VAR | ID_VAR SEPARADOR_GRUPO_VARIABLES grupo_variables;
asignacion	:	ID_VAR OP_ASIGNACION mult_asignacion;
mult_asignacion	:	expresion | expresion OP_ASIGNACION mult_asignacion; 
expresion	:	termino | expresion OP_SUMA termino | expresion OP_RESTA termino ;
termino	:	factor | termino OP_MULTIPLICACION factor | termino OP_DIVISION factor;
factor	:	P_ABRE expresion P_CIERRE | constante_numerica | ID_VAR | CONST_STRING;
bucle	:	I_BUCLE condicion bloque I_FINBUCLE;
condicional	:	I_CONDICIONAL condicion bloque I_FINCONDICIONAL ;
condicion	:	P_ABRE comparacion P_CIERRE |
			P_ABRE comparacion OP_LOGICO comparacion P_CIERRE ;
comparacion	:	elemento OP_COMPARACION elemento  |
OP_LOGICO_PRE elemento OP_COMPARACION elemento;
output		:	INST_IMPRIMIR P_ABRE cadena_caracteres P_CIERRE;
cadena_caracteres 	:	CONST_STRING | ID_VAR;
elemento	:	CONST_STRING |
constante_numerica |
ID_VAR;
constante_numerica	:	CONST_REAL | 	
CONST_ENTERA;
%%




int tipo_token;
int estado;
char caracter_leido;
FILE *fuente;

int yyparse();
int yylex();

int main() {
	char[20] input;
	printf("Ingrese archivo fuente: ");
	scanf("%s",&input);
  
	if( !(fuente = fopen(input,"rb+") ) ) {
		printf("Error de apertura del archivo fuente...");
		getch();
		exit(0);
    }
  
	yyparse();
}   
  

int yyerror(char *s) {
	printf("%s\n", s);
}

int CANTIDAD_ESTADOS=24;
int CANTIDAD_CARACTERES=19

int matrizTransicion[CANTIDAD_ESTADOS][CARACTERES] = 
{
{1,2,4,5,7,8,9,10,11,12,14,18,16,20,21,22,0,0,24},
{1,1,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24},
{24,2,3,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24},
{24,3,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24},
{24,4,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24},
{5,5,5,6,5,5,5,5,5,5,5,5,5,5,5,5,5,5,24},
{24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24},
{24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24},
{24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24},
{24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24},
{24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24},
{24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24},
{24,24,24,24,24,24,24,24,24,24,24,13,24,24,24,24,24,24,24},
{24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24},
{24,24,24,24,24,24,24,24,24,24,24,15,24,24,24,24,24,24,24},
{24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24},
{-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,17,-1,-1,-1,-1,-1,-1,-1},
{24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24},
{24,24,24,24,24,24,24,24,24,24,24,19,24,24,24,24,24,24,24},
{24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24},
{24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24},
{24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24},
{24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,23,24,24,24},
{23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,0,23,23}
}; 

int obtenerColumna(char c)
  {
  int columna;
  if(isalpha(c)) columna=0;
  if(isdigit(c)) columna=1;
  
  switch(c)
    {
    case '.': columna=2;break;
    case '"': columna=3; break;
    case ':': columna=4; break;
    case '+': columna=5; break;
    case '-': columna=6; break;
    case '*': columna=7; break;
    case '/': columna=8; break;
    case '<': columna=9; break;
    case '>': columna=10; break;
    case '=': columna=11; break;
    case '!': columna=12; break;
    case '(': columna=13; break;
    case ')': columna=14; break;
    case '#': columna=15; break;
	
	/* Saltos de línea */
	case '\n': columna=16; linea++; break;
    case '\r': columna=16; break;
	
	/* Eliminado de espacios */
    case '\t': columna=17; break;
    case ' ': columna=17; break;
	
    case EOF: columna=18; break;
	default: columna=24; break;
    }
  return columna;  
  }


int yylex()
  { 
  cant=0;
  estado = 0;
  int estado_final  = CANTIDAD_ESTADOS;
  int columna;
        
  while (estado != estado_final)
    {
		caracter_leido=getc(fuente);
		columna = determinarColumna(caracter_leido); 
		estado = matrizTransicion[estado][columna];
    }

	return 0; // TODO ! 
  }   
