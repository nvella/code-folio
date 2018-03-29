#include <stdio.h>
#include <stdlib.h>

#include "sys.h"

void Sys_RaiseError(char* error) {
	printf("\nfatal error:\n%s", error);
	exit(EXIT_FAILURE);
}
