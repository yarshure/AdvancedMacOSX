#import <errno.h>      // for errno
#import <stdio.h>      // for printf()
#import <stdlib.h>     // for EXIT_SUCCESS
#import <string.h>     // for strerror
#import <sys/sysctl.h> // for sysctlbyname()
#import <sys/types.h>

/* compile with
gcc -Wall -o processor-count processor-count.m
*/

static int processorCount () {
    int processorCount = 1;

    int count;
    size_t size = sizeof(count);

    int result = sysctlbyname("hw.cacheconfig", &count, &size,
                              NULL, 0);  // new value, not used
    if (result == -1) {
        printf("sysctlbyname returned error: %d/%s\n",
               errno, strerror(errno));
    } else {
        processorCount = count;
    }
    
    return processorCount;

} // processorCount


int main (void) {
    printf ("processors: %d\n", processorCount());

    return (EXIT_SUCCESS);

} // main
