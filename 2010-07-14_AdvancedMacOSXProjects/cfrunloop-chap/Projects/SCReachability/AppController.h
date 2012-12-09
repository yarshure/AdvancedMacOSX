// AppController.h -- SysConfig reachability example

#import <Cocoa/Cocoa.h>
#import <SystemConfiguration/SystemConfiguration.h>

@interface AppController : NSObject
{
    // the runloop entity that will notify us about changes
    // in network connectivity
    SCNetworkReachabilityRef reacher;

    IBOutlet NSTextField *reachabilityField;
}

@end // AppController
