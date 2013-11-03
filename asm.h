#define FILE_DATOS "datos.asm"
#define FILE_PROCEDIMIENTOS "procedimientos.asm"
#define FILE_MAIN "main.asm"
#define FILE_FUENTE "fuente.asm"

#define LARGO_MAXIMO_CTE_STRING 30

FILE * fileDatosASM;
FILE * fileProcedimientosASM;
FILE * fileMainASM;

void setNombreVariableASM(char *, char *, char *);

void crearFuenteASM(struct colaPolaca * colaPolaca, struct elementoTablaSimbolos * tablaSimbolos, int cantidadElementosTablaSimbolos) {

	crearArchivosASM();

	generarCodigoCabeceraASM();
	generarCodigoVariablesASM(tablaSimbolos, cantidadElementosTablaSimbolos);
	generarCodigoProcedimientosASM();
	generarCodigoMainASM();
	
	ensamblarArchivosFuenteASM();
}

void crearArchivosASM() {
	fileDatosASM = fopen(FILE_DATOS, "wt");
	fileProcedimientosASM = fopen(FILE_PROCEDIMIENTOS, "wt");
	fileMainASM = fopen(FILE_MAIN, "wt");
}

void generarCodigoCabeceraASM() {
	fprintf(fileDatosASM,".MODEL	LARGE ;tipo de modelo de memoria usado\n");
	fprintf(fileDatosASM,".386\n");
	fprintf(fileDatosASM,".STACK 200h ; bytes en el stack\n");
}

void generarCodigoVariablesASM(struct elementoTablaSimbolos * tablaSimbolos, int cantidadElementosTablaSimbolos) {
	fprintf(fileDatosASM,".DATA ; comienzo de la zona de datos\n\n");

	fprintf(fileDatosASM,"MAXTEXTSIZE equ %d\n\n", LARGO_MAXIMO_CTE_STRING);

	for(int i = 0; i < cantidadElementosTablaSimbolos; i++) {
		struct elementoTablaSimbolos elementoTS = tablaSimbolos[i];

		if(elementoTS.tipo != 'f') {
			char nombreASM[40];
			setNombreVariableASM(elementoTS.nombre, elementoTS.ambito, nombreASM);

			if(elementoTS.nombre[0] == '_') { // Si es una constante
				if(elementoTS.tipo == 'i') {
					fprintf(fileDatosASM, "%s dd %d\n", nombreASM, elementoTS.valorEntero);
				}

				if(elementoTS.tipo == 'r') {
					fprintf(fileDatosASM, "%s dd %d\n", nombreASM, elementoTS.valorReal);
				}

				if(elementoTS.tipo == 's') {
					fprintf(fileDatosASM, "%s db MAXTEXTSIZE %s,'$',%d dup (?)\n", nombreASM, elementoTS.valorString, LARGO_MAXIMO_CTE_STRING);
				}
			} else { // Si es una variable
				if(elementoTS.tipo == 'i') {
					fprintf(fileDatosASM, "%s dd ?\n", nombreASM);	
				}

				if(elementoTS.tipo == 'r') {
					fprintf(fileDatosASM, "%s dd ?\n", nombreASM);
				}

				if(elementoTS.tipo == 's') {
					fprintf(fileDatosASM, "%s db MAXTEXTSIZE dup (?),'$'\n", nombreASM);
				}
			}			
		}				
	}
}

void setNombreVariableASM(char * nombreOriginal, char * ambito, char * nombreASM) {
	strcpy(nombreASM, nombreOriginal);
	strcat(nombreASM, "_");
	strcat(nombreASM, ambito);
}

void generarCodigoProcedimientosASM() {

}

void generarCodigoMainASM() {
	fprintf(fileMainASM, ".CODE ; comienzo de la zona de codigo\n");

	fprintf(fileMainASM, "mov AX,@DATA ; inicializa el segmento de datos\n");
	fprintf(fileMainASM, "mov DS,AX ;\n");

	fprintf(fileMainASM, "mov ax, 4C00h ; termina la ejecución.\n");
	fprintf(fileMainASM, "int 21h\n");
	fprintf(fileMainASM, "END ; final del archivo.\n");
}

void ensamblarArchivosFuenteASM() {
	FILE * fuenteASM = fopen("fuente.asm", "wt");

	fclose(fuenteASM);
}

void eliminarArchivosASMTemporales() {
	fclose(fileDatosASM);
	fclose(fileProcedimientosASM);
	fclose(fileMainASM);

	remove(FILE_DATOS);
	remove(FILE_PROCEDIMIENTOS);
	remove(FILE_MAIN);
}
