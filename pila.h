
#define TAMANIO_PILA 10000

 typedef struct pilaEnteros {
	int elementos[TAMANIO_PILA];
	int cantidadElementosPila;
} pilaEnteros;

void pilaEmpujar(struct pilaEnteros * stack, int elemento) {

	if(stack->cantidadElementosPila==TAMANIO_PILA) {
		printf("Stack Overflow!");
		exit(1);
		}
	
	stack->elementos[stack->cantidadElementosPila]=elemento;
	stack->cantidadElementosPila++;
}

int pilaVacia (struct pilaEnteros * stack) {
	if(stack->cantidadElementosPila==0) {
		return 1;
	}
	else {
		return 0;
	}
}

void pilaExtraer(struct pilaEnteros * stack, int * elemento) {

	if(pilaVacia(stack)) {
		printf("Error! Se quiso extraer de una pila vacía\n");
		exit(1);
	}
	
	*elemento=stack->elementos[stack->cantidadElementosPila-1];
	stack->cantidadElementosPila--;
}

void colaExtraer(struct pilaEnteros * stack, int * elemento) {
	if(pilaVacia(stack)) {
		printf("Error! Se quiso extraer de una pila vacía\n");
		exit(1);
	}
	
	*elemento=stack->elementos[0];
	int j=0;
	while(j<stack->cantidadElementosPila) {
		printf("--- Elemento %d: %d\n",j,stack->elementos[j]);	
		j++;
	}
	int i=0;
	while(i<stack->cantidadElementosPila-1) {
		stack->elementos[i] = stack->elementos[i+1];	
		i++;
	}
	
	stack->cantidadElementosPila--;




}

void imprimirPila(struct pilaEnteros  * stack) {
	printf("\n===VOLCADO DE PILA DE SALTOS=== \n");
	int i=stack->cantidadElementosPila;
	while(i>0) {
		int elem = stack->elementos[i-1];
		printf("Posicion %d: %d\n",i,elem);
		i--;
	} 
}
