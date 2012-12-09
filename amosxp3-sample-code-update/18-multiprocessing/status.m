// status.m -- play with various child exiting status values

// clang -g -Weverything -o status status.m

#import <errno.h>		// for errno
#import <stdio.h>		// for printf
#import <stdlib.h>		// for EXIT_SUCCESS
#import <string.h>		// for strerror
#import <sys/resource.h>	// for rlimit
#import <sys/time.h>		// for ru_utime and ru_stime in rlimit
#import <sys/types.h>		// for pid_t
#import <sys/wait.h>		// for wait()
#import <unistd.h>		// for fork


static void printStatus (int status) {
    if (WIFEXITED(status)) {
	printf ("program exited normally.  Return value is %d",
		WEXITSTATUS(status));

    } else if (WIFSIGNALED(status)) {
	printf ("program exited on signal %d", WTERMSIG(status));
	if (WCOREDUMP(status)) {
	    printf (" (core dumped)");
	}

    } else {
	printf ("other exit value");
    }

    printf ("\n");

} // printStatus


int main (void) {
    int status;

    // normal exit
    if (fork() == 0) {
	_exit (23);
    }

    wait (&status);
    printStatus (status);

    // die by a signal (SIGABRT)
    if (fork() == 0) {
	abort ();
    }

    wait (&status);
    printStatus (status);

    // die by crashing
    if (fork() == 0) {
	int *blah = (int *)0xFeedFace;  // a bad address
	*blah = 12;
    }

    wait (&status);
    printStatus (status);

    // drop core
    if (fork() == 0) {
	struct rlimit rl;
	
	rl.rlim_cur = RLIM_INFINITY;
	rl.rlim_max = RLIM_INFINITY;
	
	if (setrlimit (RLIMIT_CORE, &rl) == -1) {
	    fprintf (stderr, "error in setrlimit for RLIMIT__COR: %d (%s)\n",
		     errno, strerror(errno));
	}
	abort ();
    }

    wait (&status);
    printStatus (status);

    return EXIT_SUCCESS;

} // main

