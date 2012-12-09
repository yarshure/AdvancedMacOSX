#import "CFChatterClientAppDelegate.h"

#import <errno.h>         // errno
#import <fcntl.h>         // fcntl()
#import <stdbool.h>       // true/false
#import <string.h>        // strerror()
#import <unistd.h>        // close()

#import <arpa/inet.h>     // inet_ntop()
#import <netdb.h>         // gethostbyname2()
#import <netinet/in.h>    // struct sockaddr_in
#import <netinet6/in6.h>  // struct sockaddr_in6
#import <sys/socket.h>    // socket(), AF_INET
#import <sys/types.h>     // random types

#define MAX_MESSAGE_SIZE  (UINT8_MAX)
#define READ_BUFFER_SIZE  (PAGE_SIZE)

static const in_port_t kPortNumber = 2342;
static const int kInvalidSocket = -1;

// See chatterclient.m for the definition of this function.
static int WriteMessage (int fd, const void *buffer, size_t length);

// See simpleclient.m for the definition of these two functions.
static int SocketConnectedToHostNamed (const char *hostname);
static bool GetAddressAtIndex (struct hostent *host, int addressIndex,
                               struct sockaddr_storage *outServerAddress);

#define RUN_LOOP_OBSERVER (false)
#if RUN_LOOP_OBSERVER
static void AddRunLoopObserver();
static void ObserveRunLoopActivity (CFRunLoopObserverRef,
                                    CFRunLoopActivity, void *);
#endif

// Forward references
@interface CFChatterClientAppDelegate ()

// UI
- (void) updateUI;
- (void) appendMessage: (NSString *) msg;
- (void) runErrorMessage: (NSString *) message  withErrno: (int) err;

// Connection
- (void) connectToHost: (NSString *) hostname  asUser: (NSString *) username;
- (void) closeConnection;

// Socket
- (void) startMonitoringSocket;
- (void) stopMonitoringSocket;

// Runloop stuffage
static void ReceiveMessage (CFSocketRef, CFSocketCallBackType,
                            CFDataRef, const void *, void *);
- (void) handleMessageData: (NSData *) data;

@end // extension

@implementation CFChatterClientAppDelegate
@synthesize window;

- (id) init {
    if ((self = [super init])) {
        _sockfd = kInvalidSocket;
#if RUN_LOOP_OBSERVER
        AddRunLoopObserver();
#endif  // RUN_LOOP_OBSERVER
    }
    return self;
} // init


- (void) awakeFromNib {
    // Prepopulate the username field as a convenience.x
    [_usernameField setStringValue: NSUserName()];
    [self updateUI];
} // awakeFromNib


- (void) dealloc {
    [self closeConnection];
} // dealloc


// Quit the app when the last window closes.
- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication *) app {
    return YES;
} // applicationShouldTerminateAfterLastWindowClosed


- (BOOL) isConnected {
    BOOL connected = (_socketRef != NULL);
    return connected;
} // isConnected


- (IBAction) sendMessage: (id) sender {
    if (_sockfd == kInvalidSocket)  return;

    // Add a newline to match command-line client's behavior.
    NSString *messageString =
        [[_messageField stringValue] stringByAppendingString: @"\n"];
    if (messageString.length == 1) {
        // Just the newline - don't send it.  Help prevent channel floods.
        return;
    }

    const char *message = [messageString UTF8String];
    const size_t length = strlen (message);
    int nwritten = WriteMessage (_sockfd, message, length);

    // Successful send, clear out the message field.
    if (nwritten == length) [_messageField setStringValue: @""];

} // sendMessage


// Sent by Join/Leave button when not connected.
- (IBAction) join: (id) sender {
    NSString *hostname = [_hostField stringValue];
    NSString *username = [_usernameField stringValue];
    [self connectToHost: hostname  asUser: username];

    [self updateUI];

    if ([self isConnected]) {
        NSString *connectMessage = 
            [NSString stringWithFormat: @"( * * * connected to %@ as %@ * * * ) \n",
                      hostname, username];
        [self appendMessage: connectMessage];
        [[_messageField window] makeFirstResponder: _messageField];
    }
} // subscribe


// Sent by Join/Leave button when connected.
- (IBAction) leave: (id) sender {
    [self closeConnection];

    [self updateUI];

    NSString *disconnectMessage =
        [NSString stringWithFormat: @"( * * * disconnected from %@ * * *) \n",
                  [_hostField stringValue]];
    [self appendMessage: disconnectMessage];
    [[_hostField window] makeFirstResponder: _hostField];
} // unsubscribe


- (void) updateUI {
    const BOOL connected = [self isConnected];

    // Disable username and hostname while connected.
    [_usernameField setEnabled: !connected];
    [_hostField setEnabled: !connected];

    // Join becomes Leave when connected.
    [_joinLeaveButton setTitle: connected ? @"Leave" : @"Join"];
    [_joinLeaveButton setAction: connected ? @selector(leave:) : @selector(join:)];

    // Can only type or send messages while connected.
    [_messageField setEnabled: connected];
    [_sendButton setEnabled: connected];
} // updateUI


- (void) appendMessage: (NSString *) msg {
    // Append the message.
    NSRange endOfText = NSMakeRange ([_transcript string].length, 0);
    [_transcript replaceCharactersInRange: endOfText  withString: msg];

    // Make the end of the message visible.
    endOfText = NSMakeRange ([_transcript string].length, 0);
    [_transcript scrollRangeToVisible: endOfText];
} // appendMessage


- (void) runErrorMessage: (NSString *) message  withErrno: (int) error {
    NSString *errnoString = @"";
    if (error != 0) {
        errnoString = ([NSString stringWithUTF8String: strerror(error)]);
    }
    
    NSRunAlertPanel (message, errnoString, @"OK", nil, nil);
} // runErrorMessage


- (void) connectToHost: (NSString *) hostname  asUser: (NSString *) username {
    NSString *errorMessage = nil;
    int sysError = noErr;
    
    if (_sockfd != kInvalidSocket) [self closeConnection];
    
    // sanity check our nick name before trying to connect
    if (hostname.length < 1) {
        errorMessage = @"Hostname must not be empty.";
        goto bailout;
    }
    
    if (username.length == 0 || username.length > 8) {
        errorMessage = @"Username must be between 1 and 8 characters long.";
        goto bailout;
    }
    
    const char *hostnameCStr = [hostname UTF8String];
    _sockfd = SocketConnectedToHostNamed (hostnameCStr);
    
    // UTF-8 length could be greater than the number of characters.
    const char *name = [username UTF8String];
    NSUInteger namelen = strlen (name);

    int nwritten = WriteMessage (_sockfd, name, namelen);

    if (nwritten == -1) {
        errorMessage = @"Failed to send username.";
        sysError = errno;
        goto bailout;
    }
    
    // Make the socket non-blocking.
    int err = fcntl (_sockfd, F_SETFL, O_NONBLOCK);
    if (err == -1) {
        errorMessage = @"Could not put socket into nonblocking mode.";
        sysError = errno;
        goto bailout;
    }
    
    [self startMonitoringSocket];

bailout: 
    if (errorMessage != nil) {
        [self runErrorMessage: errorMessage  withErrno: sysError];
        [self closeConnection];
    }
    return;
} // connectToHost: asUser: 


- (void) closeConnection {
    [self stopMonitoringSocket];
    close (_sockfd);
    _sockfd = kInvalidSocket;
} // closeConnection


- (void) startMonitoringSocket {
    CFSocketContext context = { 0, (__bridge void *)(self), NULL, NULL, NULL };
    _socketRef = CFSocketCreateWithNative (kCFAllocatorDefault,
                                           _sockfd,
                                           kCFSocketDataCallBack,
                                           ReceiveMessage,
                                           &context);
    if (_socketRef == NULL) {
        [self runErrorMessage: @"Unable to create CFSocketRef."  withErrno: noErr];
        goto bailout;
    }
    
    CFRunLoopSourceRef rls = 
        CFSocketCreateRunLoopSource(kCFAllocatorDefault, _socketRef, 0);
    if (rls == NULL) {
        [self runErrorMessage: @"Unable to create socket run loop source."
              withErrno: noErr];
        goto bailout;
    }
    
    CFRunLoopAddSource (CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
    CFRelease (rls);

bailout: 
    return;

} // startMonitoringSocket


- (void) stopMonitoringSocket {
    if (socket != NULL) {
        CFSocketInvalidate (_socketRef);
        CFRelease (_socketRef);
        _socketRef = NULL;
    }
} // stopMonitoringSocket


static void ReceiveMessage (CFSocketRef socket, CFSocketCallBackType type,
                            CFDataRef address, const void *data, void *info) {
    CFChatterClientAppDelegate *self = (__bridge CFChatterClientAppDelegate *)(info);
    [self handleMessageData: (__bridge NSData *) data];
} // ReceiveMessage


- (void) handleMessageData: (NSData *) data {
    // Closed connection?
    if (data.length == 0) {
        [self closeConnection];
        [self runErrorMessage: @"The server closed the connection."  withErrno: noErr];
        return;
    }
    
    // Null-terminate the data.
    NSMutableData *messageData = [NSMutableData dataWithData: data];
    const char NUL = '\0';
    [messageData appendBytes: &NUL length: 1];

    // Get a string to display.
    NSString *message = [NSString stringWithUTF8String: messageData.bytes];
    if (message == nil) {
        [self runErrorMessage: @"Error reading from server."  withErrno: noErr];
        return;
    }
    
    [self appendMessage: message];
} // handleMessageData: 

@end // CFChatterClientAppDelegatex



#if RUN_LOOP_OBSERVER
typedef struct observerActivities {
    int         activity;
    const char *name;
} observerActivities;

observerActivities g_activities[] = {
    { kCFRunLoopEntry,          "Run Loop Entry" },
    { kCFRunLoopBeforeTimers,   "Before Timers" },
    { kCFRunLoopBeforeSources,  "Before Sources" },
    { kCFRunLoopBeforeWaiting,  "Before Waiting" },
    { kCFRunLoopAfterWaiting,   "After Waiting" },
    { kCFRunLoopExit,           "Exit" }
};

static void AddRunLoopObserver (void) {
    
    CFRunLoopRef rl = CFRunLoopGetCurrent ();
    
    CFRunLoopObserverRef observer =
        CFRunLoopObserverCreate (kCFAllocatorDefault,
                                 kCFRunLoopAllActivities, // activites
                                 1, // repeats
                                 0, // order
                                 ObserveRunLoopActivity,
                                 NULL); // context
    
    CFRunLoopAddObserver (rl, observer, kCFRunLoopDefaultMode);
    CFRelease (observer);
} // addRunLoopObserver


static void ObserveRunLoopActivity (CFRunLoopObserverRef observer, 
                                    CFRunLoopActivity activity, void *info) {
    observerActivities *scan, *stop;
    
    scan = g_activities;
    stop = scan + (sizeof(g_activities) / sizeof(*g_activities));
    
    while (scan < stop) {
        if (scan->activity == activity) {
            NSLog (@"%s", scan->name);
            break;
        }
        scan++;
    }
    
} // ObserveRunLoopActivity

#endif  // RUN_LOOP_OBSERVER


/* * * THIS DOESN'T GET COPIED INTO THE BOOK AT THIS POINT * * */
/* It was already printed with simpleclient.m; we're just reusing it. */
// Returns -1 on failure, >= 0 on success.
static int
WriteMessage(int fd, const void *buffer, size_t length) {
    if (length > MAX_MESSAGE_SIZE) {
        fprintf(stderr, "*** Truncating message to %d bytes.\n",
                MAX_MESSAGE_SIZE);
        length = MAX_MESSAGE_SIZE;
    }
    
    // First, send the length byte.
    uint8_t nleft = (uint8_t) length;
    ssize_t nwritten = write(fd, &nleft,
                             sizeof(nleft) );
    if (nwritten <= 0) {
        goto CantWrite;
    }
    
    // Then, send the string bytes.
    while(nleft > 0) {
        nwritten = write(fd, buffer, nleft);
        if (nwritten <= 0)  goto CantWrite;
        
        nleft  -= nwritten;
        buffer += nwritten;
    }
    
CantWrite: 
    if (-1 == nwritten)  perror("write");
    return nwritten;
} // WriteMessage

#pragma mark simpleclient.m

/* * * THESE DON'T GET COPIED INTO THE BOOK AT THIS POINT * * */
static int SocketConnectedToHostNamed (const char *hostname) {
    int sockfd = -1;

    // For each family call gethostbyname2() 
    sa_family_t family[] = { AF_INET6, AF_INET };
    int family_count = sizeof(family)  / sizeof(*family);

    for (int i = 0; sockfd == -1 && i < family_count; i++) {
        printf("Looking at %s family: \n", 
               family[i] == AF_INET6 ? "AF_INET6" : "AF_INET");

        // Get the host address.
        struct hostent *host = NULL;
        host = gethostbyname2(hostname, family[i]);
        if (host == NULL) {
            herror ("gethostbyname2");
            continue;
        }

        // Try to connect with each address.
        struct sockaddr_storage server_addr;

        for (int addressIndex = 0; sockfd == -1; addressIndex++) {

            // Grab the next address.  Bail out if we've run out.
            if (!GetAddressAtIndex(host, addressIndex, &server_addr) )  break;

            char buffer[INET6_ADDRSTRLEN];

            printf("    Trying %s...\n",
                   inet_ntop(host->h_addrtype, host->h_addr_list[addressIndex],
                             buffer, sizeof(buffer) ) );

            // Get a socket.
            sockfd = socket (server_addr.ss_family, SOCK_STREAM, 0);

            if (sockfd == -1) {
                perror ("        socket");
                continue;
            }

            // Reach out and touch someone.  Clients call connect()  instead of 
            // bind()  + listen() .
            int err = connect (sockfd, (struct sockaddr *) &server_addr, 
                               server_addr.ss_len);
            if (err == -1) {
                perror ("        connect");
                close (sockfd);
                sockfd = -1;
            }
            // We successfully connected, so sockfd is not -1.
            // Both loops will exit at this point.
        }
    }
    return sockfd;
} // SocketConnectedToHostNamed


// Index into the hostent and get the addressIndex'th address.
// Returns true if successful, false if we've run out of addresses.
static bool GetAddressAtIndex (struct hostent *host, int addressIndex,
                               struct sockaddr_storage *outServerAddress) {
    // Bad arguments?
    if (outServerAddress == NULL || host == NULL)  return false;

    // Out of addresses?
    if (host->h_addr_list[addressIndex] == NULL)  return false;

    outServerAddress->ss_family = host->h_addrtype;

    if (outServerAddress->ss_family == AF_INET6) {
        struct sockaddr_in6 *addr = (struct sockaddr_in6 *) outServerAddress;
        addr->sin6_len = sizeof(*addr);
        addr->sin6_port = htons(kPortNumber);
        addr->sin6_flowinfo = 0;
        addr->sin6_addr = *(struct in6_addr *) host->h_addr_list[addressIndex];
        addr->sin6_scope_id = 0;
    } else {
        struct sockaddr_in *addr = (struct sockaddr_in *) outServerAddress;
        addr->sin_len = sizeof(*addr);
        addr->sin_port = htons(kPortNumber);
        addr->sin_addr = *(struct in_addr *) host->h_addr_list[addressIndex];
        memset(&addr->sin_zero, 0, sizeof(addr->sin_zero) );
    }
    return true;
} // GetAddressAtIndex
