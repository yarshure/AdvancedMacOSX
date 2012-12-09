#import <Cocoa/Cocoa.h>

@interface AppController : NSObject
{
    IBOutlet NSButton *button;
    IBOutlet NSTextField *hostField;
    IBOutlet NSTextView *textView;
    NSPipe *pipe;
    NSTask *task;
}
- (IBAction)startStop:(id)sender;
- (void)dataReady:(NSNotification *)note;
- (void)taskTerminated:(NSNotification *)note;
- (void)appendData:(NSData *)d;
- (void)cleanup;
@end

