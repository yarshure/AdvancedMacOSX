#import <stdio.h>	// for printf()

/* compile with:
gcc -g -Wall -o minimal-service minimal-service.m
*/

/* schedule with
launchctl load ./minimal-service.plist 
launchctl unload ./minimal-service.plist 
*/

int main (int argc, const char *argv[])
{
    char buffer[500];
    char *input;

    while ((input = fgets (buffer, 500, stdin)) != NULL) {
        printf ("you entered: %s\n", input);
        fflush (stdout);
    }

    return (0);

} // main


