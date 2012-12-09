#import <Cocoa/Cocoa.h>
#import <SystemConfiguration/SystemConfiguration.h>

// Substitute empty protocol for versions prior to 10.6.
#ifndef MAC_OS_X_VERSION_10_6
@protocol NSApplicationDelegate @end
#endif

@interface AppController : NSObject <NSApplicationDelegate>
{
    IBOutlet NSTextField *hostnameField;
    IBOutlet NSTextField *consoleUserField;
    IBOutlet NSTextField *localIPField;

    __strong SCDynamicStoreRef dynamicStore;
    CFRunLoopSourceRef storeChangeSource;
}
@end // AppController
