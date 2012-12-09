// testmultiple.m -- see if multiple blocked signals are queued or delviered
//		     once.  Based on Stevens's program 10.1 in APUE

/* compile with
cc -g -Wmost -o testmultiple testmultiple.m
*/

#import <signal.h>	// for signal symbols
#import <stdio.h>	// for fprintf and friends
#import <stdlib.h>	// for EXIT_SUCCESS
#import <errno.h>	// for errno
#import <string.h>	// for strerror()



static void sig_quit (int signalNumber)
{
    printf ("caught SIGQUIT\n");
    
    if (signal(SIGQUIT, SIG_DFL) == SIG_ERR) {
	fprintf (stderr, "can't reset SIGQUIT\n");
    }

} // sig_quit


int main (int argc, char *argv[])
{
    sigset_t newmask, oldmask, pendmask;

    if (signal (SIGQUIT, sig_quit) == SIG_ERR) {
	fprintf (stderr, "Can't catch SIGQUIT");
    }

    // blockSIGQUIT and save current signal mask
    sigemptyset (&newmask);
    sigaddset (&newmask, SIGQUIT);
    if (sigprocmask(SIG_BLOCK, &newmask, &oldmask) < 0) {
	fprintf (stderr, "sigprocmask error: %d / %s\n",
		 errno, strerror(errno));
    }

    sleep (10);  // sigquit wil remain pending

    if (sigpending (&pendmask) < 0) {
	fprintf (stderr, "sigpending error: %d / %s\n",
		 errno, strerror(errno));
    }
    if (sigismember (&pendmask, SIGQUIT)) {
	printf ("\nSIGQUIT pending\n");
    }
    
    // reset signal mask which unblocks sigquit
    if (sigprocmask (SIG_SETMASK, &oldmask, NULL) < 0) {
	fprintf (stderr, "SIG_SETMASK errror: %d / %s\n", 
		 errno, strerror(errno));
    }

    printf ("SIGQUIT unblocked\n");

    sleep (10);	// SIGQUIT should temrinate here

    return (EXIT_SUCCESS);

} // main




