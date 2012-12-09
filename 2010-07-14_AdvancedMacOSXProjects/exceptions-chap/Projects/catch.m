// catch.m -- catch some signals

/* compile with
cc -g -Wmost -o catch catch.m
*/

#import <signal.h>	// for signal functions and types
#import <stdio.h>	// printf and friends
#import <stdlib.h>	// for EXIT_SUCCESS
#import <unistd.h>	// for sleep
#import <string.h>	// for strlen


static void writeString (const char *string)
{
    int length = strlen (string);
    write (STDOUT_FILENO, string, length);

} // writeString

void handleHUP (int signo)
{
    writeString ("got a HUP!\n");

} // handleHUP


void handleUsr1Usr2 (int signo)
{
    if (signo == SIGUSR1) {
	writeString ("got a SIGUSR1\n");

    } else if (signo == SIGUSR2) {
	writeString ("got a SIGUSR2. exiting\n");
	exit (EXIT_SUCCESS);
    }

} // handleUsr1Usr2


int main (int argc, char *argv[])
{
    int i;

    // register our signal handlers

    (void) signal (SIGHUP, handleHUP);
    (void) signal (SIGUSR1, handleUsr1Usr2);
    (void) signal (SIGUSR2, handleUsr1Usr2);

    // now do our Real Work

    for (i = 0; i < 500000; i++) {
	printf ("i is %d\n", i);
	sleep (1);
    }

    return (EXIT_SUCCESS);
    
} // main

