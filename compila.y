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


#define CANTIDAD_ESTADOS 25
#define CANTIDAD_CARACTERES 20
#define LARGO_MAXIMO_NOMBRE_TOKEN 20
#define LARGO_MAXIMO_CTE_STRING 30
#define CANT_PALABRAS_RESERVADAS 21
#define TAM_MAX_CTE_REAL 9999 // TODO Definir número real.
#define TAM_MAX_CTE_ENTERA 9999 // TODO Definir número real.


%}


/* Tokens - Reglas AL */
%token OP_DECLARACION SEPARADOR_DEC FIN_DEC SEPARADOR_LISTA_VARIABLES
%token OP_COMPARACION OP_LOGICO_PRE OP_LOGICO_AND OP_LOGICO_OR
%right OP_ASIGNACION I_PROG
%left OP_SUMA OP_RESTA OP_MULTIPLICACION OP_DIVISION
%token P_ABRE P_CIERRE I_CONDICIONAL I_FINCONDICIONAL I_BUCLE I_FINBUCLE
%left I_FINPROG
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
	INI_FUNCION declaracion_funcion bloque_declaraciones lista_sentencias retorno_funcion ;

retorno_funcion: 
	FIN_FUNCION ID_VAR;
	
declaracion_funcion:
	ID_VAR SEPARADOR_DEC tipo;
	
sentencia:	
	asignacion
	| condicional
	| bucle
	| output
	| porcentaje;
	
grupo_variables:
	ID_VAR 
	| ID_VAR SEPARADOR_LISTA_VARIABLES grupo_variables;
	
asignacion:
	ID_VAR {  agregarAPolaca($1); } 
	OP_ASIGNACION { agregarOperacionAPolaca("="); } 
	mult_asignacion ;
	
mult_asignacion:
	expresion 
	| expresion OP_ASIGNACION { agregarOperacionAPolaca("="); } mult_asignacion ;
	
expresion:	
	termino 
	| expresion OP_SUMA termino {agregarOperacionAPolaca("+");}
	| expresion OP_RESTA termino {agregarOperacionAPolaca("-");};
	
termino:
	factor 
	| termino OP_MULTIPLICACION factor {agregarOperacionAPolaca("*");}
	| termino OP_DIVISION factor {
		printf("División: IndiceTS %d = IndiceTS %d\n",$1,$3);
		agregarOperacionAPolaca("/");
	};
		
factor:	
	P_ABRE expresion P_CIERRE 
	| constante_numerica {agregarAPolaca($1);}
	| ID_VAR {agregarAPolaca($1);} 
	| CONST_STRING {agregarAPolaca($1);};
	
bucle:
	I_BUCLE condicion lista_sentencias I_FINBUCLE ;
	
condicional:
	I_CONDICIONAL condicion lista_sentencias I_FINCONDICIONAL ;
	
condicion:
	P_ABRE comparacion P_CIERRE
	| P_ABRE comparacion operador comparacion P_CIERRE ;
	
operador:
	OP_LOGICO_AND 
	| OP_LOGICO_OR;
	
comparacion:
	elemento OP_COMPARACION elemento {printf("Comparacion: %d con %d (comparacion %d)\n",$1,$3,$2);};
	| OP_LOGICO_PRE elemento OP_COMPARACION elemento {printf("Comparacion negada: %d con %d (comparacion %d)\n",$2,$4,$3);};
	
output:
	INST_IMPRIMIR P_ABRE cadena_caracteres P_CIERRE {printf("Output: %d\n",$3);};
	
porcentaje: 
	PORCENTAJE P_ABRE expresion SEPARADOR_LISTA_VARIABLES expresion P_CIERRE;
	
cadena_caracteres:
	CONST_STRING {
		printf("CHK_PRINT. ");
		agregarAPolaca($1);
	} 
	| ID_VAR {
		printf("CHK5");
		agregarAPolaca($1);
	};

elemento:
	CONST_STRING
	| constante_numerica 
	| ID_VAR {
		printf("CHK6");
		agregarAPolaca($1);
	};
	
constante_numerica:
	CONST_REAL 
	| CONST_ENTERA ;
%%

/***** VARIABLES GLOBALES *****/
int tokenIdentificado;
char tokenChar;
char palabraLeida[LARGO_MAXIMO_NOMBRE_TOKEN]; int indiceLetraPalabraLeida;
char anteriorPalabraLeida[LARGO_MAXIMO_NOMBRE_TOKEN];
char tipoVariableDeclarada;
int estado;
char caracterLeido;
FILE *fuente;
int linea = 0;

char modoDebug='n';
char bloqueDeclaracionesActivo='n';

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
void opSuma();
void opResta();
void opMultiplicacion();
void opDivision();
void opComparacion();
void opAsignacion();
void opSuma();
void finArch();

void debugMessageInt(char * , int );
void debugMessageString(char * , char *);
void debugMessage(char *);
void compilationError(char *);

void escribirTSEnArchivo();
void setNombreConstante(char *, char *);

int cantidadElementosTablaSimbolos=0;
struct elementoTablaSimbolos tablaSimbolos[1000];
struct pila polacaInv;

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
	
	polacaInv.cantidadElementosPila=0;
	
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
	getchar();
    fclose(fuente);

	escribirTSEnArchivo();
	imprimePolaca(&polacaInv);
}

int yyerror(char *s) {
	printf("%s\n", s);
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

	{initId,initCte,initCte,initCadena,separadorDec,opSuma,opResta,opMultiplicacion,opDivision,opComparacion,opComparacion,opAsignacion,nada,parentesisAbre,parentesisCierra,nada,separadorListaVariables,nada,nada,finArch},
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
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,opComparacion,nada,nada,nada,nada,nada,nada,nada,nada},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,opComparacion,nada,nada,nada,nada,nada,nada,nada,nada},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada},
	{error,error,error,error,error,error,error,error,error,error,error,opComparacion,error,error,error,error,error,error,error,error},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada},
	{nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,nada,opComparacion,nada,nada,nada,nada,nada,nada,nada,nada},
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
	"endif", I_FINCONDICIONAL,
	"while", I_BUCLE,
	"endwhile", I_FINBUCLE,
	"not", OP_LOGICO_PRE,
	"and", OP_LOGICO_AND,
	"or", OP_LOGICO_OR,
	"print", INST_IMPRIMIR,
	"percent", PORCENTAJE,
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
        if(!strcmpi(palabrasReservadas[i++].palabra,c))
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
	/*debugMessageString("INFO initId: Palabra Leída (temporal)",palabraLeida);*/

}

void contId() {
	palabraLeida[indiceLetraPalabraLeida++] = caracterLeido;
	/*debugMessageString("INFO contId: Palabra Leída (temporal)",palabraLeida);*/
}

void finId() {
	int indicePalabraReservada = verificarPalabraReservada(palabraLeida);

	debugMessageString("--- INFO --- Identificador leido",palabraLeida);


	// si es una palabra reservada
	if(indicePalabraReservada != -1) {
		debugMessageInt("--- INFO --- finId: Indice Palabra Reservada", indicePalabraReservada);
		tokenIdentificado = palabrasReservadas[indicePalabraReservada-1].valor;
	} else {
		/* Si no es una palabra reservada, la busca en la tabla de simbolos */

		// FIXME Habría que cambiar el ambito que está fijado
		int indicePalabraEnTablaDeSimbolos = buscarEnTS("main",palabraLeida,tablaSimbolos,cantidadElementosTablaSimbolos);

		if(indicePalabraEnTablaDeSimbolos==-1) {
			debugMessageString("--- INFO --- Identificador no encontrado en tabla de símbolos",palabraLeida);
			if(bloqueDeclaracionesActivo=='y' || !strcmpi(anteriorPalabraLeida,"function")) {
				// Si la palabra no está en la tabla de símbolos y estamos en bloque de declaraciones, crearla.
				// FIXME El ámbito y el tipo están fijados
				cantidadElementosTablaSimbolos= agregarEnTS("main", anteriorPalabraLeida[0], palabraLeida, "VALOR", tablaSimbolos, cantidadElementosTablaSimbolos);
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
		tokenIdentificado = ID_VAR;
	}
	strcpy(anteriorPalabraLeida,palabraLeida);
}

void initCte() {
	limpiarEspacioPalabraLeida();
	palabraLeida[indiceLetraPalabraLeida++] = caracterLeido;
}

void contCte() {
	palabraLeida[indiceLetraPalabraLeida++] = caracterLeido;
}

void finCteEntera() {
	// FIXME Falta validar el tamaño maximo de una variable entera.
	debugMessageString("--- DEBUG --- Constante entera leída",palabraLeida);
	
	int tamPalabraLeida = strlen(palabraLeida);
	char nombreConstante[tamPalabraLeida+1] ;
	setNombreConstante(palabraLeida, nombreConstante);
	int valorConstante = atoi(palabraLeida);
	
	if(valorConstante <= TAM_MAX_CTE_ENTERA) {	
		// FIXME Habría que cambiar el ambito que está fijado
		int indicePalabraEnTablaDeSimbolos = buscarEnTS("main",nombreConstante,tablaSimbolos,cantidadElementosTablaSimbolos);

		if(indicePalabraEnTablaDeSimbolos==-1) {
			debugMessageString("--- DEBUG --- Constante no encontrada en tabla de símbolos",palabraLeida);
					
			cantidadElementosTablaSimbolos = agregarEnTS("main", 'e', nombreConstante, &valorConstante, tablaSimbolos, cantidadElementosTablaSimbolos);
			yylval = cantidadElementosTablaSimbolos - 1;
			debugMessageString("--- DEBUG --- Agregando constante entera a tabla de símbolos",nombreConstante);
		}
		else {
			yylval = cantidadElementosTablaSimbolos;
		}		
		tokenIdentificado = CONST_ENTERA;
	} else {
		compilationError("La constante entera supera el máximo permitido");
	}
}

void finCteReal() {
	// FIXME Falta validar el tamaño maximo de una variable real.
	debugMessageString("Constante real leída",palabraLeida);
	
	int tamPalabraLeida = strlen(palabraLeida);
	char nombreConstante[tamPalabraLeida+1] ;
	setNombreConstante(palabraLeida, nombreConstante);
	float valorConstante = atof(palabraLeida);
	
	if(valorConstante <= TAM_MAX_CTE_REAL) {
		// FIXME Habría que cambiar el ambito que está fijado
		int indicePalabraEnTablaDeSimbolos = buscarEnTS("main",nombreConstante,tablaSimbolos,cantidadElementosTablaSimbolos);

		if(indicePalabraEnTablaDeSimbolos==-1) {
			debugMessageString("Constante no encontrada en tabla de símbolos",palabraLeida);
					
			cantidadElementosTablaSimbolos = agregarEnTS("main", 'r', nombreConstante, &valorConstante, tablaSimbolos, cantidadElementosTablaSimbolos);
			yylval = cantidadElementosTablaSimbolos - 1;
			debugMessageString("Agregando constante real a tabla de símbolos",nombreConstante);
		}
		
		tokenIdentificado = CONST_REAL;
	} else {
		compilationError("La constante real supera el máximo permitido");
	}
}

void initCadena() {
	limpiarEspacioPalabraLeida();
}

void contCadena() {
	if(indiceLetraPalabraLeida < LARGO_MAXIMO_CTE_STRING) {
		palabraLeida[indiceLetraPalabraLeida++] = caracterLeido;
	} else {
		compilationError("La cadena supera el máximo tamaño aceptado");
	}
}

void finCadena() {
	debugMessageString("Constante leída leido",palabraLeida);

	int tamPalabraLeida = strlen(palabraLeida);
	if(tamPalabraLeida <= LARGO_MAXIMO_CTE_STRING) {
		char nombreConstante[tamPalabraLeida+1] ;
		setNombreConstante(palabraLeida, nombreConstante);
		
		// FIXME Habría que cambiar el ambito que está fijado
		int indicePalabraEnTablaDeSimbolos = buscarEnTS("main",nombreConstante,tablaSimbolos,cantidadElementosTablaSimbolos);

		if(indicePalabraEnTablaDeSimbolos==-1) {
			debugMessageString("Constante no encontrada en tabla de símbolos",palabraLeida);
			cantidadElementosTablaSimbolos= agregarEnTS("main", 's', nombreConstante, palabraLeida, tablaSimbolos, cantidadElementosTablaSimbolos);
			yylval = cantidadElementosTablaSimbolos - 1;
			debugMessageString("Agregando constante a tabla de símbolos",nombreConstante);
		}
		tokenIdentificado = CONST_STRING;
	} else {
		debugMessageString("Error: La constante %s supera el maximo tamaño de caracteres admitido.",palabraLeida);
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

void opComparacion() {
	tokenIdentificado = OP_COMPARACION;
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

void escribirTSEnArchivo() {
	FILE *tsFile;
	if( !(tsFile = fopen("ts.txt","w") ) ) {
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
		} else if(tablaSimbolos[i].tipo == 'e') {
			fprintf(tsFile, "   Tipo: entero\n");
			fprintf(tsFile, "   Valor: %d\n", tablaSimbolos[i].valorEntero);
		} else if(tablaSimbolos[i].tipo == 'r') {
			fprintf(tsFile, "   Tipo: real\n");
			fprintf(tsFile, "   Valor: %f\n", tablaSimbolos[i].valorReal);
		} else if(tablaSimbolos[i].tipo == 'f') {
			fprintf(tsFile, "   Tipo: función\n");
			fprintf(tsFile, "   Valor: %f\n", tablaSimbolos[i].valorString);
		}
		fprintf(tsFile, "   Eliminado: %d\n\n", tablaSimbolos[i].eliminado);
	}

	fclose(tsFile);
}

void setNombreConstante(char * constante, char * nombreConstante) {
	strcpy(nombreConstante,"_");
	strcat(nombreConstante,constante);
}

/* Funciones de Polaca */

void agregarAPolaca(int indiceTS) {

	//FIXME Ámbito hardcodeado
	char mensajeAgregadoPolaca[200];
	sprintf(mensajeAgregadoPolaca,"--- POLACA --- Agregando indice %d",indiceTS);
	debugMessageString(mensajeAgregadoPolaca,tablaSimbolos[indiceTS].nombre);
	
	if(indiceTS!=-1) {
		polacaAgregar(&polacaInv,tablaSimbolos[indiceTS].nombre,tablaSimbolos[indiceTS].tipo);
	}
	else {
		// TODO Puede darse este caso? Es decir, que se llegue acá con un identificador que no esté en la TS
	}
}


void agregarOperacionAPolaca(char * operacion) {

	polacaAgregar(&polacaInv,operacion);

	debugMessageString("--- POLACA --- Agregando",operacion);
	
}