#define TAM_POLACA 4000

#include "pila.h"


	
void polacaAgregar(struct pila * pol,char * elemento, char tipo='?') {
	struct elementoPolaca nuevo;
	strcpy(nuevo.elemento,elemento);
	nuevo.tipo=tipo;
	
	pilaEmpujar(pol,nuevo);
}


void imprimePolaca(struct pila * pol)
{
	imprimirPila(pol);

	/*int i=0;
	printf("Abriendo archivo de intermedia\n");
	FILE *out = fopen("intermedia.txt","w");
	printf("Abierto archivo de intermedia. Volcando %d elementos \n",pol->cantidadElementos);
	
	while(i<pol->cantidadElementos)
	{
		fprintf(out,"%s (%c) \n",pol->elementos[i].elemento,pol->elementos[i].tipo);
		i++;
	}
	
	fclose(out);*/
}

