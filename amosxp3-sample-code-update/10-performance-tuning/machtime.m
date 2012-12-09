// machtime.m -- exercise mach_absolute_time()

#import <mach/mach_time.h>  // for mach_absolute_time() and friends
#import <stdio.h>           // for printf()
#import <stdlib.h>          // for abort()

// clang -g -Weverything -o machtime machtime.m

int main (void) {
    uint64_t start = mach_absolute_time ();

    mach_timebase_info_data_t info;

    if (mach_timebase_info (&info) == KERN_SUCCESS) {
        printf ("scale factor : %u / %u\n", info.numer, info.denom);
    } else {
        printf ("mach_timebase_info failed\n");
        abort ();
    }

    uint64_t end = mach_absolute_time ();
    uint64_t elapsed = end - start;
    uint64_t nanos = elapsed * info.numer / info.denom;

    printf ("elapsed time was %lld nanoseconds\n", nanos);

    return 0;

} // main
