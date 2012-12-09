// minimal-daemon.m -- a minimal daemon that runs under launchd

#import <stdio.h>	// for printf()
#import <signal.h>	// for signal()
#import <stdlib.h>	// for exit()
#import <unistd.h>	// for write()
#import <strings.h>	// for strlen()

/* compile with
gcc -g -Wall -o minimal-daemon minimal-daemon.m
*/

/* schedule with
launchctl load ./minimal-daemon.plist 
launchctl unload ./minimal-daemon.plist 
*/


void handleSigTerm (int signal)
{
    char *message = "we got signal!\n";
    int len = strlen (message);

    write (1, message, len);

} // handleSigTerm



int main (void)
{
    printf ("starting!\n");
    fflush (stdout);

    signal (SIGTERM, handleSigTerm);

    sleep (100);

    exit (0);

} // main
