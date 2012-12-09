// longjmp.m -- use setjmp, longjmp

// clang -g -Weverything -Wno-missing-noreturn -Wno-unreachable-code -o longjmp longjmp.m

#import <setjmp.h>      // for setjmp / longjmp
#import <stdio.h>       // for printf
#import <stdlib.h>      // for EXIT_SUCCESS

static jmp_buf handler;

static void doEvenMoreStuff () {
    printf ("        entering doEvenMoreStuff\n");
    printf ("        done with doEvenMoreStuff\n");
} // doEvenMoreStuff

static void doMoreStuff () {
    printf ("    entering doMoreStuff\n");
    doEvenMoreStuff ();
    longjmp (handler, 23);
    printf ("    done with doMoreStuff\n");
} // doMoreStuff

static void doStuff () {
    printf ("entering doStuff\n");
    doMoreStuff ();
    printf ("done with doStuff\n");
} // doStuff

int main (void) {
    int result;

    if ( (result = setjmp(handler)) ) {
        printf ("longjump called, setjmp returned again: %d\n", result);
    } else {
        doStuff ();
    }
    
    return (EXIT_SUCCESS);
} // main


