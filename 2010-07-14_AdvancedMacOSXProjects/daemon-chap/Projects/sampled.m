#include <sys/time.h>    // for struct timespec
#include <sys/socket.h>  // for sockaddr_storage, etc
#include <syslog.h>	 // for openlog() and syslog()
#include <stdlib.h>	 // for getprogname(), EXIT_SUCCESS, etc
#include <sys/event.h>	 // for kqueue(), kevent()
#include <errno.h>	 // for errno
#include <stdio.h>	 // for fprintf, fdopen, etc
#include <unistd.h>	 // for close()
#include <launch.h>	 // for launch_data*

/* compile with
gcc -g -Wall -o sampled sampled.m
*/

/* schedule with
launchctl load ./sampled.plist
launchctl unload ./sampled.plist
*/

int main(void)
{
    // program success/failure result
    int result = EXIT_FAILURE;
    
    // send interesting messages out through syslog.  Also send
    // messages to standard error, log the process ID, write to
    // the console if syslog isn't available, and we'll be using
    // the daemon facility for logging.
    openlog (getprogname(), 
             LOG_PERROR | LOG_PID | LOG_CONS, LOG_DAEMON);

    // values gotten from launchd data query functions
    launch_data_t message = NULL, configDict = NULL;

    // make the checkin message
    message = launch_data_new_string (LAUNCH_KEY_CHECKIN);

    // and check in with launchd
    if ((configDict = launch_msg(message)) == NULL) {
        syslog (LOG_ERR, 
                "launch_msg(\"" LAUNCH_KEY_CHECKIN "\") IPC failure: %m");
        goto done;
    }

    // see if launchd returned an errno.  If you get "permission denied"
    // make sure you have ServiceIPC=true in your plist
    if (launch_data_get_type(configDict) == LAUNCH_DATA_ERRNO) {
        errno = launch_data_get_errno (configDict);
        syslog (LOG_ERR, "Check-in failed: %m");
        goto done;
    }

    // see if any specific timeout has been requested in plist.
    // default to a minute if not
    struct timespec timeout = { 60, 0 };
    launch_data_t timeoutValue;
    timeoutValue = launch_data_dict_lookup (configDict, 
                                            LAUNCH_JOBKEY_TIMEOUT);
    if (timeoutValue != NULL) {
        timeout.tv_sec = launch_data_get_integer (timeoutValue);
    }

    // get the socket(s) configured
    launch_data_t sockets;
    sockets = launch_data_dict_lookup (configDict, LAUNCH_JOBKEY_SOCKETS);
    if (sockets == NULL) {
        syslog (LOG_ERR, "No sockets found to answer requests on!");
        goto done;
    }

    // currently only support one configured socket, but you're
    // welcome to support more if you wish
    if (launch_data_dict_get_count(sockets) > 1) {
        syslog (LOG_WARNING, "Some sockets will be ignored!");
    }

    // dig into the Sockets dictionary to get the SampleListeners
    // dictionary
    launch_data_t listeners;
    listeners = launch_data_dict_lookup (sockets, "SampleListeners");
    if (listeners == NULL) {
        syslog (LOG_ERR, "No known sockets found to answer requests on!");
        goto done;
    }

    // make a queue we'll use to get new connection fd's from launchd
    int kq;
    if ((kq = kqueue()) == -1) {
        syslog (LOG_ERR, "kqueue(): %m");
        goto done;
    }

    // register a read event with the kqueue
    struct kevent kev;
    size_t i;
    for (i = 0; i < launch_data_array_get_count (listeners); i++) {
        launch_data_t tempi = launch_data_array_get_index (listeners, i);

        EV_SET (&kev,          // struct to fill in
                launch_data_get_fd(tempi),  // identifier
                EVFILT_READ,  // filter
                EV_ADD,       // action flags
                0,            // filter flags
                0,            // filter data
                NULL);        // context

        if (kevent(kq, &kev, 1, NULL, 0, NULL) == -1) {
            syslog (LOG_DEBUG, "kevent(): %m");
            goto done;
        }
        launch_data_free (tempi);
    }
    
    while (1) {
        int status;

        // wait until we get a new event, or the timeout
        status = kevent(kq, NULL, 0, &kev, 1, &timeout);

        if (status == -1) {
            syslog (LOG_ERR, "kevent(): %m");
            goto done;

        } else if (status == 0) {
            // timed out, time to go home
            result = EXIT_SUCCESS;
            goto done;
        }

        // fetch info on the new socket waiting for us from launchd
        struct sockaddr_storage ss;
        socklen_t slen = sizeof(ss);

        int fd;
        fd = accept (kev.ident, (struct sockaddr *)&ss, &slen);
        if (fd == -1) {
            syslog (LOG_ERR, "accept(): %m");
            continue; /* this isn't fatal */
        }

        // read the request and write the response
        FILE *stream;
        stream = fdopen (fd, "r+");

        if (stream != NULL) {
            char buffer[1024];
            buffer[0] = '\0';
            
            char *gotten;
            gotten = fgets (buffer, 1024, stream);
            
            fprintf (stream, "hello world!\n");
            fprintf (stream, "you said '%s'\n", buffer);
            fclose (stream);

        } else {
            syslog (LOG_ERR, "could not fdopen(): %m");
            close (fd);
        }
    }

done:
    // finally clean up after ourselves.
    if (message != NULL) launch_data_free (message);
    if (configDict != NULL) launch_data_free (configDict);

    closelog ();

    return (result);

} // main
