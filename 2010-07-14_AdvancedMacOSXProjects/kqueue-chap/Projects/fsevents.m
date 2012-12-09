// fsevents.m -- Watch file system events.

/* compile with
gcc -g -Wall -framework Foundation -framework CoreServices -o fsevents fsevents.m
*/

#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>  // For FSEvents()
#import <sys/stat.h>  // for stat()

// Dump out all historic events before exiting after seeing N new
// events.
#define MAX_CALLBACKS 20
static BOOL gNewEvents = YES;

// String constants so typos won't cause debugging headaches.
#define LAST_EVENT_KEY @"fseventsSampleLastEvent"
#define DEVICE_UUID_KEY @"fseventsSampleDeviceUUID"


// Somewhat compact way to display the flags that are set.
typedef struct FlagMap {
    int bitflag;
    const char *description;
} FlagMap;


static FlagMap flagmap[] = {
    { kFSEventStreamEventFlagMustScanSubDirs, "must scan subdirs. bummer" },
    { kFSEventStreamEventFlagUserDropped,
      "  because user dropped the ball" },
    { kFSEventStreamEventFlagKernelDropped,
      "  because the kernel dropped the ball" },
    { kFSEventStreamEventFlagEventIdsWrapped,
      "event id's wrapped. whoa." },
    { kFSEventStreamEventFlagHistoryDone, "history playback done" },
    { kFSEventStreamEventFlagRootChanged, "root changed" },
    { kFSEventStreamEventFlagMount, "Mounties!" },
    { kFSEventStreamEventFlagUnmount, "Unmounties!" }
};


static void callbackFunction (ConstFSEventStreamRef stream,
                              void *clientCallBackInfo,
                              size_t numEvents,
                              void *eventPaths,
                              const FSEventStreamEventFlags eventFlags[],
                              const FSEventStreamEventId eventIds[]) {
    printf ("-----------------\n");
    printf ("event count: %lu\n", numEvents);

    // Keep track of the eventIds so we can save it off when we're
    // done looking at events.
    FSEventStreamEventId currentEvent = 0;

    int i;
    for (i = 0; i < numEvents; i++) {
        // Add an extra blank line for breathing room.
        printf ("\n");

        // Dump out the arguments.
        printf ("path[%d] : %s : id %llu\n", 
                i, ((char **)eventPaths)[i], eventIds[i]);

        FSEventStreamEventFlags flags = eventFlags[i];
        printf ("  flags: %x\n", (int)flags);

        if (flags == kFSEventStreamEventFlagNone) {
            printf ("    something happened\n");
        }

        // Display all of the set flags.
        FlagMap *scan, *stop;
        scan = flagmap;
        stop = scan + sizeof(flagmap) / sizeof(*flagmap);
        while (scan < stop) {
            if (flags & scan->bitflag) {
                printf ("    %s\n", scan->description);
            }
            scan++;
        }

        if (flags & kFSEventStreamEventFlagHistoryDone) {
            // Woo!  We can stop printing historic events.
            gNewEvents = YES;

            // Don't drop into new event case.
            if (i == numEvents - 1) goto done;
        }

        // Remember what our last event was.
        currentEvent = eventIds[i];
    }

    // Don't count history events against our callback count.
    if (!gNewEvents) goto done;

    static int sCallbackCount;
    sCallbackCount++;

    printf ("%d left\n", MAX_CALLBACKS - sCallbackCount);

    if (sCallbackCount >= MAX_CALLBACKS) {
        NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
        
        // Save the last event ID seen into user defaults.
        NSNumber *eventIdNumber =
            [NSNumber numberWithUnsignedLongLong: currentEvent];
        [defs setObject: eventIdNumber
              forKey: LAST_EVENT_KEY];

        // Save the device UUID.
        dev_t device = FSEventStreamGetDeviceBeingWatched (stream);

        if (device != 0) {
            CFUUIDRef devUUID = FSEventsCopyUUIDForDevice (device);

            if (devUUID != NULL) {
                CFStringRef stringForm =
                    CFUUIDCreateString(kCFAllocatorDefault, devUUID);
                [defs setObject: (id)stringForm  forKey: DEVICE_UUID_KEY];
            }
            CFRelease (devUUID);
        }
        // Make sure it reaches the disk.
        [defs synchronize];

        printf ("all done!\n");
        exit (EXIT_SUCCESS);
    }
    
done:
    return;

} // callbackFunction


int main (void) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    // Watch the whole device.
    NSString *path = @"/";

    // Get the device ID.
    struct stat statbuf;
    int result = stat([path fileSystemRepresentation], &statbuf);
    if (result == -1) {
        printf ("bad stat, man.  %d\n", errno);
        return (EXIT_FAILURE);
    }
    dev_t device = statbuf.st_dev;

    // Find the last event we saw.
    FSEventStreamEventId lastEvent = kFSEventStreamEventIdSinceNow;

    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSNumber *lastEventNumber =
        [defs objectForKey: LAST_EVENT_KEY];

    if (lastEventNumber != nil) {
        // Make sure it's the right device by making sure the UUIDs
        // match.
        NSString *uuidString = [defs stringForKey: DEVICE_UUID_KEY];

        CFUUIDRef devUUID = FSEventsCopyUUIDForDevice (device);

        CFStringRef devString =
            CFUUIDCreateString (kCFAllocatorDefault, devUUID);

        if ([uuidString isEqualToString: (id)devString]) {
            // Whew, we have a good point to pick up from.
            lastEvent = [lastEventNumber unsignedLongLongValue];
            printf ("Woo!  picking up where we left off!  %llu\n",
                    lastEvent);
            // We should be getting some history then.
            gNewEvents = NO;
        } else {
            printf ("uuid mismatch: %s vs %s\n",
                    [uuidString UTF8String], [(id)devString UTF8String]);
        }
    }
    
    FSEventStreamRef stream;
    CFAbsoluteTime latency = 3.0; // latency in seconds
    NSArray *paths = [NSArray arrayWithObject: path];

    stream = FSEventStreamCreateRelativeToDevice
        (kCFAllocatorDefault,
         callbackFunction,
         NULL, // context
         device,
         (CFArrayRef)paths, // relative to device
         lastEvent,
         latency,
         kFSEventStreamCreateFlagNone);

    if (stream == NULL) {
        printf ("bad streaming, man!\n");
        return (EXIT_FAILURE);
    }

    NSRunLoop *loop = [NSRunLoop currentRunLoop];

    FSEventStreamScheduleWithRunLoop
        (stream, [loop getCFRunLoop], kCFRunLoopDefaultMode);

    BOOL success = FSEventStreamStart (stream);
    if (!success) NSLog(@"can't start");

    [loop run];

    // This isn't actually reached, but you would clean up the 
    // stream like this.
    FSEventStreamStop (stream);
    FSEventStreamUnscheduleFromRunLoop
        (stream, [loop getCFRunLoop], kCFRunLoopDefaultMode);
    FSEventStreamInvalidate (stream);
    FSEventStreamRelease (stream);

    [pool release];

    return (EXIT_SUCCESS);

} // main
