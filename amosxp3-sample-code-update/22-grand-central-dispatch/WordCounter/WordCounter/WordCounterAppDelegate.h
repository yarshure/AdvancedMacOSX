#import <Cocoa/Cocoa.h>

@interface WordCounterAppDelegate : NSObject <NSApplicationDelegate>

@property (unsafe_unretained) IBOutlet NSWindow *window;
@property (unsafe_unretained) IBOutlet NSTextView *wordsView;
@property (unsafe_unretained) IBOutlet NSTextField *countLabel;
@property (unsafe_unretained) IBOutlet NSTextField *uniqueLabel;
@property (unsafe_unretained) IBOutlet NSButton *countButton;
@property (unsafe_unretained) IBOutlet NSProgressIndicator *spinner;

- (IBAction) count: (id) sender;

@end // WordCounterAppDelegate
