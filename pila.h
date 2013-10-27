
struct datoPila {
	char datoString[200];
	
};
typedef struct nodoPila
{
	struct datoPila dato;
	struct nodoPila * siguiente;
} nodoPila;


nodoPila*  pilaEmpujar(nodoPila * pila, struct datoPila elemento) {

	nodoPila * nuevo = (nodoPila *)malloc(sizeof(nodoPila));
	nuevo->dato=elemento;

	nuevo->siguiente=pila;
	pila = nuevo;
	
	return nuevo;
}

int pilaVacia (nodoPila * pila) {
	if(pila==NULL) {
		return 1;
	}
	else {
		return 0;
	}
}

nodoPila* pilaExtraer(nodoPila * pila, struct datoPila & elemento) {

	if(pilaVacia(pila)) {
		printf("Error! Se quiso extraer de una pila vacía\n");
		exit(1);
	}
	
	elemento=pila->dato;
	
	pila = pila->siguiente;
	return pila;
}

void imprimirPila(nodoPila * pila) {
	nodoPila * elem = pila;
	printf("\n===VOLCADO DE PILA=== \n");
	while(elem!=NULL) {
		printf("\nDesapilando: ");
		printf("%s\n",elem->dato.datoString);	
		elem=elem->siguiente;
	} 
}