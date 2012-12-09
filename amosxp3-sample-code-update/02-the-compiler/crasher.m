// crasher.m -- a program that crashes, for use with atos.

#import <stdlib.h> // for abort()

/* compile and run with:
clang -g -o crasher crasher.m
*/

void die() 
{
    abort();
} // die


void bounce() {
    die ();
} // bounce


int main (void) {
    bounce ();
    return (0);
} // main


