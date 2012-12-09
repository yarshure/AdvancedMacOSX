#include <stdio.h>
#include <stdlib.h>

// clang -g -Weverything -o dumpargs dumpargs.m

int main (int argc, char *argv[]) {
    int i;

    for (i = 0; i < argc; i++) {
	printf ("%d: %s\n", i, argv[i]);
    }

    return (EXIT_SUCCESS);

} // main

