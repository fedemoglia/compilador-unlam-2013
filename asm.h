#define FILE_DATOS "datos.asm"
#define FILE_PROCEDIMIENTOS "procedimientos.asm"
#define FILE_MAIN "main.asm"
#define FILE_FUENTE "fuente.asm"

// FIXME Estamos definiendo dos veces las constantes!
#define LARGO_MAXIMO_NOMBRE_TOKEN 20
#define LARGO_MAXIMO_CTE_STRING 30

//FILE * fuenteASM;
//FILE * fuenteASM;
//FILE * fuenteASM;
FILE * fuenteASM;

struct colaPolaca * polaca;
struct elementoTablaSimbolos * elementosTS;
int cantidadElementosTS;

void setNombreVariableASM(char *, char *, char *);

void crearFuenteASM(struct colaPolaca * colaPolaca, struct elementoTablaSimbolos * tablaSimbolos, int cantidadElementosTablaSimbolos) {
	// FIXME No me gusta la forma en que se están declarando estas varibles globales, pero se complicaba pasar todos los parámetros siempre.
	polaca = colaPolaca;
	elementosTS = tablaSimbolos;
	cantidadElementosTS = cantidadElementosTablaSimbolos;

	crearArchivosASM();

	generarCodigoCabeceraASM();
	generarCodigoVariablesASM();
	
	generarCodigoInicioCodigoASM();
	generarCodigoRutinasASM();
	generarCodigoMainASM();
	generarCodigoFinCodigoASM();
	
	//ensamblarArchivosFuenteASM();
	//eliminarArchivosASMTemporales();
}

void crearArchivosASM() {
	fuenteASM = fopen(FILE_FUENTE, "wt");
	//fuenteASM = fopen(FILE_DATOS, "wt");
	//fuenteASM = fopen(FILE_PROCEDIMIENTOS, "wt");
	//fuenteASM = fopen(FILE_MAIN, "wt");
}

void generarCodigoCabeceraASM() {
	fprintf(fuenteASM,".MODEL	LARGE ;tipo de modelo de memoria usado\n");
	fprintf(fuenteASM,".386\n");
	fprintf(fuenteASM,".STACK 200h ; bytes en el stack\n\n");
}

void generarCodigoVariablesASM() {
	fprintf(fuenteASM,".DATA ; Comienzo de la zona de datos\n\n");
	fprintf(fuenteASM,"MAXTEXTSIZE equ %d\n\n", LARGO_MAXIMO_CTE_STRING);

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
					case 's': fprintf(fuenteASM, "db MAXTEXTSIZE \"%s\",'$',%d dup (?)\n", elementoTS.valorString, LARGO_MAXIMO_CTE_STRING - strlen(elementoTS.valorString)); break;
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
	fprintf(fuenteASM, "END ; Final del archivo.\n");
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
		for(int i = indiceInicioFuncion + 2; i < indiceFinFuncion; i++) {  // Las instrucciones de la función empiezan en inicio + 2.
			struct elementoPolaca elem = polaca->elementos[i];
			fprintf(fuenteASM, "	%d - %s\n", i, elem.elemento, elem.tipo);
		}
		fprintf(fuenteASM, "%s ENDP\n\n", nombreFuncion);
		indiceInicioFuncion = buscarInicioFuncion(indiceFinFuncion); // Busco en la polaca el inicio de la siguiente función.
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

void generarCodigoMainASM() {
	fprintf(fuenteASM,"; --- Comienzo de programa principal ---\n\n");

	fprintf(fuenteASM, "mov AX,@DATA ; Inicializa el segmento de datos\n");
	fprintf(fuenteASM, "mov DS,AX ;\n");

	fprintf(fuenteASM,"; --- Fin de programa principal ---\n\n");
}

void ensamblarArchivosFuenteASM() {
	FILE * fuenteASM = fopen("fuente.asm", "wt");
	FILE * fileDatosTemp = fopen(FILE_DATOS, "rt");
	char buffer[200];
	
	fgets(buffer, sizeof(buffer), fileDatosTemp);
	while(!feof(fileDatosTemp)) {
		fprintf("%s", buffer);
		fprintf(fuenteASM, "%s", buffer);
		fgets(buffer, sizeof(buffer), fileDatosTemp);
	}

	fclose(fuenteASM);
}

void eliminarArchivosASMTemporales() {
	fclose(fuenteASM);
	fclose(fuenteASM);
	fclose(fuenteASM);

	remove(FILE_DATOS);
	remove(FILE_PROCEDIMIENTOS);
	remove(FILE_MAIN);
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