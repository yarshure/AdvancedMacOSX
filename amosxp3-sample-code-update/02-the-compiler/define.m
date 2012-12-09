// define.m -- Use preprocessor symbols

/* Compile with 
clang -g -Weverything -Wno-undef -o define define.m
and with
clang -g -Weverything -Wno-undef -DTHING1 -DTHING_2=23 -o define define.m
 */

#include <stdio.h>

#define THING_3

int main (void) {

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
