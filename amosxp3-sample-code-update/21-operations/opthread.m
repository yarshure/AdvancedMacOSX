// play with operatons and see how many threads are actually generated 
// by looking in Activity Monitor.

#import <Foundation/Foundation.h>


// clang -g -Weverything -framework Foundation -o opthread opthread.m


typedef enum NullOpBehavior {
    kSleep,
    kLoop,
} NullOpBehavior;

@interface Operation : NSOperation {
    NullOpBehavior behavior;
    int sequence;
}

- (id) initWithBehavior: (NullOpBehavior) b;

@end // Operation


@implementation Operation

- (id) initWithBehavior: (NullOpBehavior) b {
    static volatile int seq;
    if ((self = [super init])) {
        behavior = b;
        @synchronized([self class]) {
            sequence = seq++;
        }
    }
    return (self);
    
} // initWithBehavior


- (void)main {
    static volatile int g_count;

    @synchronized([self class]) {
        g_count++;
//        NSLog(@"starting op %d - count %d", sequence, g_count);
    }
    
    if (behavior == kSleep) {
        sleep(10);
        
    } else if (behavior == kLoop) {
        int i;
        for (i = 0; i < 1000000000; i++) ;
    }

    @synchronized([self class]) {
        g_count--;
//        NSLog(@"done with op %d - count %d", sequence, g_count);
    }
} // main

@end // Operation



int main (int argc, const char *argv[]) {
    [[NSAutoreleasePool alloc] init];

    if (argc != 4) {
        printf ("usage: %s [-sleep|-loop] queueCount opCount\n", argv[0]);
        return EXIT_FAILURE;
    }

    NullOpBehavior behavior;
    if (strcmp(argv[1], "-sleep") == 0) {
        behavior = kSleep;
    } else if (strcmp(argv[1], "-loop") == 0) {
        behavior = kLoop;
    } else {
        printf ("bad null op type\n");
        return EXIT_FAILURE;
    }

    int queueCount = atoi(argv[2]);
    int opCount = atoi(argv[3]);

    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount: queueCount];

    int i;
    for (i = 0; i < opCount; i++) {
        Operation *blah = [[[Operation alloc] initWithBehavior:behavior]
                              autorelease];
        [queue addOperation: blah];
    }

    // Wait for stuff to finish;
    sleep (20);

    return EXIT_SUCCESS;

} // main
