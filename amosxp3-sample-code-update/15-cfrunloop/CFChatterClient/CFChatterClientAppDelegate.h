#import <Cocoa/Cocoa.h>

@interface CFChatterClientAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *__weak window;

    IBOutlet NSTextField *_usernameField;
    IBOutlet NSTextField *_hostField;
    IBOutlet NSButton    *_joinLeaveButton;

    IBOutlet NSTextView	 *_transcript;
    IBOutlet NSTextField *_messageField;
    IBOutlet NSButton    *_sendButton;

    CFSocketNativeHandle  _sockfd;
    CFSocketRef _socketRef;
}
@property (nonatomic, weak) IBOutlet NSWindow *window;
@property (nonatomic, readonly, getter=isConnected) BOOL connected;

- (IBAction) sendMessage: (id) sender;
- (IBAction) join: (id) sender;
- (IBAction) leave: (id) sender;

@end // CFChatterClientAppDelegate
