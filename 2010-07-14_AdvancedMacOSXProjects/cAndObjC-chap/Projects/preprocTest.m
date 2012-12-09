// preprocTest.m -- a simple program to see preprocessor output

/* compile with
gcc -g -Wall -o preprocTest preprocTest.m
or
gcc -g -Wall -E preprocTest.m > junk.i
or choose "Preprocess" in Xcode
*/

#import <stdio.h> // for printf()
#include <sys/types.h>

#define BUFFER_SIZE 2048

int main (int argc, char *argv[])
{
    char buffer[BUFFER_SIZE]; /* this is a comment */
    char *thing;
    
    thing = fgets (buffer, BUFFER_SIZE, stdin);
    printf ("%s", thing);

    /* some oter comment */
    return (0);

} // main

