// expansion.m -- look at macro expansion

/* compile with
gcc -g -Wall -o expansion expansion.m
*/

#include <stdio.h>  // for printf()

int main (void) {

#define FNORD hello
    int FNORD = 23;
    printf ("hello, your number today is %d\n", hello);

#define NOBODY_HOME
    static unsigned NOBODY_HOME int thing = 42;
    printf ("thing, your number today is %d\n", thing);

// this is actually a dangerous way to do this.  See
// the section about macro hygiene.
#define SUM(x, y)  x + y
    int value = SUM(23, 42);
    printf ("value, your number today is %d\n", value);

    return (0);

} // main

