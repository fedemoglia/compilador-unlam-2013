%{
#include <stdio.h>
#include <ctype.h>
#include <conio.h>
#include <stdlib.h>
#include <string.h>
#include "tablaSimbolos.h"
#define CANTIDAD_ESTADOS 24
#define CANTIDAD_CARACTERES 19
#define LARGO_MAXIMO_NOMBRE_TOKEN 20
#define CANT_PALABRAS_RESERVADAS 16
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
				A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z ;
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

/***** VARIABLES GLOBALES *****/
int tokenIdentificado;
char tokenChar;
char palabraLeida[LARGO_MAXIMO_NOMBRE_TOKEN]; int indiceLetraPalabraLeida;
int estado;
char caracterLeido;
FILE *fuente;
int linea = 0;

char modoDebug='n';

int yyparse();
int yylex();

void error();
void nada();
void initId();
void contId();
void finId();
void initCte();
void contCte();
void finCteEntera();
void finCteReal();
void initCadena();
void contCadena();
void finCadena();
void separadorDec();
void parentesisAbre();
void parentesisCierra();
void opSuma();
void opResta();
void opMultiplicacion();
void opDivision();
void opComparacion();
void opAsignacion();
void opSuma();


int cantidadElementosTablaSimbolos=0;
struct elementoTablaSimbolos tablaSimbolos[1000];

int main(int argc, char *argv[]) {
	char input[20];
	if(argc<2) {
		printf("Ingrese archivo fuente: ");
		scanf("%s",&input);
	}
	else {
		strcpy(input,argv[1]);
	}

	if( !(fuente = fopen(input,"rb+") ) ) {
		printf("Error de apertura del archivo fuente...");
		getch();
		exit(0);
    }
	printf("Modo Debug? (y/n)");
	modoDebug = getch();
	printf("\n");

	/* Esto es para probar */
	
    while (!feof(fuente)) {
        printf("Token identificado: %d\n", yylex());
    }
	
	
    yyparse();
	system("PAUSE");
    fclose(fuente);
}

int yyerror(char *s) {
	printf("%s\n", s);
}

int matrizTransicion[CANTIDAD_ESTADOS][CANTIDAD_CARACTERES] = {
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
	{-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,23,-1,-1,-1},
	{23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,0,23,0},
};

void (*proceso[CANTIDAD_ESTADOS][CANTIDAD_CARACTERES])()= {
	{initId,initCte,initCte,initCadena,separadorDec,opSuma,opResta,opMultiplicacion,opDivision,opComparacion,opComparacion,opAsignacion,nada,parentesisAbre,parentesisCierra,nada,nada,nada,nada},
	{contId,contId,finId,finId,finId,finId,finId,finId,finId,finId,finId,finId,finId,finId,finId,finId,finId,finId,finId},
	{finCteEntera,contCte,nada,finCteEntera,finCteEntera,finCteEntera,finCteEntera,finCteEntera,finCteEntera,finCteEntera,finCteEntera,finCteEntera,finCteEntera,finCteEntera,finCteEntera,finCteEntera,finCteEntera,finCteEntera,finCteEntera},
	{finCteReal,contCte,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal},
	{finCteReal,contCte,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal},
	{contCadena,contCadena,contCadena,finCadena,contCadena,contCadena,contCadena,contCadena,contCadena,contCadena,contCadena,contCadena,contCadena,contCadena,contCadena,contCadena,contCadena,contCadena,error},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,opComparacion,nada,nada,nada,nada,nada,nada,nada},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,opComparacion,nada,nada,nada,nada,nada,nada,nada},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada},
	{error,error,error,error,error,error,error,error,error,error,error,opComparacion,error,error,error,error,error,error,error},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,opComparacion,nada,nada,nada,nada,nada,nada,nada},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada},
	{error,error,error,error,error,error,error,error,error,error,error,error,error,error,error,nada,error,error,error},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada},
};

char palabrasReservadas[CANT_PALABRAS_RESERVADAS][20] = {
	"main",
	"endmain",
	"begin",
	"end",
	"dec",
	"entero",
	"real",
	"string",
	"if",
	"while",
	"and",
	"or",
	"endif",
	"endwhile",
	"print",
	"percent"
	};

int determinarColumna(char c) {
	int columna=-1;
	if(isalpha(c)) columna=0;
	if(isdigit(c)) columna=1;

	switch(c) {
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
	}
	return columna;
}


int yylex()	{
	int cant=0;
	estado = 0;
	int estadoFinal  = CANTIDAD_ESTADOS;
	int columna;

	while (estado != estadoFinal) {
		caracterLeido = getc(fuente);
		columna = determinarColumna(caracterLeido);
		if(columna==-1) {
			return 1;	// Error
		}
		(*proceso[estado][columna])();
		estado = matrizTransicion[estado][columna];
	}
	ungetc(caracterLeido, fuente);

	return tokenIdentificado;
}

int verificarPalabraReservada(char *c)
{
    int i=0;
    while(i<CANT_PALABRAS_RESERVADAS)
    {
        if(!strcmp(palabrasReservadas[i++],c))
        {
            return i;
        }
    }
    return -1;
}



/* Funciones léxicas */

void error() {
    printf("Error léxico: se esperaba otro caracter\n\n");
    system("PAUSE");
    exit(1);
}

void nada() {}

void limpiarEspacioPalabraLeida() {
	indiceLetraPalabraLeida=0;
	int i=0;
	while(i<LARGO_MAXIMO_NOMBRE_TOKEN) {
		palabraLeida[i++]=0;
		}
}

void initId() {
	limpiarEspacioPalabraLeida();
	palabraLeida[indiceLetraPalabraLeida++] = caracterLeido;
	if(modoDebug=='y') {
	printf("INFO initId: Letra Leida %c, Palabra Leída (temporal) %s\n",caracterLeido,palabraLeida);
	}
}

void contId() {
	palabraLeida[indiceLetraPalabraLeida++] = caracterLeido;
	if(modoDebug=='y') {
	printf("INFO contId: Letra Leida %c, Palabra Leída (temporal) %s\n",caracterLeido,palabraLeida);
	}
}

void finId() {
	tokenIdentificado = ID_VAR;

	int indicePalabraReservada = verificarPalabraReservada(palabraLeida);
	if(modoDebug=='y') {
		printf("INFO finId: Palabra Leída %s, indice %d\n",palabraLeida, indicePalabraReservada);
	}
	
}

void initCte() {

}

void contCte() {

}

void finCteEntera() {
	tokenIdentificado = CONST_ENTERA;
}

void finCteReal() {
	tokenIdentificado = CONST_REAL;
}

void initCadena() {

}

void contCadena() {

}

void finCadena() {
	tokenIdentificado = CONST_STRING;
}

void separadorDec() {
	tokenIdentificado = SEPARADOR_DEC;
}

void parentesisAbre() {
	tokenIdentificado = P_ABRE;
}

void parentesisCierra() {
	tokenIdentificado = P_CIERRE;
}

void opSuma() {
	tokenIdentificado = OP_SUMA;
}

void opResta() {
	tokenIdentificado = OP_RESTA;
}

void opMultiplicacion() {
	tokenIdentificado = OP_MULTIPLICACION;
}

void opDivision() {
	tokenIdentificado = OP_DIVISION;
}

void opComparacion() {
	tokenIdentificado = OP_COMPARACION;
}

void opAsignacion() {
	tokenIdentificado = OP_ASIGNACION;
}
