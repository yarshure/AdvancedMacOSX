// dispatch_iterate.m -- iterate over an array doing work.

// clang -g -Weverything -o dispatch_iterate dispatch_iterate.m

#import <dispatch/dispatch.h>  // for GCD
#import <mach/mach_time.h>
#import <stdio.h> // for printf()

enum {
    kNumberCount = 2000000,
    kStride = 1000,
    kCountCount = 10,
    kSleepTime = 0
};

static int numbers[kNumberCount];
int results2[kNumberCount];

#undef MIN // existing MIN macro causes -Weverything warnings due to GNU extension.
#define MIN(x,y) ((x) < (y) ? (x) : (y))


typedef double CGFloat;

static CGFloat BNRTimeBlock (void (^block)(void)) {
    mach_timebase_info_data_t info;
    if (mach_timebase_info(&info) != KERN_SUCCESS) return -1.0;

    uint64_t start = mach_absolute_time ();
    block ();
    uint64_t end = mach_absolute_time ();
    uint64_t elapsed = end - start;

    uint64_t nanos = elapsed * info.numer / info.denom;
    return (CGFloat)nanos / NSEC_PER_SEC;

} // BNRTimeBlock


static int Work (int *data, size_t index) {
    return data[index] * 2;
} // Work


int main (void) {
    // Initialize numbers
    printf ("STARTING!\n");

    for (int i = 0; i < kNumberCount; i++) {
        numbers[i] = i;
    }

    printf ("INIT!\n");
    sleep (kSleepTime);
    printf ("STARTING iterate!\n");

    // Iterative
    int *results = results2;
    for (int count = 0; count < kCountCount; count++) {
        for (size_t i = 0; i < kNumberCount; i++) {
            results[i] = Work (numbers, i);
        }
    }

    printf ("DONE iterate!\n");
    sleep (kSleepTime);
    printf ("STARTING dispatch!\n");

    dispatch_queue_t queue =
        dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    CGFloat time = BNRTimeBlock (^{
            for (int count = 0; count < kCountCount; count++) {
                dispatch_apply (kNumberCount, queue, ^(size_t index) {
                        results[index] = Work (numbers, index);
                    });
            }
        });
        
    printf ("DONE dispatch!  Took %f seconds\n", time);
    sleep (kSleepTime);
    printf ("STARTING dispatch-stride\n");

    time = BNRTimeBlock (^{
            for (int count = 0; count < kCountCount; count++) {
                dispatch_apply (kNumberCount / kStride, queue, ^(size_t index) {
                        size_t jindex = index * kStride;
                        size_t jStop = MIN(jindex + kStride, kNumberCount);
                        while (jindex < jStop) {
                            results[jindex] = Work (numbers, jindex);
                            jindex++;
                        }
                    });
            }
        });

    printf ("DONE dispatch-stride.  Took %f seconds\n", time);

    return 0;

} // main
