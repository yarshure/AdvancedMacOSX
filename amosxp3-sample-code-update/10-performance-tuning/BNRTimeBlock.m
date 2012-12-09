#import <mach/mach_time.h>  // for mach_absolute_time() and friends

#import <stdio.h>   // for printf
#import <stdlib.h>  // for system
#import <Foundation/Foundation.h>  // for CGFloat

// clang -g -Weverything -o BNRTimeBlock BNRTimeBlock.m

CGFloat BNRTimeBlock (void (^block)(void));


CGFloat BNRTimeBlock (void (^block)(void)) {
    mach_timebase_info_data_t info;
    if (mach_timebase_info(&info) != KERN_SUCCESS) return -1.0;

    uint64_t start = mach_absolute_time ();
    block ();
    uint64_t end = mach_absolute_time ();
    uint64_t elapsed = end - start;

    uint64_t nanos = elapsed * info.numer / info.denom;
    return (CGFloat)nanos / NSEC_PER_SEC;

} // BNRTimeBlock


int main (void) {
    CGFloat seconds = BNRTimeBlock (^{
            system ("ls -l");
        });

    printf ("\n ls -l took %f seconds\n", seconds);
    return 0;

} // main
