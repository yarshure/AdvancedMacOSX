// complexmessage.m -- return a malloc'd block of memory to a complex message


/* compile with
 cc -g -o complexmessage.msg -bundle complexmessage.m
*/

#import <stdlib.h>	// for random number routines
#import <time.h>	// for time() to seed the random generator
#import <stdio.h>	// for printf
#import <string.h>	// for strdup, and snprintf

static int g_randomValue;

int BNRMessageActivate (void)
{
    printf ("complex message activate\n");

    srandom (time(NULL));
    g_randomValue = random () % 500;

    return (1);

} // BNRMessageActivate


void BNRMessageDeactivate (void)
{
    printf ("complex message deactivate\n");
} // BNRMessageDeactivate


char *BNRMessageMessage (void)
{
    char buffer[2048];

    snprintf (buffer, 2048, "Here is a random number: %d", g_randomValue);

    return (strdup(buffer));

} // BNRMessageMessage

 

