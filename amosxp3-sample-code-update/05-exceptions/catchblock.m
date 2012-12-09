// catchblock.m -- Catch and block some signals

// clang -g -Weverything -Wno-unused-parameter -o catchblock catchblock.m

#import <signal.h>      // for signal functions and types
#import <stdio.h>       // printf and friends
#import <stdlib.h>      // for EXIT_SUCCESS
#import <string.h>      // for strlen
#import <unistd.h>      // for sleep

static void writeString (const char *string) {
    size_t length = strlen (string);
    write (STDOUT_FILENO, string, length);
} // writeString


static void handleHUP (int signo) {
    writeString ("got a HUP!\n");
} // handleHUP


static void handleUsr1Usr2 (int signo) {
    if (signo == SIGUSR1) {
        writeString ("got a SIGUSR1\n");

    } else if (signo == SIGUSR2) {
        writeString ("got a SIGUSR2. exiting\n");
        exit (EXIT_SUCCESS);
    }
} // handleUsr1Usr2


int main (void) {
    // Register our signal handlers
    (void) signal (SIGHUP, handleHUP);
    (void) signal (SIGUSR1, handleUsr1Usr2);
    (void) signal (SIGUSR2, handleUsr1Usr2);

    // construct our signal mask.  We don't want to be bothered
    // by SIGUSR1 or SIGUSR2 in our critical section.
    // but we'll leave SIGHUP out of the mask so that it will get
    // delivered

    sigset_t signalMask;
    sigemptyset (&signalMask);
    sigaddset (&signalMask, SIGUSR1);
    sigaddset (&signalMask, SIGUSR2);

    // now do our Real Work

    sigset_t oldSignalMask;

    for (int i = 0; i < 500000; i++) {
        printf ("i is %d\n", i);

        if ( (i % 5) == 0) {
            printf ("blocking at %i\n", i);
            sigprocmask (SIG_BLOCK, &signalMask, &oldSignalMask);
        }

        if ( (i % 5) == 4) {
            printf ("unblocking at %i\n", i);
            sigprocmask(SIG_SETMASK, &oldSignalMask, NULL);
        }

        sleep (1);
    }

    return EXIT_SUCCESS;
} // main

