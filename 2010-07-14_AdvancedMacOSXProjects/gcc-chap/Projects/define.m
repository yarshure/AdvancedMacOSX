// define.m -- Use preprocessor symbols

/* Compile with 
cc -g -Wall -o define define.m
and with
cc -g -Wall -o define -DTHING1 -DTHING_2=23 define.m
 */

#include <stdio.h>

#define THING_3

int main (int arg, char *argv[])
{

#ifdef THING_1
    printf ("thing1\n");
#endif

#if THING_2 == 23
    printf ("thing2\n");
#endif

#ifdef THING_3
    printf ("thing3\n");
#endif

    return (0);

} // main
