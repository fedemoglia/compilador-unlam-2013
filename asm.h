#define FILE_DATOS "datos.asm"
#define FILE_PROCEDIMIENTOS "procedimientos.asm"
#define FILE_MAIN "main.asm"
#define FILE_FUENTE "fuente.asm"

FILE * fileDatosASM;
FILE * fileProcedimientosASM;
FILE * fileMainASM;

void crearFuenteASM() {
	crearArchivosASM();

	generarCodigoCabeceraASM();
	generarCodigoVariablesASM();
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

void generarCodigoProcedimientosASM() {

}

void generarCodigoVariablesASM() {

}

void generarCodigoMainASM() {

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
