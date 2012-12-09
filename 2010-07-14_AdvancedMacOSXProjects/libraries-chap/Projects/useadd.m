// useadd.m -- use functions from a library

/* compile with
cc -g -o useadd useadd.m -L. -laddum 
 */

#import <stdlib.h>	// for EXIT_SUCCESS
#import <stdio.h>	// for printf

int main (int argc, char *argv[])
{
    int i;

    i = 5;
    printf ("i is %d\n", i);

    i = add_1 (i);
    printf ("i after add_1: %d\n", i);

    i = add_4 (i);
    printf ("i after add_4: %d\n", i);

    exit (EXIT_SUCCESS);
} // main
