#define FILE_FUENTE "fuente.asm"

// FIXME Estamos definiendo dos veces las constantes!
#define LARGO_MAXIMO_NOMBRE_TOKEN 20
#define LARGO_MAXIMO_CTE_STRING 30

#define LIBERAR_COPRO "FFREE"

FILE * fuenteASM;

colaPolaca pilaOperandos;
struct colaPolaca * polaca;
struct elementoTablaSimbolos * elementosTS;
int cantidadElementosTS;
char ambito[30] = "main";

int indiceInicioMain = 0;

void setNombreVariableASM(char *, char *, char *);
void agregarOperandoColaDesdePolaca(struct elementoPolaca);
void agregarOperandoCola(char *, char);

void crearFuenteASM(struct colaPolaca * colaPolaca, struct elementoTablaSimbolos * tablaSimbolos, int cantidadElementosTablaSimbolos) {
	// FIXME No me gusta la forma en que se están declarando estas varibles globales, pero se complicaba pasar todos los parámetros siempre.
	polaca = colaPolaca;
	elementosTS = tablaSimbolos;
	cantidadElementosTS = cantidadElementosTablaSimbolos;

	crearArchivoASM();

	generarCodigoCabeceraASM();
	generarCodigoVariablesASM();
	
	generarCodigoInicioCodigoASM();
	generarCodigoRutinasASM();
	generarCodigoMainASM();
	generarCodigoFinCodigoASM();
}

void crearArchivoASM() {
	fuenteASM = fopen(FILE_FUENTE, "wt");
}

void generarCodigoCabeceraASM() {
	fprintf(fuenteASM,".MODEL	LARGE ;tipo de modelo de memoria usado\n");
	fprintf(fuenteASM,".386\n");
	fprintf(fuenteASM,".STACK 200h ; bytes en el stack\n\n");
}

void generarCodigoVariablesASM() {
	fprintf(fuenteASM,".DATA ; Comienzo de la zona de datos\n\n");
	
	fprintf(fuenteASM,"MAXTEXTSIZE equ %d\n\n", LARGO_MAXIMO_CTE_STRING);
	fprintf(fuenteASM,"_newline db 0Dh,0Ah,'$'\n");
	fprintf(fuenteASM,"MSG_PRESIONE_TECLA db 0DH,0AH, \"Presione una tecla para continuar...\",'$'\n");
	fprintf(fuenteASM,"AUX_STRING db MAXTEXTSIZE dup(?),'$'\n");	
	fprintf(fuenteASM, "AUX_NUMERO dd ?\n");

	for(int i = 0; i < cantidadElementosTS; i++) {
		struct elementoTablaSimbolos elementoTS = elementosTS[i];

		if(elementoTS.tipo != 'f') {
			char nombreASM[40];
			setNombreVariableASM(elementoTS.nombre, elementoTS.ambito, nombreASM);

			fprintf(fuenteASM, "%s ", nombreASM); // Seteo el nombre de la variable
			if(elementoTS.nombre[0] == '_') { // Si es una constante			
				switch(elementoTS.tipo) {
					case 'i': fprintf(fuenteASM, "dd %d\n", elementoTS.valorEntero); break;
					case 'r': fprintf(fuenteASM, "dd %f\n", elementoTS.valorReal); break;
					case 's': fprintf(fuenteASM, "db \"%s\",'$',%d dup (?)\n", elementoTS.valorString, LARGO_MAXIMO_CTE_STRING - strlen(elementoTS.valorString)); break;
				}
			} else { // Si es una variable
				switch(elementoTS.tipo) {
					case 'i': fprintf(fuenteASM, "dd ?\n"); break;
					case 'r': fprintf(fuenteASM, "dd ?\n"); break;
					case 's': fprintf(fuenteASM, "db MAXTEXTSIZE dup (?),'$'\n"); break;
				}
			}			
		}				
	}
	fprintf(fuenteASM,"\n\n");
}

void setNombreVariableASM(char * nombreOriginal, char * ambito, char * nombreASM) {
	strcpy(nombreASM, nombreOriginal);	
	strcat(nombreASM, "_");
	strcat(nombreASM, ambito);
}

void generarCodigoInicioCodigoASM() {
	fprintf(fuenteASM, ".CODE ; Comienzo de la zona de codigo\n\n");
}

void generarCodigoFinCodigoASM() {
	fprintf(fuenteASM, "mov ax, 4C00h ; Termina la ejecución.\n");
	fprintf(fuenteASM, "int 21h\n");
	fprintf(fuenteASM, "END MAIN; Final del archivo.\n");
}

void generarCodigoRutinasASM() {
	fprintf(fuenteASM,"; --- Comienzo de definición de Rutinas ---\n\n");
	generarCodigoRutinasEstandar();
	generarCodigoRutinasUsuario();
	fprintf(fuenteASM,"; --- Fin de definición de Rutinas ---\n\n");
}

void generarCodigoRutinasEstandar() {
	agregarRutinaStrlen();
	agregarRutinaCopiar();
	agregarRutinaConcat();
	agregarRutinaEsperarTecla();
	agregarRutinaNuevaLinea();
	agregarRutinaImprimirEntero();
}

void generarCodigoRutinasUsuario() {
	int indiceInicioFuncion = -1;
	int indiceFinFuncion = -1;
	
	indiceInicioFuncion = buscarInicioFuncion(0); // Busco en la polaca el inicio de la primer función.
	while(indiceInicioFuncion != -1) {
		indiceFinFuncion = buscarFinFuncion(indiceInicioFuncion); // Busco en la polaca el fin de la función actual.
		
		char nombreFuncion[LARGO_MAXIMO_NOMBRE_TOKEN];
		strcpy(nombreFuncion, polaca->elementos[indiceInicioFuncion + 1].elemento);
		
		fprintf(fuenteASM, "%s PROC\n", nombreFuncion); // Nombre Función				

		strcpy(ambito, nombreFuncion);
		generarCodigoRutina(indiceInicioFuncion + 2, indiceFinFuncion);

		fprintf(fuenteASM, "%s ENDP\n\n", nombreFuncion);
		indiceInicioFuncion = buscarInicioFuncion(indiceFinFuncion); // Busco en la polaca el inicio de la siguiente función.
		indiceInicioMain = indiceFinFuncion + 1; // Se setea en una variable global el inicio del main para evitar la declaración de funciones.
	} 
}

int buscarInicioFuncion(int inicioBusqueda) {
	for(int i = inicioBusqueda; i < polaca->cantidadElementosCola; i++) {
		if(!compareCaseInsensitive(polaca->elementos[i].elemento, "INIFUNCION")) {
			return i;
		}
	}
	return -1;
}

int buscarFinFuncion(int inicioBusqueda) {
	for(int i = inicioBusqueda; i < polaca->cantidadElementosCola; i++) {
		if(!compareCaseInsensitive(polaca->elementos[i].elemento, "FINFUNCION")) {
			return i;
		}
	}
	return -1;
}

void generarCodigoRutina(int inicioFuncion, int finFuncion) {
	for(int i = inicioFuncion; i < finFuncion; i++) {
		struct elementoPolaca elem = polaca->elementos[i];
		if(elem.tipo == 'o') { // Es operador
			agregarOperacion(elem);			
		} else { // Es operando
			agregarOperandoColaDesdePolaca(elem);
		}
	}
}

void generarCodigoMainASM() {
	fprintf(fuenteASM, "; --- Comienzo de programa principal ---\n\n");
	fprintf(fuenteASM, "MAIN:\n");
	fprintf(fuenteASM, "mov AX,@DATA ; Inicializa el segmento de datos\n");
	fprintf(fuenteASM, "mov DS,AX ;\n\n");
	strcpy(ambito, "main"); // Seteo ambito en "main".
	
	for(int i = indiceInicioMain; i < polaca->cantidadElementosCola; i++) {
		procesarElementoPolaca(polaca->elementos[i]);
	}

	fprintf(fuenteASM,"\n; --- Fin de programa principal ---\n\n");
}

void procesarElementoPolaca(struct elementoPolaca elemento) {
	if(elemento.tipo == 'o') { // Es operador
		agregarOperacion(elemento);			
	} else { // Es operando
		agregarOperandoColaDesdePolaca(elemento);
	}
}

void agregarOperacion(struct elementoPolaca operador) {
	if(!compareCaseInsensitive(operador.elemento, "=")) {
		asignacionASM();
	} else if(!compareCaseInsensitive(operador.elemento, "+")) {
		if(esOperacionEntreStrings()) {
			concatenacionStringsASM();
		} else {
			sumaASM();
		}	
	} else if(!compareCaseInsensitive(operador.elemento, "-")) {
		restaASM();
	} else if(!compareCaseInsensitive(operador.elemento, "*")) {
		multiplicacionASM();
	} else if(!compareCaseInsensitive(operador.elemento, "/")) {
		divisionASM();
	} else if(!compareCaseInsensitive(operador.elemento, "PRINT")) {
		imprimirASM();
	}
}

void agregarOperandoColaDesdePolaca(struct elementoPolaca operando) {
	// A la pila se agrega el operando con el nombre que tiene la variable en ASM.
	if(operando.tipo != 'f') {
		strcat(operando.elemento, "_");
		strcat(operando.elemento, ambito);
	}	
	colaEmpujar(&pilaOperandos, operando, -1);
}

void agregarOperandoCola(char * operando, char tipo) {
	polacaAgregar(&pilaOperandos, operando, tipo, -1);
}

int esOperacionEntreStrings() {
	// FIXME Esto me parece horrible como se hace, pero sino tenía que cambiar varias cosas.
	int indiceUltimoElemento = pilaOperandos.cantidadElementosCola - 1;
	if(pilaOperandos.elementos[indiceUltimoElemento].tipo == 's') {
		return 1;
	} else {
		return 0;
	}
}

void asignacionASM() {
	if(esOperacionEntreStrings()) {
		asignacionStringsASM();
	} else {
		asignacionNumericaASM();
	}	
}

void asignacionNumericaASM() {
	struct elementoPolaca operando;
	char aux[60], tipoDato;

	agregarAFuenteASM("; Asignacion");
	agregarAFuenteASM(LIBERAR_COPRO);
	
	colaSacar(&pilaOperandos, &operando);  // Saco 1er operando.
	tipoDato = operando.tipo;
	
	if(tipoDato == 'i') {
		strcpy(aux,"FILD ");
	} else {
		strcpy(aux,"FLD ");
	}
	
	strcat(aux, operando.elemento);		
	agregarAFuenteASM(aux);
	
	colaSacar(&pilaOperandos, &operando); // Saco 2do operando.
	validarOperando(operando, tipoDato);
	if(tipoDato == 'i') {
		strcpy(aux,"FISTP ");
	} else {
		strcpy(aux,"FSTP ");
	}	
	
	strcat(aux, operando.elemento);
	agregarAFuenteASM(aux);	
}

void asignacionStringsASM() {
	struct elementoPolaca operando1, operando2;
	char aux[60];
	
	agregarAFuenteASM("; Asignacion strings");
	
	colaSacar(&pilaOperandos, &operando1); // Saco 1er operando.	
	colaSacar(&pilaOperandos, &operando2); // Saco 2do operando.
	
	strcpy(aux, "MOV SI,OFFSET ");
	strcat(aux, operando1.elemento);
	agregarAFuenteASM(aux);
	
	strcpy(aux, "MOV DI,OFFSET ");
	strcat(aux, operando2.elemento);
	agregarAFuenteASM(aux);
	
	strcpy(aux,"CALL copiar");
	agregarAFuenteASM(aux);
}

void sumaASM() {
	struct elementoPolaca operando, operandoAux;
	char aux[60], tipoDato;
	
	agregarAFuenteASM("; Suma");
	agregarAFuenteASM(LIBERAR_COPRO);
	
	colaSacar(&pilaOperandos, &operando); // Saco 1er operando.
	tipoDato = operando.tipo;
	
	if(tipoDato == 'i') {
		strcpy(aux, "FILD ");
	} else {
		strcpy(aux, "FLD ");
	}
	strcat(aux, operando.elemento);
	agregarAFuenteASM(aux);
	
	colaSacar(&pilaOperandos, &operando); // Saco 2do operando.
	validarOperando(operando, tipoDato);
	
	if(tipoDato == 'i') {
		strcpy(aux, "FILD ");
	} else {
		strcpy(aux, "FLD ");
	}
	strcat(aux, operando.elemento);	
	agregarAFuenteASM(aux);	
	agregarAFuenteASM("FADD");
	
	if(tipoDato == 'i') {
		strcpy(aux,"FISTP ");
	} else {
		strcpy(aux,"FSTP ");
	}
		
	strcat(aux, "AUX_NUMERO");
	agregarAFuenteASM(aux);
	agregarOperandoCola("AUX_NUMERO", tipoDato);
}

void concatenacionStringsASM() {
	struct elementoPolaca operando1, operando2;
	char operador[100], aux[100];

	strcpy(aux,"; Concatenacion strings");
	agregarAFuenteASM(aux);
	
	colaSacar(&pilaOperandos, &operando1); // Saco 1er operando.
	colaSacar(&pilaOperandos, &operando2); // Saco 2do operando.

	agregarAFuenteASM("MOV AX, @DATA");
	agregarAFuenteASM("MOV ES,AX");
	
	strcpy(aux, "MOV SI,OFFSET ");
	strcat(aux, operando2.elemento);
	agregarAFuenteASM(aux);
	
	agregarAFuenteASM("MOV DI,OFFSET AUX_STRING");
	agregarAFuenteASM("CALL COPIAR");
	
	strcpy(aux, "MOV SI,OFFSET ");
	strcat(aux, operando1.elemento);
	agregarAFuenteASM(aux);
	
	agregarAFuenteASM("MOV DI,OFFSET AUX_STRING");
	agregarAFuenteASM("CALL CONCAT");
	
	agregarOperandoCola("AUX_STRING", 's');
}

void restaASM() {

}

void multiplicacionASM() {

}

void divisionASM() {

}

void imprimirASM() {
	if(esOperacionEntreStrings()) {
		imprimirStringASM();
	} else {
		imprimirNumeroEnteroASM();
	}	
}

void imprimirStringASM() {
	struct elementoPolaca operando;
	char aux[100];
	
	agregarAFuenteASM("; Impresion de string");
	
	colaSacar(&pilaOperandos, &operando); // Saco operando.
	strcpy(aux, "MOV DX, OFFSET ");
	strcat(aux, operando.elemento);
	agregarAFuenteASM(aux);
	
	strcpy(aux, "MOV AH, 9");
	agregarAFuenteASM(aux);
	
	strcpy(aux, "INT 21h");
	agregarAFuenteASM(aux);	
	
	agregarAFuenteASM("CALL NEWLINE");
}

void imprimirNumeroEnteroASM() {
	struct elementoPolaca operando;
	char aux[100];
	
	agregarAFuenteASM("; Impresion de numero");
	
	colaSacar(&pilaOperandos, &operando); // Saco operando.
	strcpy(aux, "MOV eax,");
	strcat(aux, operando.elemento);	
	agregarAFuenteASM(aux);
	
	strcpy(aux, "CALL IMPRIMIR_ENTERO");	
	agregarAFuenteASM(aux);
}

void validarOperando(struct elementoPolaca operando, char tipoDato) {
	if(operando.tipo != tipoDato) {
		compilationError("Las operaciones deben hacerse con operandos del mismo tipo");
	}
}

/* Rutinas estándar */
void agregarRutinaStrlen() {
	fprintf(fuenteASM,
	"; Rutina STRLEN: devuelve en BX la cantidad de caracteres que tiene un string\n"
	"; DS:SI apunta al string.\n"
	"STRLEN PROC\n"
	"	mov bx,0\n"
	"STRL01:\n"
	"	cmp BYTE PTR [SI+BX],'$'\n"
	"	je STREND\n"
	"	inc BX\n"
	"	jmp STRL01\n"
	"STREND:\n"
	"	ret\n"
	"STRLEN ENDP\n\n");
}

void agregarRutinaCopiar() {
	fprintf(fuenteASM,
	"; Rutina COPIAR: copia DS:SI a ES:DI; busca la cantidad de caracteres\n"
	"COPIAR PROC\n"
	"	call STRLEN ; busco la cantidad de caracteres\n"
	"	cmp bx,MAXTEXTSIZE\n"
	"	jle COPIARSIZEOK\n"
	"	mov bx,MAXTEXTSIZE\n"
	"COPIARSIZEOK:\n"
	"	mov cx,bx ; la copia se hace de 'CX' caracteres\n"
	"	cld ; cld es para que la copia se realice hacia adelante\n"
	"	rep movsb ; copia la cadea\n"
	"	mov al,'$' ; carácter terminador\n"
	"	mov BYTE PTR [DI],al ; el registro DI quedo apuntando al final\n"
	"	ret\n"
	"COPIAR ENDP\n\n"
	);
}

void agregarRutinaConcat() {
	fprintf(fuenteASM,
	"; Rutina CONCAT: concatena DS:SI al final de ES:DI.\n"
	"; busco el size del primer string\n"
	"; sumo el size del segundo string\n"
	"; si la suma excede MAXTEXTSIZE, copio solamente MAXTEXTSIZE caracteres\n"
	"; si la suma NO excede MAXTEXTSIZE, copio el total de caracteres que tiene el segundo string\n"
	"CONCAT PROC\n"
	"	push ds\n"
	"	push si\n"
	"	call STRLEN ; busco la cantidad de caracteres del 2do string\n"
	"	mov dx,bx ; guardo en DX la cantidad de caracteres en el origen.\n"
	"	mov si,di\n"
	"	push es\n"
	"	pop ds\n"
	"	call STRLEN ; tamanio del 1er string\n"
	"	add di,bx ; DI ya queda apuntando al final del primer string\n"
	"	add bx,dx ; tamanio total\n"
	"	cmp bx,MAXTEXTSIZE ; excede el tama#o maximo?\n"
	"	jg CONCATSIZEMAL\n"
	
	"CONCATSIZEOK: ; La suma no excede el maximo, copio todos\n"
	"	mov cx,dx ; los caracteres del segundo string.\n"
	"	jmp CONCATSIGO\n"
	"CONCATSIZEMAL: ; La suma de caracteres de los 2 strings exceden el maximo\n"
	"	sub bx,MAXTEXTSIZE\n"
	"	sub dx,bx\n"
	"	mov cx,dx ; copio lo maximo permitido el resto se pierde.\n"
	"CONCATSIGO:\n"
	"	push ds\n"
	"	pop es\n"
	"	pop si\n"
	"	pop ds\n"
	"	cld ; cld es para que la copia se realice hacia adelante\n"
	"	rep movsb ; copia la cadea\n"
	"	mov al,'$' ; carácter terminador\n"
	"	mov BYTE PTR [DI],al ; el registro DI quedo apuntando al final\n"
	"	ret\n"
	"CONCAT ENDP\n\n"
	);
}

void agregarRutinaEsperarTecla() {
	fprintf(fuenteASM,
	"; Rutina ESPERA_TECLA\n"
	"; A la espera de una tecla\n"
	"ESPERA_TECLA PROC\n"
	"	mov dx,OFFSET MSG_PRESIONE_TECLA\n"
	"	mov ah,09\n"
	"	int 21h\n"
	"	mov DX, OFFSET _newline\n"
	"	mov ah,09\n"
	"	int 21h\n"
	"	mov ah,1\n"
	"	int 21h\n"
	"	ret\n"
	"ESPERA_TECLA ENDP\n\n"
	);
}

void agregarRutinaNuevaLinea() {
	fprintf(fuenteASM,
	"NEWLINE PROC\n"
	"	push dx\n"
	"	push eax\n"
	"	mov DX, OFFSET _newline\n"
	"	mov ah,09\n"
	"	int 21h\n"
	"	pop eax\n"
	"	pop dx\n"
	"	ret\n"
	"NEWLINE ENDP\n\n"
	);
}

void agregarRutinaImprimirEntero() {
   fprintf(fuenteASM,
		"IMPRIMIR_ENTERO PROC\n"
		"	push eax\n"
		"	push ebx\n"
		"	push ecx\n"
		"	push edx\n"
		"	xor	ecx,ecx\n"
		"	mov	ebx,10d\n"
		"imp_dec_loop1:\n"
		"	xor	edx,edx\n"
		"	div	ebx\n"
		"	push edx\n"
		"	inc	ecx\n"
		"	cmp	eax,0\n"
		"	jnz	imp_dec_loop1\n"
		"	mov	ah,02\n"
		"imp_dec_loop2:\n"
		"	pop	edx\n"
		"	add dl,48D\n"
		"	int	21h\n"
		"	dec	ecx\n"
		"	jnz	imp_dec_loop2 \n"
		"	pop edx\n"
		"	pop ecx\n"
		"	pop ebx\n"
		"	pop eax\n"
		"	CALL NEWLINE\n"
		"	ret\n"
		"IMPRIMIR_ENTERO ENDP\n\n");
}

void agregarAFuenteASM(char * cadena) {
	fprintf(fuenteASM, "	%s\n", cadena);
}
