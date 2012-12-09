// preprocTest.m -- a simple program to see preprocessor output for

/* compile with
cc -g -Wall -E preprocTest.m > junk.i
(and then look at junk.i)
*/

#import <stdio.h>

#define BUFFER_SIZE 2048

int main (int argc, char *argv[])
{
    char buffer[BUFFER_SIZE];	/* this is my buffer, there are many like it */
    char *thing;
    
    thing = fgets (buffer, BUFFER_SIZE, stdin);
    printf ("%s", thing);

    /* happiness and light */
    return (0);

} // main

