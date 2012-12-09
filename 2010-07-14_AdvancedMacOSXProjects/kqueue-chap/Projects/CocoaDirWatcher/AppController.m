#import "AppController.h"

#import <sys/event.h>  // for kqueue() and kevent()
#import <errno.h>      // for errno
#import <strings.h>    // for strerror()

@implementation AppController


// some activity has happened on the kqueue file descriptor.
// call kevent() to pick up the new event waiting for us

void socketCallBack (CFSocketRef socketref, CFSocketCallBackType type,
		     CFDataRef address, const void *data, void *info)
{
    AppController *me = (AppController *) info;

    struct kevent event;

    // because this function is inside of @implementation AppController,
    // we can dig into the object structure without complaints from
    // the compiler

    if (kevent(me->kqfd, NULL, 0, &event, 1, NULL) == -1) {
        NSLog (@"could not pick up event.  Error is %d/%s",
               errno, strerror(errno));

    } else {
        [me logActivity: (NSString *)event.udata];
    }

} // socketCallBack


// add the given directory to the kqueue for watching

- (void) watchDirectory: (NSString *) dirname
{
    int dirfd;
    dirfd = open ([dirname UTF8String], O_RDONLY);

    if (dirfd == -1) {
        NSLog (@"could not open %@.  Error is %d/%s",
               dirname, errno, strerror(errno));
    }

    struct kevent direvent;
    EV_SET (&direvent,
            dirfd,
            EVFILT_VNODE,
            EV_ADD | EV_CLEAR | EV_ENABLE,
            NOTE_WRITE,
            0,
            [dirname copy]);

    // register event
    if (kevent(kqfd, &direvent, 1, NULL, 0, NULL) == -1) {
        NSLog (@"could not kevent watching %@.  Error is %d/%s",
               dirname, errno, strerror(errno));
    }
    
} // watchDirectory


// add the file descriptor to the runloop.  When activity happens
// (such as new data on a socket, or a new event in a kqueue()),
// call the socketCallBack function.

- (void) addFileDescriptorMonitor: (int) fd
{
    CFSocketContext context = { 0, self, NULL, NULL, NULL };
    CFRunLoopSourceRef rls;

    runLoopSocket = CFSocketCreateWithNative (NULL,
					      fd,
					      kCFSocketReadCallBack,
					      socketCallBack,
					      &context);
    if (runLoopSocket == NULL) {
        NSLog (@"could not CFSocketCreateWithNative");
	goto bailout;
    }

    rls = CFSocketCreateRunLoopSource (NULL, runLoopSocket, 0);
    if (rls == NULL) {
        NSLog (@"could not create a run loop source");
	goto bailout;
    }

    CFRunLoopAddSource (CFRunLoopGetCurrent(), rls,
			kCFRunLoopDefaultMode);
    CFRelease (rls);

bailout:
    return;
    
} // addFileDescriptorMonitor


// program is cranking up.  Watch a couple of directories

- (void) awakeFromNib
{
    kqfd = kqueue ();

    if (kqfd == -1) {
        NSLog (@"could not create kqueue.  Error is %d/%s",
               errno, strerror(errno));
    }

    [self watchDirectory: @"/tmp"];
    [self watchDirectory: NSHomeDirectory()];
    [self watchDirectory: 
              [@"~/Library/Preferences" stringByExpandingTildeInPath]];

    [self addFileDescriptorMonitor: kqfd];
    
} // awakeFromNib


// inform the user that something interesting happened to path

- (void) logActivity: (NSString *) path
{
    // log it to the console
    NSLog (@"activity on %@", path);

    // and also append the path to the textview
    NSAttributedString *astring;

    astring = [[NSAttributedString alloc] initWithString: path];
    [[logview textStorage] appendAttributedString: astring];
    [astring release];

    astring = [[NSAttributedString alloc] initWithString: @"\n"];
    [[logview textStorage] appendAttributedString: astring];
    [astring release];

    NSRange endPoint;
    endPoint = NSMakeRange ([[logview string] length], 0);

    [logview scrollRangeToVisible: endPoint];

} // logActivity


@end // AppController

