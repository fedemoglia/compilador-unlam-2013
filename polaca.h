#define TAMANIO_COLA 10000

struct elementoPolaca {
	char elemento[40];
	char tipo;
};

typedef struct colaPolaca {
	struct elementoPolaca elementos[TAMANIO_COLA];
	int cantidadElementosCola;
} colaPolaca;

void polacaAgregar(colaPolaca * pol,char * elemento, char tipo, int posicion) {
	struct elementoPolaca nuevo;
	strcpy(nuevo.elemento,elemento);
	nuevo.tipo=tipo;
	colaEmpujar(pol,nuevo, posicion);
}

void colaEmpujar(colaPolaca * stack, struct elementoPolaca elemento, int posicion) {

	if(stack->cantidadElementosCola==TAMANIO_COLA) {
		printf("Stack Overflow!");
		exit(1);
		}
		
	if(posicion==-1) {
		stack->elementos[stack->cantidadElementosCola]=elemento;
		stack->cantidadElementosCola++;
	}
	else {
		printf("\nIntentando insertar en posicion %d\n",posicion);
		stack->elementos[posicion]=elemento;
	}
}

void colaSacar(colaPolaca * stack,  struct elementoPolaca * elemento) {
	if(colaVacia(stack)) {
		printf("Error! Se quiso extraer de una pila vacía\n");
		exit(1);
	}
	
	*elemento=stack->elementos[stack->cantidadElementosCola-1];
	stack->cantidadElementosCola--;
}

int colaVacia (colaPolaca * stack) {
	if(stack->cantidadElementosCola==0) {
		return 1;
	}
	else {
		return 0;
	}
}

void imprimirCola(colaPolaca * stack) {
	printf("\n===VOLCADO DE POLACA=== \n");
	int i=0;
	while(i<stack->cantidadElementosCola) {
		struct elementoPolaca elem = stack->elementos[i];
		printf("POS: %d - %s (%c)\n",i,elem.elemento,elem.tipo);	
		i++;
	} 
}

void generarArchivoIntermedia (colaPolaca * stack) {
	FILE * intermedia;
	if( !(intermedia = fopen("Intermedia.txt","w") ) ) {
		printf("Error de apertura del archivo de notacion intermedia...");
		getchar();
		exit(0);
    }
	int i=0;
	struct elementoPolaca elem;
	while(i<stack->cantidadElementosCola-1) {
		elem = stack->elementos[i];
		fprintf(intermedia, "%s,",elem.elemento);	
		i++;
	}
	elem = stack->elementos[i];
	fprintf(intermedia, "%s",elem.elemento);
	fclose(intermedia);
}

void imprimePolaca(colaPolaca * pol)
{
	imprimirCola(pol);
}
