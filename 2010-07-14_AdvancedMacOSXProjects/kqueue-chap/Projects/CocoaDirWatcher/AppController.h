// AppController.h -- CocoaDirWatcher's controller object

#import <Cocoa/Cocoa.h>

@interface AppController : NSObject
{
    // directory changed messages are appended to this
    IBOutlet NSTextView *logview;

    // file descriptor for the directory-watching kqueue
    int kqfd;

    // the socket placed into the runloop
    CFSocketRef	 runLoopSocket;
}

// tell the user some activity has happened on the given
// path.  It NSLog()s the information and appends it to
// the logView

- (void) logActivity: (NSString *) path;

@end // AppController


