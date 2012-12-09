#include <stdio.h>
#include <stdlib.h>

int main (int argc, char *argv[])
{
    int i;

    for (i = 0; i < argc; i++) {
	printf ("%d: %s\n", i, argv[i]);
    }

    return (EXIT_SUCCESS);

} // main

