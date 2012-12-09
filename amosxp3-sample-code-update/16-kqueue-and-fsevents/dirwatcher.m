// dirwatcher.m -- watch directories for changes

// clang -g -Weverything -o dirwatcher dirwatcher.m

#import <errno.h>       // for errno
#import <fcntl.h>	// for O_RDONLY
#import <stdio.h>	// for fprintf()
#import <stdlib.h>	// for EXIT_SUCCESS
#import <string.h>	// for strerror()
#import <sys/event.h>	// for kqueue() etc.
#import <unistd.h>      // for close()

int main (int argc, const char *argv[]) {

    // Program success/failure result
    int result = EXIT_FAILURE;
    int kq = -1;

    // Make sure there's at least one directory to monitor
    if (argc == 1) {
        fprintf (stderr, "%s directoryname [...]\n", argv[0]);
        fprintf (stderr, "    watches directoryname for changes\n");
        goto done;
    }

    // The queue to register the dir-watching events with
    kq = kqueue ();

    if (kq == -1) {
        fprintf (stderr, "could not kqueue.  Error is %d/%s\n",
                 errno, strerror(errno));
        goto done;
    }

    // Walk the set of directories provided by the user and monitor them
    for (int i = 1; i < argc; i++) {
        // The vnode monitor requires a file descriptor, so
        // open the directory to get one.
        const char *dirname = argv[i];
        int dirfd = open (dirname, O_RDONLY);

        if (dirfd == -1) {
            fprintf (stderr, "could not open(%s). Error is %d/%s\n",
                     dirname, errno, strerror(errno));
            continue;
        }

        // Fill out the event structure.  Store the name of the
        // directory in the user data
        struct kevent direvent;
        EV_SET (&direvent,
                dirfd,           // identifier
                EVFILT_VNODE,    // filter
                EV_ADD | EV_CLEAR | EV_ENABLE,  // action flags
                NOTE_WRITE,      // filter flags
                0,               // filter data
                (void *)dirname); // user data
        
        // register the event
        if (kevent(kq, &direvent, 1, NULL, 0, NULL) == -1) {
            fprintf (stderr, "could not kevent.  Error is %d/%s\n",
                     errno, strerror(errno));
            goto done;
        }
    }

    // Register interest in SIGINT with the queue.  The user data
    // is NULL, which is how we'll differentiate between
    // a directory-modification event and a SIGINT-received event.

    struct kevent sigevent;
    EV_SET (&sigevent,
            SIGINT,
            EVFILT_SIGNAL,
            EV_ADD | EV_ENABLE,
            0, 0, NULL);

    // kqueue event handling happens after the legacy API, so make
    // sure it doesn eat the signal before the kqueue can see it.
    signal (SIGINT, SIG_IGN);

    // Register the signal event.
    if (kevent(kq, &sigevent, 1, NULL, 0, NULL) == -1) {
        fprintf (stderr, "could not kevent signal.  Error is %d/%s\n",
                 errno, strerror(errno));
        goto done;
    }

    while (1) {
        // camp on kevent() until something interesting happens
        struct kevent change;
        if (kevent(kq, NULL, 0, &change, 1, NULL) == -1) {
            fprintf (stderr, "cound not kevent.  Error is %d/%s\n",
                     errno, strerror(errno));
            goto done;
        }

        // The signal event has NULL in the user data.  Check for that first.
        if (change.udata == NULL) {
            result = EXIT_SUCCESS;
            printf ("that's all folks...\n");
            goto done;

        } else {
            // udata is non-null, so it's the name of the directory
            // that changed
            printf ("%s\n", (char*)change.udata);
        }
    }

done:
    if (kq >= 0) close (kq);
    return result;

} // main
