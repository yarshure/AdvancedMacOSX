#import "AppController.h"

#import "PeekerProtocol.h"

@implementation AppController

// Common "clean up our mess" method.

- (void) cleanup {
    NSConnection *connection = [proxy connectionForProxy];

    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [connection invalidate];
    [proxy release];
    proxy = nil;

} // cleanup


// Reach out and touch the remote server.

- (void) connect {
    // Use mach ports for communication, since we're local.
    NSConnection *connection =
        [NSConnection connectionWithRegisteredName: kFilePeekerPortName
                      host: nil];

    [connection setRequestTimeout: 10.0];
    [connection setReplyTimeout: 10.0];

    @try {
        proxy = [[connection rootProxy] retain];
        
        [[NSNotificationCenter defaultCenter]
            addObserver: self
            selector: @selector (connectionDown:)
            name: NSConnectionDidDieNotification
            object: connection];

        [proxy setProtocolForProxy: @protocol(PeekerProtocol)];
    }
    @catch (NSException *e) {
        NSLog (@"Could not connect: %@", e);
        [self cleanup];
    }

} // connect


- (IBAction) getListing: (id) sender {
    if (!proxy) {
        [self connect];
        if (!proxy) return;
    }

    NSString *path = [pathField stringValue];

    NSArray *stuff = nil;

    @try {
        stuff = [proxy dirListingAtPath: path];
    }
    @catch (NSException *e) {
        NSLog (@"getListing error: %@", e);
    }

    NSLog (@"stuff: %@", stuff);
    
} // getListing


- (IBAction) getData: (id) sender {
    if (!proxy) {
        [self connect];
        if (!proxy) return;
    }

    NSString *path = [pathField stringValue];

    NSData *stuff = nil;

    @try {
        stuff = [proxy bytesFromFileAtPath: path];
    }
    @catch (NSException *e) {
        NSLog (@"getData error: %@", e);
    }

    NSString *string = [[[NSString alloc] initWithData: stuff
                                          encoding: NSUTF8StringEncoding]
                           autorelease];
    NSLog (@"stuff: %@", string);
    
} // getListing


- (void) awakeFromNib {
    [self connect];

} // awakeFromNib


// The system, is down. down down down.
- (void) connectionDown: (NSNotification *) notification {
    NSLog (@"connection down");
    [self cleanup];
} // connectionDown


- (NSApplicationTerminateReply) 
    applicationShouldTerminate: (NSApplication *) app {
    [[proxy connectionForProxy] invalidate];
    [self cleanup];

    return (NSTerminateNow);

} // applicationShouldTerminatex


- (void) dealloc {
    [self cleanup];
    [super dealloc];
} // dealloc

@end // AppController

