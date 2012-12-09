#import <Cocoa/Cocoa.h>

#ifndef MAC_OS_X_VERSION_10_6
@protocol NSApplicationDelegate @end
#endif

@interface AppController : NSObject <NSApplicationDelegate>
{
    IBOutlet NSTextField *usernameField;
    IBOutlet NSTextField *hostField;
    IBOutlet NSButton    *joinLeaveButton;

    IBOutlet NSTextView	 *transcript;
    IBOutlet NSTextField *messageField;
    IBOutlet NSButton    *sendButton;

    CFSocketNativeHandle  sockfd;
    CFSocketRef socket;
}
@property(nonatomic, readonly, getter=isConnected) BOOL connected;

- (IBAction)sendMessage:(id)sender;
- (IBAction)join:(id)sender;
- (IBAction)leave:(id)sender;
@end  // AppController
