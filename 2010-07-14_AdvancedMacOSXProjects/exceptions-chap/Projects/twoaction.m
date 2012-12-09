// twoaction.m -- see if sigaction lets us register two handlers



/* compile with
cc -g -Wmost -o twoaction twoaction.m
*/

#import <signal.h>	// for signal symbols
#import <stdio.h>	// for fprintf and friends
#import <stdlib.h>	// for EXIT_SUCCESS
#import <errno.h>	// for errno
#import <string.h>	// for strerror()

static struct sigaction oldAction;

static void sig_usr (int signo)
{
    printf ("got SIGUSR\n");
} // sig_usr

static void sig_usr_bork (int signo)
{
    printf ("got SIGUSR also!\n");

    (oldAction.sa_handler)(SIGUSR1);

} // sig_usr_bork


int main (int argc, char *argv[])
{
    struct sigaction action;

    sigemptyset (&action.sa_mask);
    action.sa_handler = sig_usr;
    action.sa_flags = 0;

    if (sigaction(SIGUSR1, &action, &oldAction) < 0) {
	fprintf (stderr, "could'nt sigaction SIGUSR1: %d, %s\n",
		 errno, strerror(errno));
    }

    sigemptyset (&action.sa_mask);
    action.sa_handler = sig_usr_bork;
    action.sa_flags = 0;

    if (sigaction(SIGUSR1, &action, &oldAction) < 0) {
	fprintf (stderr, "could'nt sigaction SIGUSR1: %d, %s\n",
		 errno, strerror(errno));
    }

    sleep (30);

    return (EXIT_SUCCESS);

} // main
