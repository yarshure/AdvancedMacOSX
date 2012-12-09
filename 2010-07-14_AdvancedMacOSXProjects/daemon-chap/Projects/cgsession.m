#import <CoreFoundation/CoreFoundation.h>
#import <ApplicationServices/ApplicationServices.h>

/* compile with
gcc -g -Wall -framework CoreFoundation -framework ApplicationServices -o cgsession cgsession.m
*/

int main (void) {

    CFDictionaryRef sessionInfo = CGSessionCopyCurrentDictionary ();
    
    if (sessionInfo == NULL) {
        printf ("can't get session dictionary\n");
        return (EXIT_FAILURE);
    }

    CFStringRef shortUserName;
    shortUserName = CFDictionaryGetValue (sessionInfo,
                                          kCGSessionUserNameKey);

    CFNumberRef userUIDNumber;
    userUIDNumber = CFDictionaryGetValue (sessionInfo,
                                          kCGSessionUserIDKey);
    int userUID;
    (void)CFNumberGetValue(userUIDNumber, kCFNumberIntType, &userUID);

    CFBooleanRef userIsActive;
    userIsActive = CFDictionaryGetValue (sessionInfo,
                                         kCGSessionOnConsoleKey);

    CFBooleanRef loginCompleted;
    loginCompleted = CFDictionaryGetValue (sessionInfo,
                                           kCGSessionLoginDoneKey);

    CFStringRef output;
    output = 
        CFStringCreateWithFormat (kCFAllocatorDefault, NULL,
                                  CFSTR("%@/%d active:%d logindone:%d"),
                                  shortUserName, userUID,
                                  CFBooleanGetValue(userIsActive),
                                  CFBooleanGetValue(loginCompleted));
    CFShow (output);

    return (EXIT_SUCCESS);

} // main

/* got:

% ./cgsession
markd/503 active:1 logindone:1

From an ssh session:
% ./cgsession
can't get session dictionary

Active:
borkbook-2:tmp bignerdranch$ ./cgsession 
bignerdranch/502 active:1 logindone:1

FUS out:
borkbook-2:tmp bignerdranch$ sleep 30; ./cgsession
bignerdranch/502 active:0 logindone:1
*/
