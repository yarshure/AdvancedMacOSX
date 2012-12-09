// watch.m -- try a watchpoint

/* compile with
cc -g -o watch watch.m
*/

#import <stdlib.h>	// for random()
#import <stdio.h>	// for printf()x

typedef struct blarg {
    int foo;
    char bar[15];
} blarg;



int main (int argc, char *argv[])
{
    int i, j;
    blarg  urgle[5];

    i = 0;

    while (1) {
	j = random () % 50;
	if (j == 5) {
	    printf ("got 5! (%d)\n", i);
	}
	i++;
    }

    exit (EXIT_SUCCESS);

} // main


