// interrupt.m -- show interruption of a long-running process

// clang -Weverything -Wno-unused-parameter -o interrupt interrupt.m

#import <errno.h>       // for errno
#import <setjmp.h>      // for setjmp / longjmp
#import <signal.h>      // for signal functions and types
#import <stdbool.h>     // for bool type
#import <stdio.h>       // for printf
#import <stdlib.h>      // for EXIT_SUCCESS
#import <string.h>      // for strerror
#import <unistd.h>      // for sleep

static jmp_buf handler;

__attribute((noreturn)) static void handleSignal (int signo) {
    longjmp (handler, 1);
} // handleSignal


static void doLotsOfWork () {
    for (int i = 0; i < 50000; i++) {
        printf ("i is %d\n", i);
        sleep (1);
    }
} // doLotsOfWork

int main (void) {
    struct sigaction action;
    sigemptyset (&action.sa_mask);
    sigaddset (&action.sa_mask, SIGTERM);
    
    action.sa_handler = handleSignal;
    action.sa_flags = 0;
    
    if (sigaction (SIGUSR1, &action, NULL) == -1) {
        fprintf (stderr, "error in sigaction: %d / %s\n",  errno, strerror(errno));
        return EXIT_FAILURE;
    }
    
    volatile bool handlerSet = 0;
    while (1) {
        if (!handlerSet) {
            if (setjmp (handler)) {
                // We longjmp'd to here.  Reset the handler next time around.
                handlerSet = 0;
                continue;
            } else {
                handlerSet = 1;
            }
        }

        printf ("starting lots of work\n");
        doLotsOfWork ();
    }

    return EXIT_SUCCESS;

} // main
