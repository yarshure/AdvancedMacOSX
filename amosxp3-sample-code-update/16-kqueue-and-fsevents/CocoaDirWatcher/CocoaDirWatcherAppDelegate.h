#import <Cocoa/Cocoa.h>

@interface CocoaDirWatcherAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *__weak _window; // from template

    // Directory changed messages are appended here.
    IBOutlet NSTextView *__unsafe_unretained _logView;
        
    // File descriptor for the directory-watching kqueue.
    int _kqfd;
                
    // The socket placed into the runloop
    CFSocketRef _runLoopSocket;
}

@property (weak) IBOutlet NSWindow *window;
@property (unsafe_unretained) IBOutlet NSTextView *logView;

@end // CocoaDirWatcherAppDelegate
