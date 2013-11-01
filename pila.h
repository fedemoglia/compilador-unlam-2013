
#define TAMANIO_PILA 10000

struct elementoPolaca {
	char elemento[40];
	char tipo;
};

typedef struct pila {
	struct elementoPolaca elementos[TAMANIO_PILA];
	int cantidadElementosPila;
} pila;


void pilaEmpujar(struct pila * stack, struct elementoPolaca elemento) {

	if(stack->cantidadElementosPila==TAMANIO_PILA) {
		printf("Stack Overflow!");
		exit(1);
		}
	
	stack->elementos[stack->cantidadElementosPila]=elemento;
	stack->cantidadElementosPila++;
}

int pilaVacia (struct pila * stack) {
	if(stack->cantidadElementosPila==0) {
		return 1;
	}
	else {
		return 0;
	}
}

void pilaExtraer(struct pila * stack, struct elementoPolaca * elemento) {

	if(pilaVacia(stack)) {
		printf("Error! Se quiso extraer de una pila vacía\n");
		exit(1);
	}
	
	*elemento=stack->elementos[stack->cantidadElementosPila-1];
	stack->cantidadElementosPila--;
	
	return ;
}

void imprimirPila(struct pila  * stack) {
	printf("\n===VOLCADO DE PILA=== \n");
	int i=stack->cantidadElementosPila;
	while(i>=0) {
		struct elementoPolaca elem = stack->elementos[i];
		printf("%s (%c)\n",elem.elemento,elem.tipo);	
		i--;
	} 
}
