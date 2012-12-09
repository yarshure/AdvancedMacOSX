#import <Cocoa/Cocoa.h>

@interface AppController : NSObject
{
    IBOutlet NSTextView	*inText;
    IBOutlet NSTextView	*outText;
}

- (IBAction) sort: (id) sender;

@end // AppController


