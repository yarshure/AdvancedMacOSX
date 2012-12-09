// longjmp.m -- use setjmp, longjmp

/* compile with
cc -g -Wmost -o longjmp longjmp.m
*/

#import <setjmp.h>	// for setjmp / longjmp
#import <stdio.h>	// for printf
#import <stdlib.h>	// for EXIT_SUCCESS

static jmp_buf handler;


void doEvenMoreStuff ()
{
    printf ("      entering doEvenMoreStuff\n");
    printf ("      done with doEvenMoreStuff\n");

} // doEvenMoreStuff


void doMoreStuff ()
{
    printf ("    entering doMoreStuff\n");
    doEvenMoreStuff ();
    longjmp (handler, 23);
    printf ("    done with doMoreStuff\n");
} // doMoreStuff


void doStuff ()
{
    printf ("entering doStuff\n");
    doMoreStuff ();
    printf ("done with doStuff\n");
} // doStuff


int main (int argc, char *argv[])
{
    int result;

    if ( (result = setjmp(handler)) ) {
	printf ("longjump called, result of %d\n", result);
    } else {
	doStuff ();
    }
    
    return (EXIT_SUCCESS);

} // main


