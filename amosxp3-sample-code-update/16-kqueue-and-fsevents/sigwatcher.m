// sigwatcher.m -- watch for signals happening

// clang -g -Weverything -o sigwatcher sigwatcher.m

#import <errno.h>       // for errno
#import <stdio.h>	// for fprintf()
#import <stdlib.h>	// for EXIT_SUCCESS
#import <string.h>	// for strerror()
#import <sys/event.h>	// for kqueue() etc.
#import <sys/signal.h>	// for SIGINT, etc
#import <sys/time.h>	// for struct timespec
#import <unistd.h>	// for getpid()

int main (void) {
    // Program success/failure result.
    int result = EXIT_FAILURE;

    // Register signal events with this queue.
    int kq = kqueue ();
    if (kq == -1) {
        fprintf (stderr, "could not kqueue.  Error is %d/%s\n",
                 errno, strerror(errno));
    }

    // The list of events we're interested in, mostly just pulled
    // at random from <sys/signal.h>.
    int signals[] = { SIGHUP, SIGINT, SIGQUIT, SIGILL, SIGTRAP, SIGABRT,
                      SIGBUS, SIGSEGV, SIGPIPE, SIGTERM, SIGCHLD, SIGWINCH };
    int *scan = signals;
    int *stop = scan + sizeof(signals) / sizeof(*signals);

    // Register each event with the kqueue.
    while (scan < stop) {
        struct kevent event;
        EV_SET (&event, *scan,
                EVFILT_SIGNAL,
                EV_ADD | EV_ENABLE,
                0, 0, NULL);

        // kqueue event handling happens after legacy API, so make
        // sure it the signal doesn't get eaten.
        signal (*scan, SIG_IGN);

        // Register the signal event.  kevent() will return immediately.
        if (kevent(kq, &event, 1, NULL, 0, NULL) == -1) {
            fprintf (stderr, "could not kevent signal.  Error is %d/%s\n",
                     errno, strerror(errno));
            goto done;
        }
        scan++;
    }

    printf ("I am pid %d\n", getpid());

    // Now block and display any signals received.
    while (1) {
        struct timespec timeout = { 5, 0 };
        struct kevent event;
        int status = kevent (kq, NULL, 0, &event, 1, &timeout);

        if (status == 0) {
            // Timeout.
            printf ("lub dub...\n");

        } else if (status > 0) {
            // We got signal!
            printf ("we got signal: %d (%s), delivered: %d\n", 
                    (int)event.ident, strsignal((int)event.ident),
                    (int)event.data);

            if (event.ident == SIGINT) {
                result = EXIT_SUCCESS;
                goto done;
            }

        } else {
            fprintf (stderr, "cound not kevent.  Error is %d/%s\n",
                     errno, strerror(errno));
            goto done;
        }
    }

done:
    close (kq);
    return result;

} // main
