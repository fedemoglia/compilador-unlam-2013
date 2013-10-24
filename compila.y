%{
#include <stdio.h>
#include <ctype.h>
/*#include <conio.h>*/
#include <stdlib.h>
#include <string.h>
#include "tablaSimbolos.h"
#define CANTIDAD_ESTADOS 24
#define CANTIDAD_CARACTERES 19
#define LARGO_MAXIMO_NOMBRE_TOKEN 20
#define CANT_PALABRAS_RESERVADAS 20



%}

/* Tokens - Reglas AL */
%token OP_DECLARACION SEPARADOR_DEC FIN_DEC SEPARADOR_GRUPO_VARIABLES
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
PRG	: I_PROG  bloque_principal lista_funciones I_FINPROG |
 I_PROG  bloque_principal I_FINPROG ;
lista_funciones    :    funcion | lista_funciones funcion;
bloque_principal    :    I_PROG_PRINCIPAL bloque I_FIN_PROG_PRINCIPAL ;
bloque	:	lista_sentencias | bloque_declaraciones lista_sentencias;

lista_sentencias : sentencia | lista_sentencias sentencia;

bloque_declaraciones : OP_DECLARACION { abreBloqueDeclaracion(); } grupo_declaraciones  FIN_DEC { cierraBloqueDeclaracion(); } ;
grupo_declaraciones : declaracion | grupo_declaraciones declaracion;
declaracion	:	 tipo { configurarTipoVariableDeclarada($1); } grupo_variables ;
tipo	: 	TIPO_DATO_INT | TIPO_DATO_REAL | TIPO_DATO_STRING;
funcion	:	INI_FUNCION declaracion_funcion bloque FIN_FUNCION;
declaracion_funcion	:	ID_VAR SEPARADOR_DEC tipo;
sentencia	:	asignacion |
			condicional |
			bucle |
			output ;
grupo_variables	:	ID_VAR | ID_VAR SEPARADOR_GRUPO_VARIABLES grupo_variables;
asignacion	:	ID_VAR OP_ASIGNACION mult_asignacion  {
	printf("Asignacion: IndiceTS %d = IndiceTS %d\n",$1,$3); 
	};
mult_asignacion	:	expresion | expresion OP_ASIGNACION mult_asignacion {
printf("Asignacion (mult): IndiceTS %d = IndiceTS %d\n",$1,$3); 
	};
expresion	:	termino | expresion OP_SUMA termino {

	printf("Suma: IndiceTS %d = IndiceTS %d\n",$1,$3); 
	
}
| expresion OP_RESTA termino {

	printf("Resta: IndiceTS %d = IndiceTS %d\n",$1,$3); 
	

};
termino	:	factor | termino OP_MULTIPLICACION factor { 
{
	printf("Multiplicacion: IndiceTS %d = IndiceTS %d\n",$1,$3); 
	}
	;}
| termino OP_DIVISION factor {
{
	printf("División: IndiceTS %d = IndiceTS %d\n",$1,$3); 
	};
}
;
factor	:	P_ABRE expresion P_CIERRE | constante_numerica | ID_VAR | CONST_STRING;
bucle	:	I_BUCLE condicion bloque I_FINBUCLE ;
condicional	:	I_CONDICIONAL condicion bloque I_FINCONDICIONAL ;
condicion	:	P_ABRE comparacion P_CIERRE |
			P_ABRE comparacion operador comparacion P_CIERRE ;
operador	: 	OP_LOGICO_AND | OP_LOGICO_OR;
comparacion	:	elemento OP_COMPARACION elemento {
 printf("Comparacion: %d con %d (comparacion %d)\n",$1,$3,$2);};
 
 |
OP_LOGICO_PRE elemento OP_COMPARACION elemento { 
	printf("Comparacion negada: %d con %d (comparacion %d)\n",$2,$4,$3);};
output		:	INST_IMPRIMIR P_ABRE cadena_caracteres P_CIERRE {
	printf("Output: %d\n",$3);
 };
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

int cantidadElementosTablaSimbolos=0;
struct elementoTablaSimbolos tablaSimbolos[1000];

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
	{initId,initCte,initCte,initCadena,separadorDec,opSuma,opResta,opMultiplicacion,opDivision,opComparacion,opComparacion,opAsignacion,nada,parentesisAbre,parentesisCierra,nada,nada,nada,finArch},
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
	"percent", PORCENTAJE
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

void abreBloqueDeclaracion() {
	
	debugMessage("---- Abre Bloque Declaraciones ----");
	bloqueDeclaracionesActivo='y';
}

void cierraBloqueDeclaracion() {
	debugMessage("---- Cierra Bloque Declaraciones ----\n");
	bloqueDeclaracionesActivo='n';
}

void configurarTipoVariableDeclarada(int idTokenTipoVariable) {
	switch(idTokenTipoVariable) {
		case TIPO_DATO_INT: tipoVariableDeclarada='e'; break;
		case TIPO_DATO_REAL: tipoVariableDeclarada='r'; break;
		case TIPO_DATO_STRING: tipoVariableDeclarada='s'; break;
	}
	debugMessageInt("--- Configurado tipo de variable --- ",idTokenTipoVariable);
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
        if(!strcmp(palabrasReservadas[i++].palabra,c))
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
	
	debugMessageString("Identificador leido",palabraLeida);
		
	
	// si es una palabra reservada
	if(indicePalabraReservada != -1) {
		debugMessageInt("INFO finId: Indice Palabra Reservada", indicePalabraReservada);
		tokenIdentificado = palabrasReservadas[indicePalabraReservada-1].valor;
	} else {
		/* Si no es una palabra reservada, la busca en la tabla de simbolos */
	
		// FIXME Habría que cambiar el ambito que está fijado
		int indicePalabraEnTablaDeSimbolos = buscarEnTS("main",palabraLeida,tablaSimbolos,cantidadElementosTablaSimbolos);
		
		if(indicePalabraEnTablaDeSimbolos==-1) {
			debugMessageString("Identificador no encontrado en tabla de símbolos",palabraLeida);
			if(bloqueDeclaracionesActivo=='y') {
				// Si la palabra no está en la tabla de símbolos y estamos en bloque de declaraciones, crearla.
				// FIXME El ámbito y el tipo están fijados
				cantidadElementosTablaSimbolos= agregarEnTS("main", 's', palabraLeida, "VALOR", tablaSimbolos, cantidadElementosTablaSimbolos);
				yylval = cantidadElementosTablaSimbolos;
				debugMessageString("Agregando a tabla de símbolos",palabraLeida);
			}
			else {
				debugMessageString("Error, se intento usar el identificador antes de definirlo",palabraLeida);
			}
		}
		else {
			debugMessageInt("Indice en tabla de símbolos",indicePalabraEnTablaDeSimbolos);
			yylval = indicePalabraEnTablaDeSimbolos;
			}
		tokenIdentificado = ID_VAR;
	}
}

void initCte() {

}

void contCte() {

}

void finCteEntera() {
	tokenIdentificado = CONST_ENTERA;
	
	/* Incompleto. Hay que pensar esto ...
	char nombreConstante[LARGO_MAXIMO_NOMBRE_TOKEN+1] ;
	strcpy(nombreConstante,"_");
	strcat(nombreConstante,palabraLeida);
	int valorConstante=atoi(palabraLeida);

	cantidadElementosTablaSimbolos
	palabraLeida */
	
	yylval=99999;

	}

void finCteReal() {
	tokenIdentificado = CONST_REAL;
	
	yylval=99998;
}

void initCadena() {

}

void contCadena() {

}

void finCadena() {
	tokenIdentificado = CONST_STRING;
	
	yylval=99997;
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
