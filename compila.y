%{
#include <stdio.h>
%}

/* Tokens - Reglas AL */
%token OP_DECLARACION SEPARADOR_DEC FIN_DEC SEPARADOR_GRUPO_VARIABLES
%token OP_COMPARACION OP_LOGICO_PRE OP_LOGICO OP_ASIGNACION
%token OP_SUMA OP_RESTA OP_MULTIPLICACION OP_DIVISION  OP_CONCATENACION 
%token P_ABRE P_CIERRE I_CONDICIONAL I_FINCONDICIONAL I_BUCLE I_FINBUCLE
%token I_PROG I_FINPROG INI_FUNCION FIN_FUNCION
%token DELIMITADOR_STRING SEPARADOR_DECIMALES
%token TIPO_DATO
%token ID_VAR
%token CONST_STRING CONST_REAL CONST_ENTERA
%token I_PROG_PRINCIPAL I_FIN_PROG_PRINCIPAL
/*OP_DECLARACION    :    DEC;
SEPARADOR_DEC     :    :;
FIN_DEC    :    ENDEC;
SEPARADOR_GRUPO_VARIABLES     :    ,;
OP_COMPARACION    :    < | 
> | 
<= | 
>= | 
!= | 
== ;
OP_LOGICO_PRE    :    NOT;
OP_LOGICO    :    AND |
            OR ;
OP_ASIGNACION    :    = ;
OP_SUMA    :    + ;
OP_RESTA    :    - ;
OP_MULTIPLICACION    :    * ;
OP_DIVISION    :    / ;
OP_CONCATENACION    :    +;
P_ABRE    :    ( ;
P_CIERRE    :    ) ;
I_CONDICIONAL    :    IF;
I_FINCONDICIONAL    :    ENDIF;
I_BUCLE    :    WHILE;
I_FINBUCLE    :    ENDWHILE;
I_PROG_PRINCIPAL    :    MAIN;
I_FIN_PROG_PRINCIPAL    :    ENDMAIN;
I_FINPROG    :    END;
I_PROG    :    BEGIN;
I_FINPROG    :    END;
DELIMITADOR_STRING    :    “;
SEPARADOR_DECIMALES    :    .;
INI_FUNCION    :    FUNCTION;
FIN_FUNCION    :    RETURN;
TIPO_DATO    :    REAL | INT;
constante_str    :    DELIMITADOR_STRING cadena_str DELIMITADOR_STRING;
ID_VAR    :     :    letra | letra cadena_str;
cadena_str    :    caracter | 
cadena_str caracter;
caracter    :    letra | numero | caracter_especial;
letra        :    a | b | c | d | e | f | g | h | i | j | k | l | m | n | o | p | q | r | s | t | u | v | w | x | y | z |
            A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X |
Y | Z ;
caracter_especial:    @ | % | & | / | : | , | “ ;
numero        :    0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9;
constante_real    :    constante_entera SEPARADOR_DECIMALES constante_entera |
SEPARADOR_DECIMALES constante_entera |
constante_entera SEPARADOR_DECIMALES;
constante_entera :    numero | constante_entera numero;
*/

/* Start Symbol */
%start PRG;

/* Reglas AS */
%%
PRG    :  I_PROG lista_funciones bloque_principal lista_funciones I_FINPROG |
        I_PROG lista_funciones bloque_principal  I_FINPROG |
        I_PROG  bloque_principal lista_funciones I_FINPROG | 
 I_PROG  bloque_principal I_FINPROG ;
lista_funciones    :    funcion | lista_funciones funcion;
bloque_principal    :    I_PROG_PRINCIPAL bloque I_FIN_PROG_PRINCIPAL ;
bloque    :    sentencia |
        bloque sentencia ;
funcion    :    INI_FUNCION declaracion_funcion bloque FIN_FUNCION;
declaracion_funcion    :    ID_VAR SEPARADOR_DEC TIPO_DATO;
sentencia    :    declaracion |
asignacion |
            condicional |
            bucle;
declaracion    :    OP_DECLARACION TIPO_DATO SEPARADOR_DEC grupo_variables FIN_DEC;
grupo_variables    :    ID_VAR | ID_VAR SEPARADOR_GRUPO_VARIABLES grupo_variables;
asignacion    :    ID_VAR OP_ASIGNACION mult_asignacion |
ID_VAR OP_ASIGNACION concatenacion;
mult_asignacion    :    expresion | expresion OP_ASIGNACION mult_asignacion; /*asig multiple??*/
expresion    :    termino | expresion OP_SUMA termino | expresion OP_RESTA termino ;
termino    :    factor | termino OP_MULTIPLICACION factor | termino OP_DIVISION factor;
factor    :    constante_numerica | ID_VAR;
concatenacion    :    cadena_caracteres OP_CONCATENACION cadena_caracteres;
bucle    :    I_BUCLE condicion bloque I_FINBUCLE;
condicional    :    I_CONDICIONAL condicion bloque I_FINCONDICIONAL ;
condicion    :    P_ABRE comparacion P_CIERRE |
            P_ABRE comparacion OP_LOGICO comparacion P_CIERRE ;
comparacion    :    elemento OP_COMPARACION elemento  |
OP_LOGICO_PRE elemento OP_COMPARACION elemento;
cadena_caracteres     :    CONST_STRING | ID_VAR;
elemento    :    CONST_STRING |
constante_numerica |
ID_VAR;
constante_numerica    :    CONST_REAL |     
CONST_ENTERA;
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
