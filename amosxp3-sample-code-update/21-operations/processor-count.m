#import <errno.h>      // for errno
#import <stdio.h>      // for printf()
#import <stdlib.h>     // for EXIT_SUCCESS
#import <string.h>     // for strerror
#import <sys/sysctl.h> // for sysctlbyname()
#import <sys/types.h>

// clang -Weverything -o processor-count processor-count.m


static int processorCount () {
    int processorCount = 1;

#define MAX_CACHE_DEPTH 10
    int64_t cacheconfig[MAX_CACHE_DEPTH];
    size_t size = sizeof(cacheconfig);

    int result = sysctlbyname("hw.cacheconfig", &cacheconfig[0], &size,
                              NULL, 0);  // new value, not used
    if (result == -1) {
        printf("sysctlbyname returned error: %d/%s\n",
               errno, strerror(errno));
    } else {
        processorCount = (int)cacheconfig[0];
    }

#ifdef INTERESTING_STUFF
    // Tells the number of processes that share a particular kind of cache
    printf ("L1 cache sharing: %ld\n", cacheconfig[1]);
    printf ("L2 cache sharing: %ld\n", cacheconfig[2]);
    printf ("L3 cache sharing: %ld\n", cacheconfig[3]);
#endif

    return processorCount;

} // processorCount


int main (void) {
    printf ("processors: %d\n", processorCount());

    return (EXIT_SUCCESS);

} // main
