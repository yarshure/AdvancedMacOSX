#import "CocoaDirWatcherAppDelegate.h"

#import <sys/event.h>  // for kqueue() and kevent()
#import <errno.h>      // for errno
#import <strings.h>    // for strerror()


@interface CocoaDirWatcherAppDelegate ()
// Add a property for the kqueue file descriptor.  This will let the runloop callback
// function to get the fd.
@property (assign) int kqfd;
@end // extension

@implementation CocoaDirWatcherAppDelegate

@synthesize window = _window;
@synthesize logView = _logView;
@synthesize kqfd = _kqfd;

// Inform the user that something interesting happened to path
- (void) logActivity: (NSString *) path {
    // log it to the console
    NSLog (@"activity on %@", path);

    // Add it to the text view.
    [self.logView.textStorage.mutableString appendString: path];
    [self.logView.textStorage.mutableString appendString: @"\n"];
        
    // Scroll to the end
    NSRange endPoint = NSMakeRange ([[self.logView string] length], 0);
    [self.logView scrollRangeToVisible: endPoint];
        
} // logActivity


// Some activity has happened on the kqueue file descriptor.
// Call kevent() to pick up the new event waiting for us
void socketCallBack (CFSocketRef socketref, CFSocketCallBackType type,
                     CFDataRef address, const void *data, void *info) {
    CocoaDirWatcherAppDelegate *me = (__bridge CocoaDirWatcherAppDelegate *) info;
        
    struct kevent event;
    if (kevent(me.kqfd, NULL, 0, &event, 1, NULL) == -1) {
        NSLog (@"could not pick up event.  Error is %d/%s",
               errno, strerror(errno));
    } else {
        [me logActivity: (__bridge NSString *)event.udata];
    }
        
} // socketCallBack


// Add the given directory to the kqueue for watching
- (void) watchDirectory: (NSString *) dirname {
    int dirfd = open ([dirname fileSystemRepresentation], O_RDONLY);
        
    if (dirfd == -1) {
        NSLog (@"could not open %@.  Error is %d/%s",
               dirname, errno, strerror(errno));
        return;
    }
        
    struct kevent direvent;
    EV_SET (&direvent,
            dirfd,
            EVFILT_VNODE,
            EV_ADD | EV_CLEAR | EV_ENABLE,
            NOTE_WRITE,
            0, (void *)CFBridgingRetain([dirname copy]));
        
    // Register event.
    if (kevent(self.kqfd, &direvent, 1, NULL, 0, NULL) == -1) {
        NSLog (@"could not kevent watching %@.  Error is %d/%s",
               dirname, errno, strerror(errno));
    }
        
} // watchDirectory


// Add the file descriptor to the runloop.  When activity happens,
// such as new data on a socket or a new event in a kqueue(),
// call the socketCallBack function.
- (void) addFileDescriptorMonitor: (int) fd {
    CFSocketContext context = { 0, (__bridge void *)(self), NULL, NULL, NULL };
        
    _runLoopSocket = CFSocketCreateWithNative (kCFAllocatorDefault,
                                               fd,
                                               kCFSocketReadCallBack,
                                               socketCallBack,
                                               &context);
    if (_runLoopSocket == NULL) {
        NSLog (@"could not CFSocketCreateWithNative");
        goto bailout;
    }
        
    CFRunLoopSourceRef rls = CFSocketCreateRunLoopSource (kCFAllocatorDefault,
                                                          _runLoopSocket, 0);
    if (rls == NULL) {
        NSLog (@"could not create a run loop source");
        goto bailout;
    }
        
    CFRunLoopAddSource (CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
    CFRelease (rls);
        
bailout:
    return;
        
} // addFileDescriptorMonitor


- (void) applicationDidFinishLaunching: (NSNotification *) notification {
    self.kqfd = kqueue ();
        
    if (self.kqfd == -1) {
        NSLog (@"could not create kqueue.  Error is %d/%s",
               errno, strerror(errno));
        [[NSApplication sharedApplication] terminate: self];
    }
        
    [self watchDirectory: @"/tmp"];
    [self watchDirectory: NSHomeDirectory()];
    [self watchDirectory: [@"~/Library/Preferences" stringByExpandingTildeInPath]];
        
    [self addFileDescriptorMonitor: self.kqfd];
        
} // applicationDidFinishLaunching

@end // CocoaDirWatcherAppDelegate
