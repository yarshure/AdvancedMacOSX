// syslog.m -- use the syslog functions

// clang -g -Weverything -o syslog syslog.m

#import <syslog.h>	// for syslog and friends
#import <stdlib.h>	// for EXIT_SUCCESS
#import <errno.h>	// for errno

int main (void) {
    syslog (LOG_WARNING, "This is a warning message.");
    errno = EINVAL;
    syslog (LOG_ERR, "This is an error, %m");
    syslog (LOG_EMERG, "WHOOP!! WHOOP!!");

    openlog ("BNRsyslogTest", LOG_PID | LOG_NDELAY | LOG_CONS, LOG_DAEMON);

    syslog (LOG_DEBUG, "Debug message");
    syslog (LOG_NOTICE, "Notice message");

    return EXIT_SUCCESS;
} // main
