#import <Cocoa/Cocoa.h>
#import <SystemConfiguration/SystemConfiguration.h>

@interface SCFMonitorAppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSTextField *hostnameField;
@property (weak) IBOutlet NSTextField *consoleUserField;
@property (weak) IBOutlet NSTextField *localIPField;

@end // SCFMonitorAppDelegate
