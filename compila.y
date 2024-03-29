%{
#include <stdio.h>
#include <ctype.h>
/*#include <conio.h>*/
#include <stdlib.h>
#include <string.h>
#include "tablaSimbolos.h"

#ifndef POLACA_H
#include "polaca.h"
	#define POLACA_H
#endif
#ifndef PILA_H
#include "pila.h"
	#define PILA_H
#endif
#ifndef ASM_H
#include "asm.h"
	#define ASM_H
#endif

#define CANTIDAD_ESTADOS 25
#define CANTIDAD_CARACTERES 20
#define LARGO_MAXIMO_NOMBRE_TOKEN 30
#define LARGO_MAXIMO_CTE_STRING 30
#define CANT_PALABRAS_RESERVADAS 21
#define LARGO_MAXIMO_CTE_REAL 35
#define LARGO_MAXIMO_CTE_ENTERA 5
#define TAM_MAX_CTE_REAL 17014117000000000000000000000000.00
#define TAM_MAX_CTE_ENTERA 65535
#define CANT_TIPOS_COMPARACION 6
#define FILE_TABLA_SIMBOLOS "TablaSimbolos.txt"

%}


/* Tokens - Reglas AL */
%token OP_DECLARACION SEPARADOR_DEC FIN_DEC SEPARADOR_LISTA_VARIABLES
%token OP_COMP_MAYOR OP_COMP_MENOR OP_COMP_MAYOR_IGUAL OP_COMP_MENOR_IGUAL OP_COMP_IGUAL OP_COMP_DISTINTO
%token OP_LOGICO_PRE OP_LOGICO_AND OP_LOGICO_OR
%right OP_ASIGNACION
%left OP_SUMA OP_RESTA OP_MULTIPLICACION OP_DIVISION
%token P_ABRE P_CIERRE I_CONDICIONAL I_ELSE I_FINCONDICIONAL I_BUCLE I_FINBUCLE
%token I_PROG I_FINPROG
%token INI_FUNCION FIN_FUNCION
%token TIPO_DATO_INT TIPO_DATO_REAL TIPO_DATO_STRING
%token ID_VAR
%token CONST_STRING CONST_REAL CONST_ENTERA
%token I_PROG_PRINCIPAL I_FIN_PROG_PRINCIPAL
%token INST_IMPRIMIR PORCENTAJE

/* Start Symbol */
%start PRG;

/* Reglas AS */
%%
PRG: 
	I_PROG lista_declaraciones bloque_principal I_FINPROG;

lista_declaraciones: 
	bloque_declaraciones 
	| bloque_declaraciones lista_funciones;

lista_funciones:
	funcion 
	|lista_funciones funcion;

bloque_principal: 
	I_PROG_PRINCIPAL lista_sentencias I_FIN_PROG_PRINCIPAL;

lista_sentencias: 
	sentencia 
	| lista_sentencias sentencia;

bloque_declaraciones : 
	OP_DECLARACION {abreBloqueDeclaracion();} 
	grupo_declaraciones 
	FIN_DEC {cierraBloqueDeclaracion();} 
	| ;

grupo_declaraciones: 
	declaracion 
	| grupo_declaraciones declaracion;

declaracion:
	tipo { configurarTipoVariableDeclarada($1); } 
	grupo_variables ;
	
tipo:
	TIPO_DATO_INT | TIPO_DATO_REAL | TIPO_DATO_STRING;
	
funcion:
	INI_FUNCION {agregarOperacionAPolaca("INIFUNCION",-1);}
	declaracion_funcion 
	bloque_declaraciones 
	lista_sentencias 
	retorno_funcion {agregarOperacionAPolaca("return",-1); agregarOperacionAPolaca("FINFUNCION",-1);};

retorno_funcion: 
	FIN_FUNCION cadena_caracteres | FIN_FUNCION constante_numerica;
	
declaracion_funcion:
	ID_VAR {agregarAPolaca($1);} SEPARADOR_DEC tipo {agregarTipoDeDatoAFuncion();};
	
sentencia:	
	asignacion
	| condicional
	| bucle
	| output;
	
grupo_variables:
	ID_VAR 
	| ID_VAR SEPARADOR_LISTA_VARIABLES grupo_variables;
	
asignacion:
	ID_VAR { validarIdVariableNoFuncion($1);agregarAPolaca($1); } 
	OP_ASIGNACION  
	mult_asignacion { agregarOperacionAPolaca("=",-1); };
	
mult_asignacion:
	expresion
	| expresion OP_ASIGNACION mult_asignacion { agregarOperacionAPolaca(":=",-1); };
	
expresion:	
	termino 
	| expresion OP_SUMA termino {agregarOperacionAPolaca("+",-1);}
	| expresion OP_RESTA termino {agregarOperacionAPolaca("-",-1);};
	
termino:
	factor 
	| termino OP_MULTIPLICACION factor {agregarOperacionAPolaca("*",-1);}
	| termino OP_DIVISION factor {
		agregarOperacionAPolaca("/",-1);
	};
		
factor:	
	P_ABRE expresion P_CIERRE 
	| constante_numerica
	| ID_VAR {agregarAPolaca($1); agregarCallAPolacaSiEsFuncion($1);} 
	| CONST_STRING {agregarAPolaca($1);}
	| porcentaje;
	
bucle:
	I_BUCLE  { apilarPosicionCondicionalWhile();} condicion {agregarSaltoIncondicionalOR();} lista_sentencias I_FINBUCLE {  
		agregarSaltoFinBucle();
	};
	
condicional:
	I_CONDICIONAL condicion { agregarSaltoIncondicionalOR(); } lista_sentencias resto_condicion ;
	
resto_condicion: 
	I_FINCONDICIONAL { 
		finThen();
		}
	| 
	I_ELSE { 
		   comienzoElse();
	} lista_sentencias I_FINCONDICIONAL { finElse(); };
	
condicion:
	P_ABRE OP_LOGICO_PRE comparacion P_CIERRE { 
		agregarSaltoFinComparacion("NOT"); agregarCantidadDeSaltos(+1);
	}
	| P_ABRE comparacion P_CIERRE {
		agregarSaltoFinComparacion(""); agregarCantidadDeSaltos(+1);
	}
	| P_ABRE comparacion {agregarSaltoFinComparacion("");} OP_LOGICO_AND comparacion {agregarSaltoFinComparacion(""); agregarCantidadDeSaltos(+2);} P_CIERRE
	| P_ABRE comparacion {configurarOR(); agregarSaltoFinComparacion("OR");} 
	  OP_LOGICO_OR comparacion {agregarSaltoFinComparacion("OR"); agregarCantidadDeSaltos(+2);} 
	  P_CIERRE ;
	
	
comparacion:
	expresion OP_COMP_MAYOR expresion { configurarTipoComparacion("JBE"); }

	| expresion OP_COMP_MENOR expresion {   configurarTipoComparacion("JAE"); }

	| expresion OP_COMP_MAYOR_IGUAL expresion {   configurarTipoComparacion("JB"); }

	| expresion OP_COMP_MENOR_IGUAL expresion {  configurarTipoComparacion("JA"); }

	| expresion OP_COMP_IGUAL expresion {   configurarTipoComparacion("JNE"); }

	| expresion OP_COMP_DISTINTO expresion {  configurarTipoComparacion("JE"); }
;
	
output:
	INST_IMPRIMIR P_ABRE cadena_caracteres P_CIERRE {agregarOperacionAPolaca("PRINT",-1);};
	
porcentaje: 
	PORCENTAJE P_ABRE expresion SEPARADOR_LISTA_VARIABLES expresion P_CIERRE {agregarOperacionAPolaca("PERCENT",-1);};
	
cadena_caracteres:
	CONST_STRING {
		agregarAPolaca($1);
}
	| ID_VAR {
		agregarAPolaca($1);
	};

constante_numerica:
	CONST_REAL {agregarAPolaca($1);}
	| CONST_ENTERA {agregarAPolaca($1);};
%%

/***** VARIABLES GLOBALES *****/
int tokenIdentificado;
char tokenChar;
char palabraLeida[200]; 
int indiceLetraPalabraLeida;
char anteriorPalabraLeida[200];
char tipoVariableDeclarada;
int estado;
char caracterLeido;
FILE *fuente;
int linea = 0;
char ambitoActual[30] = "main";

char modoDebug='n';
char bloqueDeclaracionesActivo='n';
char tipoComparacion[5];

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
void separadorListaVariables();
void parentesisAbre();
void parentesisCierra();
void opResta();
void opMultiplicacion();
void opDivision();
void opComparacionMayor();
void opComparacionMenor();
void opComparacionMayorIgual();
void opComparacionMenorIgual();
void opComparacionIgual();
void opComparacionDistinto();
void opAsignacion();
void opSuma();
void finArch();

void debugMessageInt(char * , int );
void debugMessageString(char * , char *);
void debugMessage(char *);
void compilationError(char *);
void compilationErrorString(char *, char *);
char* encontrarSaltoNegado(char*);

void validarIdVariableNoFuncion(int);
void agregarCallAPolacaSiEsFuncion(int);

void agregarAPolaca(int);
void escribirTSEnArchivo();
void setNombreConstante(char *, char *);
void reemplazarCaracteresInvalidos(char *);
void limpiarEspacioPalabraLeida();
void configurarTipoComparacion (char * tipoComp);
void agregarTipoDeDatoAFuncion();

int cantidadElementosTablaSimbolos=0;
struct elementoTablaSimbolos tablaSimbolos[1000];
colaPolaca polacaInv;
pilaEnteros pilaSaltos;
pilaEnteros pilaCantidadSaltos;
char esOR='n';

int main(int argc, char *argv[]) {
	char input[20];
	if(argc<2) {
		printf("Ingrese archivo fuente: ");
		scanf("%s",&input);
		fflush(stdin);
	}
	else {
		strcpy(input,argv[1]);
	}

	if( !(fuente = fopen(input,"rb+") ) ) {
		printf("Error de apertura del archivo fuente...");
		getchar();
		exit(0);
    }
	
	polacaInv.cantidadElementosCola=0;
	pilaSaltos.cantidadElementosPila=0;
	pilaCantidadSaltos.cantidadElementosPila=0;
	
	printf("Modo Debug? (y/n)");
	modoDebug = getchar();
	fflush(stdin);
	printf("\n");

	/* Esto es para probar */
/*    while (!feof(fuente)) {
        printf("Token identificado: %d\n", yylex());
    }
*/
	/* En lugar de comentar el código anterior, muevo el puntero de nuevo al inicio del archivo */
	fseek(fuente,0,SEEK_SET);

	yyparse();
	//getchar();
    fclose(fuente);

	escribirTSEnArchivo();
	imprimePolaca(&polacaInv);
	generarArchivoIntermedia(&polacaInv);
	crearFuenteASM(&polacaInv, &tablaSimbolos, cantidadElementosTablaSimbolos);
}

int yyerror(char *s) {
	printf("%s\n", s);
	exit(1);
}

int matrizTransicion[CANTIDAD_ESTADOS][CANTIDAD_CARACTERES] = {
        {1,2,4,5,7,8,9,10,11,12,14,18,16,20,21,22, 24,0,0,25},
        {1,1,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25},
        {25,2,3,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25},
        {25,3,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25},
        {25,4,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25},
        {5,5,5,6,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,-1},
        {25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25},
        {25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25},
        {25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25},
        {25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25},
        {25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25},
        {25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25},
        {25,25,25,25,25,25,25,25,25,25,25,13,25,25,25,25,25,25,25,25},
        {25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25},
        {25,25,25,25,25,25,25,25,25,25,25,15,25,25,25,25,25,25,25,25},
        {25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25},
        {-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,17,-1,-1,-1,-1,-1,-1,-1,-1},
        {25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25},
        {25,25,25,25,25,25,25,25,25,25,25,19,25,25,25,25,25,25,25,25},
        {25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25},
        {25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25},
        {25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25},
        {-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,23,-1,-1,-1,-1},
        {23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,0,23,0},
        {25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25}
};

void (*proceso[CANTIDAD_ESTADOS][CANTIDAD_CARACTERES])()= {

	{initId,initCte,initCte,initCadena,separadorDec,opSuma,opResta,opMultiplicacion,opDivision,opComparacionMenor,opComparacionMayor,opAsignacion,nada,parentesisAbre,parentesisCierra,nada,separadorListaVariables,nada,nada,finArch},
	{contId,contId,finId,finId,finId,finId,finId,finId,finId,finId,finId,finId,finId,finId,finId,finId,finId,finId,finId,finId},
	{finCteEntera,contCte,contCte,finCteEntera,finCteEntera,finCteEntera,finCteEntera,finCteEntera,finCteEntera,finCteEntera,finCteEntera,finCteEntera,finCteEntera,finCteEntera,finCteEntera,finCteEntera,finCteEntera,finCteEntera,finCteEntera,finCteEntera},
	{finCteReal,contCte,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal},
	{finCteReal,contCte,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal,finCteReal},
	{contCadena,contCadena,contCadena,finCadena,contCadena,contCadena,contCadena,contCadena,contCadena,contCadena,contCadena,contCadena,contCadena,contCadena,contCadena,contCadena,contCadena,contCadena,contCadena,error},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,opComparacionMenorIgual,nada,nada,nada,nada,nada,nada,nada,nada},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,opComparacionMayorIgual,nada,nada,nada,nada,nada,nada,nada,nada},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada},
	{error,error,error,error,error,error,error,error,error,error,error,opComparacionDistinto,error,error,error,error,error,error,error,error},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,opComparacionIgual,nada,nada,nada,nada,nada,nada,nada,nada},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada},
	{error,error,error,error,error,error,error,error,error,error,error,error,error,error,error,nada,error,error,error,error},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada}
};

struct {
	char palabra[20];
	int valor;
} palabrasReservadas[CANT_PALABRAS_RESERVADAS] = {
	"main", I_PROG_PRINCIPAL,
	"endmain", I_FIN_PROG_PRINCIPAL,
	"begin", I_PROG,
	"end", I_FINPROG,
	"dec", OP_DECLARACION,
	"endec", FIN_DEC,
	"function", INI_FUNCION,
	"return", FIN_FUNCION,
	"int", TIPO_DATO_INT,
	"real", TIPO_DATO_REAL,
	"string", TIPO_DATO_STRING,
	"if", I_CONDICIONAL,
	"else", I_ELSE,
	"endif", I_FINCONDICIONAL,
	"while", I_BUCLE,
	"endwhile", I_FINBUCLE,
	"not", OP_LOGICO_PRE,
	"and", OP_LOGICO_AND,
	"or", OP_LOGICO_OR,
	"print", INST_IMPRIMIR,
	"percent", PORCENTAJE,
};

struct {
	char salto[4];
	char saltoNegado[4];
} saltos [CANT_TIPOS_COMPARACION] = {
	"JA", "JBE",
	"JB", "JAE",
	"JE", "JNE",
	"JBE", "JA",
	"JAE", "JB",
	"JNE", "JE"	
};

int determinarColumna(char c) {
	int columna=-1;
	if(isprint(c) && c !='$') columna=0;
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
		case ',': columna=16; break;
		
		/* Saltos de línea */
		case '\n': columna=17; linea++; break;
		case '\r': columna=17; break;

		/* Eliminado de espacios */
		case '\t': columna=18; break;
		case ' ': columna=18; break;

		case EOF: columna=19; break;
	}
	return columna;
}

void abreBloqueDeclaracion() {

	debugMessage("--- DECLARACIONES --- Abre Bloque");
	bloqueDeclaracionesActivo='y';
}

void cierraBloqueDeclaracion() {
	debugMessage("--- DECLARACIONES --- Cierra Bloque");
	bloqueDeclaracionesActivo='n';
}

void configurarTipoVariableDeclarada(int idTokenTipoVariable) {
	switch(idTokenTipoVariable) {
		case TIPO_DATO_INT: tipoVariableDeclarada='e'; break;
		case TIPO_DATO_REAL: tipoVariableDeclarada='r'; break;
		case TIPO_DATO_STRING: tipoVariableDeclarada='s'; break;
	}
	debugMessageInt("--- DECLARACIONES --- Configurado tipo de variable",idTokenTipoVariable);
}

void configurarTipoComparacion (char * tipoComp) {
	strcpy(tipoComparacion,tipoComp);
}

void agregarTipoDeDatoAFuncion() {
	tablaSimbolos[cantidadElementosTablaSimbolos - 1].tipoRetorno = tolower(anteriorPalabraLeida[0]);
	debugMessageString("--- Agregando tipo de retorno a función ", tablaSimbolos[cantidadElementosTablaSimbolos - 1].nombre);
}

void agregarSaltoFinComparacion(char * operador) {
	agregarPosicionAPilaDeSaltos(+1);
	debugMessageInt("---POLACA-FINCOMP--- Agregando salto en ",polacaInv.cantidadElementosCola);
	agregarOperacionAPolaca("CMP",-1);
	agregarOperacionAPolaca("_",-1); // Dejo una celda en blanco para llenar con la posicion a la que voy a saltar
	if(compareCaseInsensitive(operador,"NOT") && compareCaseInsensitive(operador,"OR")){
		agregarOperacionAPolaca(tipoComparacion,-1);
	} else {
		agregarOperacionAPolaca(encontrarSaltoNegado(tipoComparacion),-1);
	}
}

char* encontrarSaltoNegado(char* tipoComparacion){
	int i = 0;
	while (i < CANT_TIPOS_COMPARACION) {
		if(!compareCaseInsensitive(tipoComparacion,saltos[i].salto)){
			return saltos[i].saltoNegado;
		}
		i++;
	}
	return "";
}

void apilarPosicionCondicionalWhile() {
		agregarPosicionAPilaDeSaltos(0);
	}

void agregarSaltoFinBucle() {
	int posicionDireccionSalto;
	char posicionStr[30];
	int cantidadSaltos;
	pilaExtraer(&pilaCantidadSaltos,&cantidadSaltos);
	printf("CANTIDAD DE SALTOS: %d\n\n",cantidadSaltos);
	// -- CONDICIONES DE DECISION --
	while(cantidadSaltos>0){
		pilaExtraer(&pilaSaltos,&posicionDireccionSalto);
		int posicionSalto = polacaInv.cantidadElementosCola + 2;
		char posicionStr[30];
		sprintf(posicionStr,"%d",posicionSalto);
		agregarPosicionDeSaltoAPolaca(posicionStr,posicionDireccionSalto);
		cantidadSaltos--;
		debugMessageString("--- POLACA --- Agregando", posicionStr);
	}
	// -- SALTO DE NUEVO A PRIMER COMPARACION (WHILE) --
	int posicionPrimerComparacion;
	pilaExtraer(&pilaSaltos,&posicionPrimerComparacion);
	sprintf(posicionStr,"%d",posicionPrimerComparacion);

	agregarPosicionDeSaltoAPolaca(posicionStr,-1);
	agregarOperacionAPolaca("JMP",-1);	
}

void agregarCantidadDeSaltos(int adicional){
	pilaEmpujar(&pilaCantidadSaltos, adicional);
}

void configurarOR() {
	 esOR='s'; 
}

void agregarSaltoIncondicionalOR() {
	if(esOR=='s') {
		finThen();
		agregarPosicionAPilaDeSaltos(-2);
		agregarCantidadDeSaltos(1);
		esOR='n';
	}
}

void comienzoElse() {
	llenarCeldasDeSalto(2);


	debugMessageInt("---POLACA-ELSE--- Agregando salto en",polacaInv.cantidadElementosCola);
	agregarPosicionAPilaDeSaltos(+0);
	agregarCantidadDeSaltos(1);
	agregarOperacionAPolaca("_",-1);
	agregarOperacionAPolaca("JMP",-1);
}

void finThen() {
	if(esOR=='s') {
		agregarOperacionAPolaca("_",-1);
		agregarOperacionAPolaca("JMP",-1);
	}

	llenarCeldasDeSalto(+0);
}

void finElse() {
	
	if(esOR=='s') {
		agregarOperacionAPolaca("_",-1);
		agregarOperacionAPolaca("JMP",-1);
	}

	llenarCeldasDeSalto(0);
		
}


void llenarCeldasDeSalto(int adicionalACeldaActual) {

	int posicionDireccionSalto;
	int cantidadSaltos;
	pilaExtraer(&pilaCantidadSaltos,&cantidadSaltos);
	debugMessageInt("--- FLUJO --- Cantidad de saltos",cantidadSaltos);

	while(cantidadSaltos>0){
		pilaExtraer(&pilaSaltos,&posicionDireccionSalto);
		int posicionSalto = polacaInv.cantidadElementosCola+adicionalACeldaActual;
		
		char posicionStr[30];
		sprintf(posicionStr,"%d",posicionSalto);
		agregarPosicionDeSaltoAPolaca(posicionStr,posicionDireccionSalto);
		cantidadSaltos--;
		debugMessageString("--- POLACA --- Agregando", posicionStr);
	}

}




void agregarPosicionAPilaDeSaltos(int adicional) {
		int posActual = polacaInv.cantidadElementosCola;
		posActual += adicional;
		pilaEmpujar(&pilaSaltos, posActual);
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
	if(!compareCaseInsensitive(palabrasReservadas[i++].palabra,c))
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
	//debugMessageString("INFO initId: Palabra Leída (temporal)",palabraLeida);

}

void contId() {
	palabraLeida[indiceLetraPalabraLeida++] = caracterLeido;
	//debugMessageString("INFO contId: Palabra Leída (temporal)",palabraLeida);
}

void finId() {
	if(strlen(palabraLeida) > LARGO_MAXIMO_NOMBRE_TOKEN){
		compilationErrorString("Se excedio el largo maximo de identificador",palabraLeida);
	}
	int indicePalabraReservada = verificarPalabraReservada(palabraLeida);

	debugMessageString("--- INFO --- Identificador leido",palabraLeida);
	if (!compareCaseInsensitive(palabraLeida,"main")){
			strcpy(ambitoActual,"main");
	}
	// si es una palabra reservada
	if(indicePalabraReservada != -1) {
		debugMessageInt("--- INFO --- finId: Indice Palabra Reservada", indicePalabraReservada);
		tokenIdentificado = palabrasReservadas[indicePalabraReservada-1].valor;
		strcpy(anteriorPalabraLeida,palabraLeida);
	} else {
		int esFuncion = !compareCaseInsensitive(anteriorPalabraLeida,"function");
		/* Si no es una palabra reservada, la busca en la tabla de simbolos */
		int indicePalabraEnTablaDeSimbolos = buscarEnTS(ambitoActual,palabraLeida,bloqueDeclaracionesActivo,tablaSimbolos,cantidadElementosTablaSimbolos);
		if(indicePalabraEnTablaDeSimbolos==-1) {
			debugMessageString("--- INFO --- Identificador no encontrado en tabla de símbolos",palabraLeida);
			// Si la palabra no está en la tabla de símbolos y estamos en bloque de declaraciones o es una función, crearla.
			if(bloqueDeclaracionesActivo=='y' || esFuncion) {
				if(esFuncion){
					strcpy(ambitoActual,"main"); 
				}
				cantidadElementosTablaSimbolos= agregarEnTS(ambitoActual, tolower(anteriorPalabraLeida[0]), palabraLeida, "VALOR", tablaSimbolos, cantidadElementosTablaSimbolos);
				yylval = cantidadElementosTablaSimbolos - 1;
				debugMessageString("--- INFO --- Agregando a tabla de símbolos",palabraLeida);
			}
			else {
				char mensajeError[100];
				strcpy(mensajeError,"Error, se intento usar el identificador antes de definirlo: ");
				strcat(mensajeError,palabraLeida);
				compilationError(mensajeError);
			}
		}
		else {
			debugMessageInt("--- INFO --- Indice en tabla de símbolos",indicePalabraEnTablaDeSimbolos);
			yylval = indicePalabraEnTablaDeSimbolos;
			}
		/*Si el id leído antes es "function" se cambia el ámbito al nombre de la nueva función*/
		if(esFuncion){
			strcpy(ambitoActual, palabraLeida);
		}
		tokenIdentificado = ID_VAR;
	}
}

void initCte() {
	//yylval=NULL;
	limpiarEspacioPalabraLeida();
	palabraLeida[indiceLetraPalabraLeida++] = caracterLeido;
}

void contCte() {
	palabraLeida[indiceLetraPalabraLeida++] = caracterLeido;
}

void finCteEntera() {
	if(strlen(palabraLeida) > LARGO_MAXIMO_CTE_ENTERA){
		compilationErrorString("La constante entera supera el máximo permitido",palabraLeida);
	}
	debugMessageString("--- DEBUG --- Constante entera leída",palabraLeida);
	
	int tamPalabraLeida = strlen(palabraLeida);
	char nombreConstante[tamPalabraLeida+1] ;
	setNombreConstante(palabraLeida, nombreConstante);
	int valorConstante = atoi(palabraLeida);
	
	if(valorConstante <= TAM_MAX_CTE_ENTERA && valorConstante >= 0) {		
		int indicePalabraEnTablaDeSimbolos = buscarEnTS(ambitoActual,nombreConstante,bloqueDeclaracionesActivo,tablaSimbolos,cantidadElementosTablaSimbolos);

		if(indicePalabraEnTablaDeSimbolos==-1) {
			debugMessageString("--- DEBUG --- Constante no encontrada en tabla de símbolos",palabraLeida);	
			cantidadElementosTablaSimbolos = agregarEnTS(ambitoActual, 'i', nombreConstante, &valorConstante, tablaSimbolos, cantidadElementosTablaSimbolos);
			yylval = cantidadElementosTablaSimbolos - 1;
			debugMessageString("--- DEBUG --- Agregando constante entera a tabla de símbolos",nombreConstante);
		}
		else {
			yylval = indicePalabraEnTablaDeSimbolos;
		}	
		tokenIdentificado = CONST_ENTERA;
	} else {
		compilationErrorString("La constante entera supera el máximo permitido",palabraLeida);
	}
}

void finCteReal() {
	if(strlen(palabraLeida) > LARGO_MAXIMO_CTE_REAL){
		compilationErrorString("La constante real supera el máximo permitido",palabraLeida);
	}
	debugMessageString("Constante real leída",palabraLeida);
	
	int tamPalabraLeida = strlen(palabraLeida);
	char nombreConstante[tamPalabraLeida+1] ;
	setNombreConstante(palabraLeida, nombreConstante);
	float valorConstante = atof(palabraLeida);
	if(valorConstante <= TAM_MAX_CTE_REAL) {
		int indicePalabraEnTablaDeSimbolos = buscarEnTS(ambitoActual,nombreConstante,bloqueDeclaracionesActivo,tablaSimbolos,cantidadElementosTablaSimbolos);

		if(indicePalabraEnTablaDeSimbolos==-1) {
			debugMessageString("Constante no encontrada en tabla de símbolos",palabraLeida);	
			cantidadElementosTablaSimbolos = agregarEnTS(ambitoActual, 'r', nombreConstante, &valorConstante, tablaSimbolos, cantidadElementosTablaSimbolos);
			yylval = cantidadElementosTablaSimbolos - 1;
			debugMessageString("Agregando constante real a tabla de símbolos",nombreConstante);
		}
		else {
			yylval=indicePalabraEnTablaDeSimbolos;
		}	
		
		tokenIdentificado = CONST_REAL;
	} else {		
		compilationErrorString("La constante real supera el máximo permitido",palabraLeida);
	}
}

void initCadena() {
	limpiarEspacioPalabraLeida();
}

void contCadena() {
	palabraLeida[indiceLetraPalabraLeida++] = caracterLeido;
}

void finCadena() {
	debugMessageString("Constante leída",palabraLeida);

	int tamPalabraLeida = strlen(palabraLeida);
	if(tamPalabraLeida <= LARGO_MAXIMO_CTE_STRING) {
		char nombreConstante[tamPalabraLeida+1] ;
		setNombreConstante(palabraLeida, nombreConstante);	
		int indicePalabraEnTablaDeSimbolos = buscarEnTS(ambitoActual,nombreConstante,bloqueDeclaracionesActivo,tablaSimbolos,cantidadElementosTablaSimbolos);
		debugMessageInt("--- TS --- Indice en Tabla de Símbolos",indicePalabraEnTablaDeSimbolos);

		if(indicePalabraEnTablaDeSimbolos==-1) {
			debugMessageString("Constante no encontrada en tabla de símbolos",palabraLeida);
			cantidadElementosTablaSimbolos= agregarEnTS(ambitoActual, 's', nombreConstante, palabraLeida, tablaSimbolos, cantidadElementosTablaSimbolos);
			yylval = cantidadElementosTablaSimbolos - 1;
			debugMessageString("Agregando constante a tabla de símbolos",nombreConstante);
		}
		else {
			yylval = indicePalabraEnTablaDeSimbolos;
		}
		tokenIdentificado = CONST_STRING;
	} else {
		compilationErrorString("La constante supera el maximo tamaño de caracteres admitido",palabraLeida);
	}
}

void separadorDec() {
	tokenIdentificado = SEPARADOR_DEC;
}

void separadorListaVariables() {
	tokenIdentificado = SEPARADOR_LISTA_VARIABLES;
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

void opComparacionMenor() {
	tokenIdentificado = OP_COMP_MENOR;
}

void opComparacionMayor() {
	tokenIdentificado = OP_COMP_MAYOR;
}

void opComparacionMenorIgual() {
	tokenIdentificado = OP_COMP_MENOR_IGUAL;
}

void opComparacionMayorIgual() {
	tokenIdentificado = OP_COMP_MAYOR_IGUAL;
}

void opComparacionIgual() {
	tokenIdentificado = OP_COMP_IGUAL;
}

void opComparacionDistinto() {
	tokenIdentificado = OP_COMP_DISTINTO;
}

void opAsignacion() {
	tokenIdentificado = OP_ASIGNACION;
}

void finArch() {
	tokenIdentificado = 0;
}

void debugMessageInt(char * cadena, int entero) {
	if(modoDebug=='y') {
		char mensaje[100];
		sprintf( mensaje, "%s: %d", cadena, entero );
		puts(mensaje);
	}
}

void debugMessage(char * cadena) {
	if(modoDebug=='y') {
		puts(cadena);
	}
}


void debugMessageString(char * cadena, char * string) {
	if(modoDebug=='y') {
		char mensaje[100];
		strcpy(mensaje,cadena);
		strcat(mensaje,": ");
		strcat(mensaje,string);
		puts(mensaje);
	}
}

void compilationError(char * mensaje) {
	printf("ERROR: %s\n", mensaje);
	puts("La compilación finalizó con errores, presione una tecla para finalizar");
	system("pause");
	exit(0);
}

void compilationErrorString(char * mensaje, char * parametro) {
	printf("ERROR: %s: %s\n", mensaje, parametro);
	puts("La compilación finalizó con errores, presione una tecla para finalizar");
	system("pause");
	exit(0);
}

void escribirTSEnArchivo() {
	FILE *tsFile;
	if( !(tsFile = fopen(FILE_TABLA_SIMBOLOS,"w") ) ) {
		printf("Error de apertura del archivo de salida de la Tabla de Simbolos...");
		getchar();
		exit(0);
    }

	fprintf(tsFile, "--- Tabla de Símbolos ---\n\n");

	for(int i = 0; i < cantidadElementosTablaSimbolos; i++) {

		fprintf(tsFile, "- Simbolo N°: %d\n", i);
		fprintf(tsFile, "   Ambito: %s\n", tablaSimbolos[i].ambito);
		fprintf(tsFile, "   Nombre: %s\n", tablaSimbolos[i].nombre);

		if(tablaSimbolos[i].tipo == 's') {
			fprintf(tsFile, "   Tipo: string\n");
			fprintf(tsFile, "   Valor: %s\n", tablaSimbolos[i].valorString);
		} else if(tablaSimbolos[i].tipo == 'i') {
			fprintf(tsFile, "   Tipo: entero\n");
			fprintf(tsFile, "   Valor: %d\n", tablaSimbolos[i].valorEntero);
		} else if(tablaSimbolos[i].tipo == 'r') {
			fprintf(tsFile, "   Tipo: real\n");
			fprintf(tsFile, "   Valor: %f\n", tablaSimbolos[i].valorReal);
		} else if(tablaSimbolos[i].tipo == 'f') {
			fprintf(tsFile, "   Tipo: funcion (Retorno: %c)\n", tablaSimbolos[i].tipoRetorno);
			fprintf(tsFile, "   Valor: %s\n", tablaSimbolos[i].valorString);
		}
		fprintf(tsFile, "   Eliminado: %d\n\n", tablaSimbolos[i].eliminado);
	}

	fclose(tsFile);
}

void setNombreConstante(char * constante, char * nombreConstante) {
	strcpy(nombreConstante,"_");
	strcat(nombreConstante,constante);
	reemplazarCaracteresInvalidos(nombreConstante);
}

void reemplazarCaracteresInvalidos(char * cadena) {
	for(int i=0; i < strlen(cadena); i++) {
		if(cadena[i] == ' ') {
			cadena[i] = '_';
		} else if(cadena[i] == '.') {
			cadena[i] = '_';
		} else if(!isalnum((int)cadena[i])){
			cadena[i] = '_';
		}
	}
}

void validarIdVariableNoFuncion(int indiceTS) {
	char tipo = tablaSimbolos[indiceTS].tipo;
	if(tipo == 'f') {
		compilationError("No se puede llamar a una función en el lado izquierdo de una asignación.");
	}
}

void agregarCallAPolacaSiEsFuncion(int indiceTS) {
	char tipo = tablaSimbolos[indiceTS].tipo;
	if(tipo == 'f') {
		agregarOperacionAPolaca("call",-1);
	}
}

/* Funciones de Polaca */

void agregarAPolaca(int indiceTS) {
	
	//FIXME Ámbito hardcodeado
	char mensajeAgregadoPolaca[200];
	sprintf(mensajeAgregadoPolaca,"--- POLACA --- Agregando indice %d",indiceTS);
	debugMessageString(mensajeAgregadoPolaca,tablaSimbolos[indiceTS].nombre);
	
	if(indiceTS!=-1) {
		polacaAgregar(&polacaInv,tablaSimbolos[indiceTS].nombre,tablaSimbolos[indiceTS].tipo,-1);
	}
	else {
		// TODO Puede darse este caso? Es decir, que se llegue acá con un identificador que no esté en la TS
	}
}


void agregarOperacionAPolaca(char * operacion, int posicion) {

	polacaAgregar(&polacaInv,operacion,'o',posicion);

	debugMessageString("--- POLACA --- Agregando",operacion);
	
}
void agregarPosicionDeSaltoAPolaca(char * posicionSalto, int posicion) {

	polacaAgregar(&polacaInv,posicionSalto,'p',posicion);

	debugMessageString("--- POLACA --- Agregando",posicionSalto);
	
}

int compareCaseInsensitive(char* cad1, char* cad2) {
/* WINDOWS */
	return strcmpi(cad1,cad2);
/* LINUX */ 
//	return strcasecmp(cad1,cad2);	
}
