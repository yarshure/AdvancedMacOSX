// Main file for the File Peeker Daemon.

#import <Foundation/Foundation.h>

#import "ConnectionMonitor.h"
#import "FilePeekerD.h"

#import "PeekerProtocol.h"

#import <launch.h>

// Talk to launchd and get a mach port we can use to communicate throught.
static NSPort *getPortFromLaunchd () {
    launch_data_t message = launch_data_new_string (LAUNCH_KEY_CHECKIN);

    launch_data_t response = launch_msg (message);

    if (response == NULL) return (nil);
    if (launch_data_get_type(response) == LAUNCH_DATA_ERRNO) {
        return (nil);
    }

    launch_data_t service =
        launch_data_dict_lookup (response, LAUNCH_JOBKEY_MACHSERVICES);
    if (service == NULL) return (nil);

    const char *bootstrapName = [kFilePeekerPortName UTF8String];
    launch_data_t bootyname = launch_data_dict_lookup (service, bootstrapName);
    if (bootyname == NULL) return (nil);

    // Doesn't work with 10.4 SDK.
    mach_port_t port = launch_data_get_machport (bootyname);

    if (port == MACH_PORT_NULL) return (nil);

    return ([NSMachPort portWithMachPort: port]);

} // getPortFromLaunchd



int main (int argc, const char *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    ConnectionMonitor *monitor = [[[ConnectionMonitor alloc] init] autorelease];
    FilePeekerD *peeker = [[[FilePeekerD alloc] init] autorelease];

    NSPort *receivePort = nil;
    BOOL launchd = NO;
    if (argc >= 2) {
        if (strcmp(argv[1], "-launchd") == 0) {
            launchd = YES;
            receivePort = getPortFromLaunchd ();
        }
    }

    if (receivePort == nil) receivePort = [NSMachPort port];

    if (receivePort == nil) {
        NSLog (@"receive port could not be made");
    }

    NSConnection *connection =
        [NSConnection connectionWithReceivePort: receivePort
                      sendPort: nil];

    if (!launchd) {
        if (![connection registerName: kFilePeekerPortName]) {
            NSLog (@"could not register name");
        }
    }
    [connection setRootObject: peeker];

    [connection setDelegate: monitor];
    [[NSNotificationCenter defaultCenter]
        addObserver: monitor
        selector: @selector(connectionDidDie:)
        name: NSConnectionDidDieNotification
        object: nil];
    
    [[NSRunLoop currentRunLoop] run];

    [pool release];

    return (0);

} // main
