#import "AppController.h"

// display a set of connection flags

void printFlags (SCNetworkConnectionFlags flags)
{
    // for absolutely no connection, we get passed zero
    NSLog (@"flags: %d", flags);

    if (flags & kSCNetworkFlagsTransientConnection) {
        NSLog (@"    transient connection");
    }
    if (flags & kSCNetworkFlagsReachable) {
        NSLog (@"    reachable");
    }
    if (flags & kSCNetworkFlagsConnectionRequired) {
        NSLog (@"    connection requred");
    }
    if (flags & kSCNetworkFlagsConnectionAutomatic) {
        NSLog (@"    connection automatic");
    }
    if (flags & kSCNetworkFlagsInterventionRequired) {
        NSLog (@"    intervention required");
    }
    if (flags & kSCNetworkFlagsIsLocalAddress) {
        NSLog (@"    local address");
    }
    if (flags & kSCNetworkFlagsIsDirect) {
        NSLog (@"    is direct");
    }

} // printFlags


@implementation AppController

// poulate a text field indicating the current network reachability
// state.  Also colorize it for fun

- (void) updateUIForFlags: (SCNetworkConnectionFlags) flags
{
    NSColor *textColor = nil;

    if (flags == 0) {
        [reachabilityField setStringValue: @"Network not reachable"];
        textColor = [NSColor redColor];

    } else if (flags & kSCNetworkFlagsReachable) {

        if (flags & kSCNetworkFlagsConnectionRequired
            || flags & kSCNetworkFlagsConnectionAutomatic
            || flags & kSCNetworkFlagsInterventionRequired) {
            [reachabilityField setStringValue:
                                   @"Network conditionally reachable"];
            textColor = [NSColor orangeColor];

        } else {
            [reachabilityField setStringValue: @"Network Reachable"];
            textColor = [NSColor greenColor];
        }
    }

    [reachabilityField setTextColor: textColor];

} // updateUIForFlags


// the callback is invoked from the runloop when there's been a change
// in the reachability to the addresss in the reachabiliyt ref

void reachabilityCallback (SCNetworkReachabilityRef target,
                           SCNetworkConnectionFlags flags,
                           void *userInfo)
{
    printFlags (flags);

    AppController *controller = (__bridge AppController *) userInfo;
    [controller updateUIForFlags: flags];

} // reachabilityCallback


// make a new reachability thingie and install it into the runloop

- (void) scheduleReachabilityCallback
{
    // interested in reaching the Big Nerd Ranch website

    reacher = SCNetworkReachabilityCreateWithName
        (kCFAllocatorDefault, "www.bignerdranch.com");

    SCNetworkReachabilityContext context = { 0, (__bridge void *)(self), NULL, NULL, NULL };

    Boolean status;
    status = SCNetworkReachabilitySetCallback (reacher, 
                                               reachabilityCallback,
                                               &context);
    if (status == FALSE) {
        NSLog (@"could not set reachability callback");
        goto done;
    }

    // install into the runloop

    status = SCNetworkReachabilityScheduleWithRunLoop
        (reacher,
         [[NSRunLoop currentRunLoop] getCFRunLoop],
         kCFRunLoopDefaultMode);

    if (status == FALSE) {
        NSLog (@"could not schedule reachability callback");
    }

done:
    if (status == FALSE) {
        // could not do our work for some reason, so clean
        // up and bail out
        CFRelease (reacher);
        reacher = NULL;
    }

} // scheduleReachabilityCallback


- (void) awakeFromNib
{
    [self scheduleReachabilityCallback];

} // awakeFromNib


// clean up our mess

- (void) dealloc
{
    // remove the reachability notification from the run loop
    (void) SCNetworkReachabilityScheduleWithRunLoop
        (reacher,
         [[NSRunLoop currentRunLoop] getCFRunLoop],
         kCFRunLoopDefaultMode);

    // we got it from a Create or a Copy, so we have to release it
    CFRelease (reacher);


} // dealloc


@end // AppController


