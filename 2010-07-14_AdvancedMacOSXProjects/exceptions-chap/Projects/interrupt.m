// interrupt.m -- show interruption of a long-running process

/* compile with
cc -g -Wmost -o interrupt interrupt.m
*/

#import <signal.h>	// for signal functions and types
#import <unistd.h>	// for sleep
#import <string.h>	// for strerror
#import <setjmp.h>	// for setjmp / longjmp
#import <stdio.h>	// for printf
#import <stdlib.h>	// for EXIT_SUCCESS
#import <errno.h>

static jmp_buf handler;

void handleSignal (int signo)
{
    longjmp (handler, 1);
} // handleSignal


void doLotsOfWork ()
{
    int i;

    for (i = 0; i < 50000; i++) {
	printf ("i is %d\n", i);
	sleep (1);
    }

} // doLotsOfWork



int main (int argc, char *argv[])
{
    volatile int handlerSet = 0;

    struct sigaction action;

    sigemptyset (&action.sa_mask);
    sigaddset (&action.sa_mask, SIGTERM);

    action.sa_handler = handleSignal;
    action.sa_flags = 0;

    if (sigaction (SIGUSR1, &action, NULL) == -1) {
	fprintf (stderr, "error in sigaction: %d / %s\n",
		 errno, strerror(errno));
	return (EXIT_FAILURE);
    }

    while (1) {

	if (!handlerSet) {
	    if (setjmp (handler)) {
		// we longjmp'd to here.  Reset our handler next time around
		handlerSet = 0;
		continue;
	    } else {
		handlerSet = 1;
	    }
	}

	printf("starting lots of work\n");
	doLotsOfWork ();
    }

    return (EXIT_SUCCESS);

} // main

