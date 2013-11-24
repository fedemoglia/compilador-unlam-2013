#define FILE_FUENTE "fuente.asm"
#define FILE_VARIABLES "variables.asm"
#define FILE_CODIGO "codigo.asm"

// FIXME Estamos definiendo dos veces las constantes!
#define TRUE 1
#define FALSE 0
#define LARGO_MAXIMO_NOMBRE_TOKEN 20
#define LARGO_MAXIMO_CTE_STRING 30

#define LIBERAR_COPRO "FFREE"

FILE * variablesASM;
FILE * codigoASM;
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
	ensamblarArchivoASM();
}

void crearArchivoASM() {
	codigoASM = fopen(FILE_CODIGO, "wt");
}

void generarCodigoCabeceraASM() {
	variablesASM = fopen(FILE_VARIABLES, "wt");
	fprintf(variablesASM,".MODEL	LARGE ;tipo de modelo de memoria usado\n");
	fprintf(variablesASM,".386\n");
	fprintf(variablesASM,".STACK 200h ; bytes en el stack\n\n");
}

void generarCodigoVariablesASM() {
	fprintf(variablesASM,".DATA ; Comienzo de la zona de datos\n\n");
	
	generarCodigoVariablesParaUsoGeneral();
	generarCodigoVariablesDesdeTablaDeSimbolos();
	
	fclose(variablesASM);
}

void generarCodigoVariablesParaUsoGeneral() {	
	fprintf(variablesASM,"MAXTEXTSIZE equ %d\n\n", LARGO_MAXIMO_CTE_STRING);
	fprintf(variablesASM,"_newline db 0Dh,0Ah,'$'\n");
	fprintf(variablesASM,"MSG_PRESIONE_TECLA db 0DH,0AH, \"Presione una tecla para continuar...\",'$'\n");
	fprintf(variablesASM, "_100 dd 100\n");
	
	// FIXME Variables auxiliares (esto se debe reemplazar por las auxiliares generadas dinámicamente).
	fprintf(variablesASM,"AUX_STRING db MAXTEXTSIZE dup(?),'$'\n");	
	fprintf(variablesASM, "AUX_NUMERO dd ?\n");
	
	fprintf(variablesASM, "AUX_FUNCION_NUMERO dd ?\n"); // Variable auxiliar para retorno de funciones numéricas.
	fprintf(variablesASM, "AUX_FUNCION_STRING db MAXTEXTSIZE dup(?),'$'\n");	// Variable auxiliar para retorno de funciones string.
}

void generarCodigoVariablesDesdeTablaDeSimbolos() {
	for(int i = 0; i < cantidadElementosTS; i++) {
		struct elementoTablaSimbolos elementoTS = elementosTS[i];

		if(elementoTS.tipo != 'f') {
			char nombreASM[40];
			setNombreVariableASM(elementoTS.nombre, elementoTS.ambito, nombreASM);

			fprintf(variablesASM, "%s ", nombreASM); // Seteo el nombre de la variable
			if(elementoTS.nombre[0] == '_') { // Si es una constante			
				switch(elementoTS.tipo) {
					case 'i': fprintf(variablesASM, "dd %d\n", elementoTS.valorEntero); break;
					case 'r': fprintf(variablesASM, "dd %f\n", elementoTS.valorReal); break;
					case 's': fprintf(variablesASM, "db \"%s\",'$',%d dup (?)\n", elementoTS.valorString, LARGO_MAXIMO_CTE_STRING - strlen(elementoTS.valorString)); break;
				}
			} else { // Si es una variable
				switch(elementoTS.tipo) {
					case 'i': fprintf(variablesASM, "dd ?\n"); break;
					case 'r': fprintf(variablesASM, "dd ?\n"); break;
					case 's': fprintf(variablesASM, "db MAXTEXTSIZE dup (?),'$'\n"); break;
				}
			}			
		}				
	}
	fprintf(variablesASM,"\n\n");
}

void setNombreVariableASM(char * nombreOriginal, char * ambito, char * nombreASM) {
	strcpy(nombreASM, nombreOriginal);	
	strcat(nombreASM, "_");
	strcat(nombreASM, ambito);
}

void generarCodigoInicioCodigoASM() {
	fprintf(codigoASM, ".CODE ; Comienzo de la zona de codigo\n\n");
}

void generarCodigoFinCodigoASM() {
	fprintf(codigoASM, "MOV ax, 4C00h ; Termina la ejecución.\n");
	fprintf(codigoASM, "int 21h\n");
	fprintf(codigoASM, "END MAIN; Final del archivo.\n");
	fclose(codigoASM);
}

void generarCodigoRutinasASM() {
	fprintf(codigoASM,"; --- Comienzo de definición de Rutinas ---\n\n");
	generarCodigoRutinasEstandar();
	generarCodigoRutinasUsuario();
	fprintf(codigoASM,"; --- Fin de definición de Rutinas ---\n\n");
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
		strcpy(ambito, nombreFuncion);		
		
		generarCodigoRutina(indiceInicioFuncion + 2, indiceFinFuncion, nombreFuncion);
		
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

void generarCodigoRutina(int inicioFuncion, int finFuncion, char * nombreFuncion) {
	fprintf(codigoASM, "%s PROC\n", nombreFuncion); // Nombre Función
	agregarAcodigoASM("MOV DX,DI");

	for(int i = inicioFuncion; i < finFuncion; i++) {
		procesarElementoPolaca(polaca->elementos[i]);
	}
	
	fprintf(codigoASM, "%s ENDP\n\n", nombreFuncion);
}

void generarCodigoMainASM() {
	fprintf(codigoASM, "; --- Comienzo de programa principal ---\n\n");
	fprintf(codigoASM, "MAIN:\n");
	fprintf(codigoASM, "MOV AX,@DATA ; Inicializa el segmento de datos\n");
	fprintf(codigoASM, "MOV DS,AX ;\n");
	fprintf(codigoASM, "MOV ES,AX ;\n\n");
	strcpy(ambito, "main"); // Seteo ambito en "main".
	
	for(int i = indiceInicioMain; i < polaca->cantidadElementosCola; i++) {
		procesarElementoPolaca(polaca->elementos[i]);
	}

	fprintf(codigoASM,"\n; --- Fin de programa principal ---\n\n");
}

void procesarElementoPolaca(struct elementoPolaca elemento) {
	if(elemento.tipo == 'o') { // Es operador
		agregarOperacion(elemento);			
	} else { // Es operando
		formatearNombreOperandoASM(&elemento);
		agregarOperandoColaDesdePolaca(elemento);
	}
}

void agregarOperacion(struct elementoPolaca operador) {
	if(!compareCaseInsensitive(operador.elemento, "=")) {
		asignacionASM(FALSE);		
	} else if (!compareCaseInsensitive(operador.elemento, ":=")) {
		asignacionASM(TRUE);		
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
	} else if(!compareCaseInsensitive(operador.elemento, "PERCENT")) {
		percentASM();
	}  else if(!compareCaseInsensitive(operador.elemento, "CALL")) {
		ejecutarProcedimientoUsuarioASM();
	}  else if(!compareCaseInsensitive(operador.elemento, "RETURN")) {
		retornoDeFuncionASM();
	}
}

void formatearNombreOperandoASM(struct elementoPolaca * operando) {
	// A la pila se agrega el operando con el nombre que tiene la variable en ASM.
	if(operando->tipo != 'f') {
		strcat(operando->elemento, "_");
		strcat(operando->elemento, ambito);
	}
}

void agregarOperandoColaDesdePolaca(struct elementoPolaca operando) {
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

char getTipoDatoPrimerOperandoCola() {
	return getTipoDatoOperando(pilaOperandos.elementos[pilaOperandos.cantidadElementosCola - 1]);
}

void asignacionASM(int multipleAsignacion) {
	if(esOperacionEntreStrings()) {
		asignacionStringsASM(multipleAsignacion);
	} else {
		asignacionNumericaASM(multipleAsignacion);
	}	
}

void asignacionNumericaASM(int multipleAsignacion) {
	struct elementoPolaca operando;
	char aux[60], instruccionCargaCopro[10], instruccionCopiaMemoria[10], tipoDato;

	agregarAcodigoASM("; Asignacion");
	agregarAcodigoASM(LIBERAR_COPRO);
	
	colaSacar(&pilaOperandos, &operando);  // Saco 1er operando.
	tipoDato = getTipoDatoOperando(operando);
	
	// Seteo instrucciones ASM según tipo de dato.
	setInstruccionCargaDatoEnCopro(instruccionCargaCopro, tipoDato);
	setInstruccionCopiaAMemoriaDesdeCopro(instruccionCopiaMemoria, tipoDato);
	
	// Cargo el valor a asignar.
	strcpy(aux, instruccionCargaCopro);
	strcat(aux, operando.elemento);		
	agregarAcodigoASM(aux);
	
	colaSacar(&pilaOperandos, &operando); // Saco 2do operando.
	validarOperando(operando, tipoDato);
	
	// Guardo el valor en la variable correspondiente.
	strcpy(aux, instruccionCopiaMemoria);
	strcat(aux, operando.elemento);
	agregarAcodigoASM(aux);	
	
	// Si hay una asignación múltiple necesito cargar el último operando nuevamente en la cola.
	if(multipleAsignacion == TRUE) {
		agregarOperandoColaDesdePolaca(operando);
	}
}

void asignacionStringsASM(int multipleAsignacion) {
	struct elementoPolaca operando1, operando2;
	char aux[60];
	
	agregarAcodigoASM("; Asignacion strings");
	
	colaSacar(&pilaOperandos, &operando1); // Saco 1er operando.	
	colaSacar(&pilaOperandos, &operando2); // Saco 2do operando.
	validarOperando(operando2, 's');
	
	strcpy(aux, "MOV SI,OFFSET ");
	strcat(aux, operando1.elemento);
	agregarAcodigoASM(aux);
	
	strcpy(aux, "MOV DI,OFFSET ");
	strcat(aux, operando2.elemento);
	agregarAcodigoASM(aux);
	
	strcpy(aux,"CALL COPIAR");
	agregarAcodigoASM(aux);
	
	// Si hay una asignación múltiple necesito cargar el último operando nuevamente en la cola.
	if(multipleAsignacion == TRUE) {
		agregarOperandoColaDesdePolaca(operando2);
	}
}

void sumaASM() {
	struct elementoPolaca operando, operandoAux;
	char aux[60], instruccionCargaCopro[10], instruccionCopiaMemoria[10], tipoDato;
	
	agregarAcodigoASM("; Suma");
	agregarAcodigoASM(LIBERAR_COPRO);
	
	colaSacar(&pilaOperandos, &operando); // Saco 1er operando.
	tipoDato = getTipoDatoOperando(operando);
	
	// Seteo instrucciones ASM según tipo de dato.
	setInstruccionCargaDatoEnCopro(instruccionCargaCopro, tipoDato);
	setInstruccionCopiaAMemoriaDesdeCopro(instruccionCopiaMemoria, tipoDato);
	
	// Cargo 1er operando.
	strcpy(aux, instruccionCargaCopro);
	strcat(aux, operando.elemento);
	agregarAcodigoASM(aux);
	
	colaSacar(&pilaOperandos, &operando); // Saco 2do operando.
	validarOperando(operando, tipoDato);
	
	// Cargo 2do operando.
	strcpy(aux, instruccionCargaCopro);
	strcat(aux, operando.elemento);		
	agregarAcodigoASM(aux);	
	
	// Ejecuto la suma
	agregarAcodigoASM("FADD");
	
	// Guardo el resultado.
	strcpy(aux, instruccionCopiaMemoria);
	strcat(aux, "AUX_NUMERO");
	agregarAcodigoASM(aux);
	agregarOperandoCola("AUX_NUMERO", tipoDato);
}

void concatenacionStringsASM() {
	struct elementoPolaca operando1, operando2;
	char operador[100], aux[100];

	strcpy(aux,"; Concatenacion strings");
	agregarAcodigoASM(aux);
	
	colaSacar(&pilaOperandos, &operando1); // Saco 1er operando.
	colaSacar(&pilaOperandos, &operando2); // Saco 2do operando.
	validarOperando(operando2, 's');

	agregarAcodigoASM("MOV AX, @DATA");
	agregarAcodigoASM("MOV ES,AX");
	
	strcpy(aux, "MOV SI,OFFSET ");
	strcat(aux, operando2.elemento);
	agregarAcodigoASM(aux);
	
	agregarAcodigoASM("MOV DI,OFFSET AUX_STRING");
	agregarAcodigoASM("CALL COPIAR");
	
	strcpy(aux, "MOV SI,OFFSET ");
	strcat(aux, operando1.elemento);
	agregarAcodigoASM(aux);
	
	agregarAcodigoASM("MOV DI,OFFSET AUX_STRING");
	agregarAcodigoASM("CALL CONCAT");
	
	agregarOperandoCola("AUX_STRING", 's');
}

void restaASM() {
	struct elementoPolaca operando1, operando2;
	char aux[100], instruccionCargaCopro[10], instruccionCopiaMemoria[10], tipoDato;	
	
	agregarAcodigoASM("; Resta");
	agregarAcodigoASM(LIBERAR_COPRO);
	
	colaSacar(&pilaOperandos, &operando1); // Saco 1er operando.
	colaSacar(&pilaOperandos, &operando2); // Saco 2do operando.
	
	tipoDato = getTipoDatoOperando(operando1);
	validarOperando(operando2, tipoDato);
	
	// Seteo instrucciones ASM según tipo de dato.
	setInstruccionCargaDatoEnCopro(instruccionCargaCopro, tipoDato);
	setInstruccionCopiaAMemoriaDesdeCopro(instruccionCopiaMemoria, tipoDato);

	// Cargo 2do operando.
	strcpy(aux, instruccionCargaCopro);
	strcat(aux, operando2.elemento);
	agregarAcodigoASM(aux);

	// Cargo 1er operando.
	strcpy(aux, instruccionCargaCopro);
	strcat(aux, operando1.elemento);
	agregarAcodigoASM(aux);	
	
	// Ejecuto la resta
	agregarAcodigoASM("FSUB");
	
	// Guardo resultado en aux.
	strcpy(aux, instruccionCopiaMemoria);
	strcat(aux, "AUX_NUMERO");
	agregarAcodigoASM(aux);
	agregarOperandoCola("AUX_NUMERO", tipoDato);	
}

void multiplicacionASM() {
	struct elementoPolaca operando;
	char aux[100], instruccionCargaCopro[10], instruccionCopiaMemoria[10], tipoDato;	
	
	agregarAcodigoASM("; Multiplicacion");	
	agregarAcodigoASM(LIBERAR_COPRO);	
	
	colaSacar(&pilaOperandos, &operando); // Saco 1er operando.
	tipoDato = getTipoDatoOperando(operando);	
	// Seteo instrucciones ASM según tipo de dato.
	setInstruccionCargaDatoEnCopro(instruccionCargaCopro, tipoDato);
	setInstruccionCopiaAMemoriaDesdeCopro(instruccionCopiaMemoria, tipoDato);
	
	// Cargo 1er operando.
	strcpy(aux, instruccionCargaCopro);
	strcat(aux, operando.elemento);	
	agregarAcodigoASM(aux);
		
	// Cargo 2do operando.
	colaSacar(&pilaOperandos, &operando);
	validarOperando(operando, tipoDato);	
	strcpy(aux, instruccionCargaCopro);
	strcat(aux, operando.elemento);	
	agregarAcodigoASM(aux);
	
	// Ejecuto la multiplicacion.
	strcpy(aux, "FMUL");
	agregarAcodigoASM(aux);

	// Guardo el resultado.
	strcpy(aux, instruccionCopiaMemoria);
	strcat(aux, "AUX_NUMERO");	
	agregarAcodigoASM(aux);	
	agregarOperandoCola("AUX_NUMERO", tipoDato);
}

void divisionASM() {
	struct elementoPolaca operando1, operando2;
	char aux[100], instruccionCargaCopro[10], instruccionCopiaMemoria[10], tipoDato;	
	
	agregarAcodigoASM("; Division");	
	agregarAcodigoASM(LIBERAR_COPRO);	
	
	colaSacar(&pilaOperandos, &operando1); // Saco 1er operando.
	colaSacar(&pilaOperandos, &operando2); // Saco 2do operando.	
	
	tipoDato = getTipoDatoOperando(operando1);	
	validarOperando(operando2, tipoDato);
	
	// Seteo instrucciones ASM según tipo de dato.
	setInstruccionCargaDatoEnCopro(instruccionCargaCopro, tipoDato);
	setInstruccionCopiaAMemoriaDesdeCopro(instruccionCopiaMemoria, tipoDato);
	
	// Cargo 2do operando.
	strcpy(aux, instruccionCargaCopro);
	strcat(aux, operando2.elemento);	
	agregarAcodigoASM(aux);
		
	// Cargo 1er operando.
	strcpy(aux, instruccionCargaCopro);
	strcat(aux, operando1.elemento);	
	agregarAcodigoASM(aux);
	
	// Ejecuto la multiplicacion.
	strcpy(aux, "FDIV");
	agregarAcodigoASM(aux);

	// Guardo el resultado.
	strcpy(aux, instruccionCopiaMemoria);
	strcat(aux, "AUX_NUMERO");	
	agregarAcodigoASM(aux);	
	agregarOperandoCola("AUX_NUMERO", tipoDato);
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
	
	agregarAcodigoASM("; Impresion de string");
	
	colaSacar(&pilaOperandos, &operando); // Saco operando.
	strcpy(aux, "MOV DX, OFFSET ");
	strcat(aux, operando.elemento);
	agregarAcodigoASM(aux);
	
	strcpy(aux, "MOV AH, 9");
	agregarAcodigoASM(aux);
	
	strcpy(aux, "INT 21h");
	agregarAcodigoASM(aux);	
	
	agregarAcodigoASM("CALL NEWLINE");
}

void imprimirNumeroEnteroASM() {
	struct elementoPolaca operando;
	char aux[100];
	
	agregarAcodigoASM("; Impresion de numero");
	
	colaSacar(&pilaOperandos, &operando); // Saco operando.
	strcpy(aux, "MOV eax,");
	strcat(aux, operando.elemento);	
	agregarAcodigoASM(aux);
	
	strcpy(aux, "CALL IMPRIMIR_ENTERO");	
	agregarAcodigoASM(aux);
}

void percentASM() {
	char tipoDato;
	tipoDato = getTipoDatoPrimerOperandoCola();
	
	agregarAcodigoASM("; Percent");	
	// Multiplico operando1 con operando2.
	multiplicacionASM();
	agregarOperandoCola("_100", tipoDato);
	// Divido el resultado de la multiplicación por 100.
	divisionASM();	
}

void ejecutarProcedimientoUsuarioASM() {
	struct elementoPolaca operando;
	char aux[60], tipoDato;
	
	agregarAcodigoASM("; Llamado a procedimiento de usuario");	
	colaSacar(&pilaOperandos, &operando); // Saco 1er operando (nombre de la funcion).
	
	tipoDato = getTipoDatoRetornoFuncion(operando.elemento);
	
	switch(tipoDato) {
		case 'i': ejecutarProcedimientoRetornoNumerico(operando.elemento, 'i'); break;
		case 'r': ejecutarProcedimientoRetornoNumerico(operando.elemento, 'r'); break;
		case 's': ejecutarProcedimientoRetornoString(operando.elemento); break;
	}
	
}

void ejecutarProcedimientoRetornoNumerico(char * nombreProc, char tipoDato) {
	char aux[60];
	
	strcpy(aux,"CALL ");
	strcat(aux, nombreProc);
	agregarAcodigoASM(aux);
	
	agregarOperandoCola("AUX_NUMERO", tipoDato);
	agregarOperandoCola("AUX_FUNCION_NUMERO", tipoDato);
	asignacionNumericaASM(TRUE);
}

void ejecutarProcedimientoRetornoString(char * nombreProc) {
	char aux[60];
	
	strcpy(aux,"CALL ");
	strcat(aux, nombreProc);
	agregarAcodigoASM(aux);
	
	agregarAcodigoASM("MOV SI,OFFSET AUX_FUNCION_STRING");
	agregarAcodigoASM("MOV DI,OFFSET AUX_STRING");
	
	agregarOperandoCola("AUX_STRING", 's');
}

void retornoDeFuncionASM() {
	struct elementoPolaca operando;
	char tipoDato;
	
	agregarAcodigoASM("; Retorno de funcion");
	tipoDato = getTipoDatoRetornoFuncion(ambito); // El ambito es igual al nombre de la función.
	
	switch(tipoDato) {
		case 'i': retornoDeFuncionNumerica('i'); break;
		case 'r': retornoDeFuncionNumerica('r'); break;
		case 's': retornoDeFuncionString(); break;
	}
}

void retornoDeFuncionNumerica(char tipoDato) {
	struct elementoPolaca operandoRetorno;
	char aux[60];
	
	colaSacar(&pilaOperandos, &operandoRetorno); // Saco operando de retorno.
	agregarOperandoCola("AUX_FUNCION_NUMERO", tipoDato);	// Agrego operando auxiliar.
	agregarOperandoColaDesdePolaca(operandoRetorno); // Vuelvo a meter operando de retorno.
	asignacionNumericaASM(TRUE);
	
	agregarAcodigoASM("RET");
}

void retornoDeFuncionString() {
	struct elementoPolaca operando;
	char aux[60];
	
	colaSacar(&pilaOperandos, &operando); // Saco operando.
	strcpy(aux, "MOV SI,OFFSET ");
	strcat(aux, operando.elemento);
	agregarAcodigoASM(aux);
	
	agregarAcodigoASM("MOV DI,OFFSET AUX_FUNCION_STRING");
	agregarAcodigoASM("CALL COPIAR");
	agregarAcodigoASM("RET");
}

void setInstruccionCargaDatoEnCopro(char * instruccion, char tipoDato) {
	if(tipoDato == 'i') {
		strcpy(instruccion, "FILD ");
	} else {
		strcpy(instruccion, "FLD ");
	}
}

void setInstruccionCopiaAMemoriaDesdeCopro(char * instruccion, char tipoDato) {
	if(tipoDato == 'i') {
		strcpy(instruccion, "FISTP ");
	} else {
		strcpy(instruccion, "FSTP ");
	}
}

void validarOperando(struct elementoPolaca operando, char tipoDato) {
	char tipoDatoOperando = operando.tipo;
	if(operando.tipo == 'f') {
		tipoDatoOperando = getTipoDatoRetornoFuncion(operando.elemento);
	}
	if(tipoDatoOperando != tipoDato) {
		compilationError("Las operaciones deben hacerse con operandos del mismo tipo");
	}
}

char getTipoDatoOperando(struct elementoPolaca operando) {
	char tipoDatoOperando = operando.tipo;
	if(operando.tipo == 'f') {
		tipoDatoOperando = getTipoDatoRetornoFuncion(operando.elemento);
	}
	return tipoDatoOperando;
}

char getTipoDatoRetornoFuncion(char * nombreFuncion) {
	int indiceTS = buscarEnTS("main", nombreFuncion, 'n', elementosTS, cantidadElementosTS);
	return elementosTS[indiceTS].tipoRetorno;
}

/* Rutinas estándar */
void agregarRutinaStrlen() {
	fprintf(codigoASM,
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
	fprintf(codigoASM,
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
	fprintf(codigoASM,
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
	fprintf(codigoASM,
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
	fprintf(codigoASM,
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
   fprintf(codigoASM,
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

void agregarAcodigoASM(char * cadena) {
	fprintf(codigoASM, "	%s\n", cadena);
}

void ensamblarArchivoASM(){
	fuenteASM = fopen(FILE_FUENTE, "wt");
	variablesASM = fopen(FILE_VARIABLES, "rt");
	codigoASM = fopen(FILE_CODIGO, "rt");
	char buffer[200];
	fgets(buffer,sizeof(buffer),variablesASM);
	
	while(!feof(variablesASM)) {
		fprintf(fuenteASM,"%s",buffer);
		fgets(buffer,sizeof(buffer),variablesASM);
	}
	
	fgets(buffer,sizeof(buffer),codigoASM);
	while(!feof(codigoASM)) {
		fprintf(fuenteASM,"%s",buffer);
		fgets(buffer,sizeof(buffer),codigoASM);
	}
	
	fclose(variablesASM);
	fclose(codigoASM);
	fclose(fuenteASM);
}
