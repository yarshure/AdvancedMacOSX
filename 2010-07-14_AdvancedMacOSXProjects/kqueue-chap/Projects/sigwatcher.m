// sigwatcher.m -- watch for signals happening

#import <sys/event.h>	// for kqueue() etc.
#import <sys/signal.h>	// for SIGINT, etc
#import <sys/time.h>	// for struct timespec
#import <errno.h>       // for errno
#import <string.h>	// for strerror()
#import <stdio.h>	// for fprintf()
#import <unistd.h>	// for getpid()
#import <stdlib.h>	// for EXIT_SUCCESS

/* compile with
gcc -g -Wall -o sigwatcher sigwatcher.m
*/

int main (int argc, const char *argv[])
{
    // program success/failure result
    int result = EXIT_FAILURE;

    // register signal events with this queue.
    int kq;
    kq = kqueue ();

    if (kq == -1) {
        fprintf (stderr, "could not kqueue.  Error is %d/%s\n",
                 errno, strerror(errno));
    }

    // the list of events we're interested in (mostly just pulled
    // at random from <sys/signal.h>)

    int signals[] = { SIGHUP, SIGINT, SIGQUIT, SIGILL, SIGTRAP, SIGABRT,
                      SIGBUS, SIGSEGV, SIGPIPE, SIGTERM, SIGCHLD };
    int *scan, *stop;
    scan = signals;
    stop = scan + sizeof(signals) / sizeof(*signals);

    // register each event with the kqueue

    while (scan < stop) {
        struct kevent event;
        EV_SET (&event, *scan,
                EVFILT_SIGNAL,
                EV_ADD | EV_ENABLE,
                0, 0, NULL);

        // kqueue event handling happens after the legacy API, so make
        // sure it doesn't eat the event before the kqueue can see it
        signal (*scan, SIG_IGN);

        // register the signal event; note that kevent()
        // will return immediately
        if (kevent(kq, &event, 1, NULL, 0, NULL) == -1) {
            fprintf (stderr, "could not kevent signal.  Error is %d/%s\n",
                     errno, strerror(errno));
            goto done;
        }
        scan++;
    }

    printf ("I am pid %d\n", getpid());

    // now block and display any signals received

    while (1) {
        struct timespec timeout = { 5, 0 };
        int status;
        struct kevent event;
        status = kevent (kq, NULL, 0, &event, 1, &timeout);

        if (status == 0) {
            // timeout
            printf ("lub dub...\n");

        } else if (status > 0) {
            // we got signal!
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
    return (result);

} // main
