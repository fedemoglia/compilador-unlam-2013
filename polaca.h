#define TAM_POLACA 4000

struct elementoPolaca {
	char elemento[40];
	char tipo;
};

struct polaca {
	int cantidadElementos;
	struct elementoPolaca elementos[TAM_POLACA];
	};
	
void polacaAgregar(struct polaca * pol,char * elemento, char tipo='?') {
	struct elementoPolaca nuevo;
	strcpy(nuevo.elemento,elemento);
	nuevo.tipo=tipo;
	
	pol->elementos[pol->cantidadElementos] = nuevo;
	pol->cantidadElementos++;	
}


void imprimePolaca(struct polaca pol)
{
	int i=0;
	printf("Abriendo archivo de intermedia\n");
	FILE *out = fopen("intermedia.txt","w");
	printf("Abierto archivo de intermedia\n");
	
	while(i<pol.cantidadElementos)
	{
		printf("Agregando a intermedia\n");
		fprintf(out,"%s %c\n",pol.elementos[i].elemento,pol.elementos[i].tipo);
		i++;
	}
	
	fclose(out);
}

