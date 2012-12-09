// simplemessage.m -- return a malloc'd block of memory to a simple message

/* compile with
 cc -g -o simplemessage.msg -bundle simplemessage.m
*/

#import <string.h>	// for strdup
#import <stdio.h>	// for printf


int BNRMessageActivate (void)
{
    printf ("simple message activate\n");
    return (1);
} // BNRMessageActivate


void BNRMessageDeactivate (void)
{
    printf ("simple message deactivate\n");
} // BNRMessageDeactivate


char *BNRMessageMessage (void)
{
    return (strdup("This is a simple message"));
} // BNRMessageMessage

 
