struct elementoTablaSimbolos
{
	char ambito[30]; /* Para saber si pertenece al main o a una función */
	char tipo; /* Identificador de tipo de variable: real, string, entero */
	char nombre[30];
	int valorEntero;
	float valorReal;
	char valorString[30];
	int eliminado;
};

int buscarEnTS(char* ambito, char* nombre, struct elementoTablaSimbolos * tablaSimbolos, int largoTablaSimbolos) {
	int i=0;
	while(i<largoTablaSimbolos) {
		struct elementoTablaSimbolos elemento = tablaSimbolos[i];
		if(strcmp(elemento.ambito,ambito)==0 && strcmp(elemento.nombre,nombre)==0 && elemento.eliminado==0) {
			return i;
		}
		i++;
	}

	if(strcmp(ambito,"main")==0) {
		return -1;
	}
	else {
		// recursividad para volver a llamar a la funcion para buscar en el ambito main, si se estaba en una funcion.
		return buscarEnTS("main",nombre,tablaSimbolos,largoTablaSimbolos);
	}
}

int agregarEnTS(char * ambito, char tipo, char * nombre, void * valor, struct elementoTablaSimbolos * tablaSimbolos, int cantidadElementosTablaSimbolos) {
	struct elementoTablaSimbolos elemento;
	strcpy(elemento.ambito, ambito);
	strcpy(elemento.nombre, nombre);
	elemento.tipo = tipo;
	elemento.eliminado = 0;
	
	switch(tipo) {
		case 'r': // Real. No sé por qué no funciona usar una constante con nombre :s
			elemento.valorReal = (*((float *)valor));
			elemento.valorEntero = 0;
			strcpy(elemento.valorString,"");
		break;

		case 's': // String. 
			strcpy(elemento.valorString,valor);
			elemento.valorEntero = 0;
			elemento.valorReal = 0;
		break;

		case 'e': // Entero
			elemento.valorEntero = (*((int *)valor));
			elemento.valorReal = 0;
			strcpy(elemento.valorString,"");
		break;
		}
	
	tablaSimbolos[cantidadElementosTablaSimbolos++]=elemento;
	
	return cantidadElementosTablaSimbolos;
}

int eliminarDeTS(char * ambito, char * nombre, struct elementoTablaSimbolos * tablaSimbolos, int cantidadElementosTablaSimbolos) {
	int indiceElemento = buscarEnTS(ambito,nombre,tablaSimbolos, cantidadElementosTablaSimbolos);
	
	/* Si el elemento existe, lo marca como eliminado */
	if(indiceElemento!=-1) {
		tablaSimbolos[indiceElemento].eliminado=1;
	}

	return cantidadElementosTablaSimbolos;
}



int esElementoInexistente(struct elementoTablaSimbolos elemento) {
	if (strcmp(elemento.ambito,"SINAMBITO")==0 && 
		strcmp(elemento.nombre,"INEXISTENTE")==0) {
			return 1;
		}
		else {
			return 0;
		};
}