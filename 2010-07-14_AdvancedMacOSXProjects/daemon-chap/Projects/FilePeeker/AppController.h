#import <Cocoa/Cocoa.h>

@interface AppController : NSObject {
    id proxy;	// The remote FilePeeker object
    IBOutlet NSTextField *pathField;
}

- (IBAction) getListing: (id) sender;
- (IBAction) getData: (id) sender;

@end // AppController

