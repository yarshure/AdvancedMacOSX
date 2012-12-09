// synchronied.m -- use the @synchronized() directive to protect
//	            mutable array object insertion

#import <Foundation/Foundation.h>

/* compile with:
gcc -g -fobjc-exceptions -framework Foundation -o synchronized synchronized.m
*/

// tweak these so that things break on your system.

// how many threads to run
#define THREAD_COUNT 10

// how many items each thread adds to the array 
#define ITEM_COUNT 5000

// how long to wait for the threads to complete
#define SLEEP_TIME 3


// a ThreadRunner object is the target object for each of the threads

@interface ThreadRunner : NSObject
{
    NSMutableArray *array;  // array too add NSNumbers to
    BOOL synchronized;	    // use @synchronized?
}

- (void) runThread: (id) object;
- (void) setSynchronized: (BOOL) yOrN;
- (int) arrayCount;

@end // ThreadRunner


@implementation ThreadRunner


- (id) init
{
    if (self = [super init]) {
        array = [[NSMutableArray alloc] init];
        // synchronized defaults to NO
    }

    return (self);

} // init


- (void) dealloc
{
    [array release];
    [super dealloc];

} // dealloc


- (void) setSynchronized: (BOOL) yOrN
{
    synchronized = yOrN;
} // setSynchronized


- (void) runThread: (id) object
{
    int i;

    if (synchronized) {
        for (i = 0; i < ITEM_COUNT; i++) {
            NSNumber *number = [[NSNumber alloc] initWithInt: i];

            // this is a thread-safe operation
            @synchronized (array) {
                [array insertObject: number  atIndex: i];
            }
        }
        
    } else {
        for (i = 0; i < ITEM_COUNT; i++) {
            NSNumber *number = [[NSNumber alloc] initWithInt: i];

            // this is not thread-safe
            [array insertObject: number  atIndex: i];
        }
    }

    NSLog (@"done!");

} // runThread


- (int) arrayCount
{
    return ([array count]);
} // arrayCount

@end // ThreadRunner


int main (int argc, const char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    // make a single object to be abused by multiple threads
    ThreadRunner *runner = [[ThreadRunner alloc] init];
    if (argc != 1) {
        [runner setSynchronized: YES];
    }

    // spin off the threads
    int i;
    for (i = 0; i < THREAD_COUNT; i++) {
        NSThread *thread;
        [NSThread detachNewThreadSelector: @selector(runThread:)
                  toTarget: runner
                  withObject: nil];
    }

    // hang out for awhile
    sleep (SLEEP_TIME);

    // should be THREAD_COUNT * ITEM_COUNT
    NSLog (@"count is %d", [runner arrayCount]);

    [pool release];

    return (0);

} // main


