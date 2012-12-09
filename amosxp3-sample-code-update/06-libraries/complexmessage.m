// complexmessage.m -- return a malloc'd block of memory to a complex message

// clang -g -Weverything -Wno-missing-prototypes -o complexmessage.msg -bundle complexmessage.m

#import <stdio.h>	// for printf
#import <stdlib.h>	// for random number routines
#import <string.h>	// for strdup, and snprintf
#import <time.h>	// for time() to seed the random generator

static unsigned g_randomValue;

int BNRMessageActivate (void) {
    printf ("complex message activate\n");

    srandom ((unsigned)time(NULL));
    g_randomValue = random () % 500;

    return 1;

} // BNRMessageActivate


void BNRMessageDeactivate (void) {
    printf ("complex message deactivate\n");
} // BNRMessageDeactivate


char *BNRMessageMessage (void) {
    char *message;
    asprintf (&message, "Here is a random number: %d", g_randomValue);
    return message;
} // BNRMessageMessage
