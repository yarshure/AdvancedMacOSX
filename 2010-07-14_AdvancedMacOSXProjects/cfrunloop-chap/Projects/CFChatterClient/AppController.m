#import "AppController.h"

#import <errno.h>    // errno
#import <fcntl.h>    // fcntl()
#import <stdbool.h>  // true/false
#import <string.h>   // strerror()
#import <unistd.h>   // close()

#import <arpa/inet.h>     // inet_ntop()
#import <netdb.h>         // gethostbyname2()
#import <netinet/in.h>    // struct sockaddr_in
#import <netinet6/in6.h>  // struct sockaddr_in6
#import <sys/socket.h>	  // socket(), AF_INET
#import <sys/types.h>	  // random types

#define MAX_MESSAGE_SIZE  (UINT8_MAX)
#define READ_BUFFER_SIZE  (PAGE_SIZE)
static const in_port_t kPortNumber = 2342;
static const int kInvalidSocket = -1;

// See chatterclient.m for the definition of this function.
static int WriteMessage(int fd, const void *buffer, size_t length);

// See simpleclient.m for the definition of these two functions.
int SocketConnectedToHostNamed(const char *host_name);
bool GetAddressAtIndex(struct hostent *host, int addr_ix,
                       struct sockaddr_storage *out_server_addr);

#define RUN_LOOP_OBSERVER (false)
#if RUN_LOOP_OBSERVER
static void AddRunLoopObserver();
static void ObserveRunLoopActivity(CFRunLoopObserverRef,
                                   CFRunLoopActivity, void *);
#endif

@interface AppController ()
/* UI */
- (void)updateUI;
- (void)appendMessage:(NSString *)msg;
- (void)runErrorMessage:(NSString *)message withErrno:(int)err;

/* Connection */
- (void)connectToHost:(NSString *)hostname asUser:(NSString *)username;
- (void)closeConnection;

/* Socket */
- (void)startMonitoringSocket;
- (void)stopMonitoringSocket;

static void ReceiveMessage(CFSocketRef, CFSocketCallBackType,
                           CFDataRef, const void *, void *);
- (void)handleMessageData:(NSData *)data;
@end  // AppController ()

@implementation AppController
#pragma mark Overrides
- (id)init {
    self = [super init];
    if (!self) return nil;

    sockfd = kInvalidSocket;
#if RUN_LOOP_OBSERVER
    AddRunLoopObserver();
#endif  // RUN_LOOP_OBSERVER
    return self;
}  // init

- (void)awakeFromNib {
    [usernameField setStringValue:NSUserName()];
    [self updateUI];
}  // awakeFromNib

- (void)dealloc {
    [self closeConnection];
    [super dealloc];
}  // dealloc

#pragma mark <NSApplicationDelegate>
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)app {
    return YES;
}

#pragma mark Properties
- (BOOL)isConnected {
    const BOOL connected = (NULL != socket);
    return connected;
}

#pragma mark Actions
- (IBAction)sendMessage:(id)sender {
    if (kInvalidSocket == sockfd) return;

    // Add a newline to match command-line client's behavior.
    NSString *messageString = [[messageField stringValue]
                               stringByAppendingString:@"\n"];
    if (1 == [messageString length]) {
        // Just the newline - don't send it.
        return;
    }

    const char *message = [messageString UTF8String];
    const size_t length = strlen(message);
    NSLog(@"%s: %s (%zu bytes)", __func__, message, length);
    int nwritten = WriteMessage(sockfd, message, length);
    if (length == nwritten) {
        // Clear the message field.
        [messageField setStringValue:@""];
    }
}  // sendMessage

// Sent by Join/Leave button when not connected.
- (IBAction)join:(id)sender {
    NSString *hostname = [hostField stringValue];
    NSString *username = [usernameField stringValue];
    [self connectToHost:hostname asUser:username];

    [self updateUI];

    if ([self isConnected]) {
        NSString *connectMsg = [NSString stringWithFormat:
                                @"( * * * connected to %@ as %@ * * * )\n",
                                hostname, username];
        [self appendMessage:connectMsg];
        [[messageField window] makeFirstResponder:messageField];
    }
}  // subscribe

// Sent by Join/Leave button when connected.
- (IBAction)leave:(id)sender {
    [self closeConnection];

    [self updateUI];

    NSString *disconnectMsg = [NSString stringWithFormat:
                               @"( * * * disconnected from %@ * * *)\n",
                               [hostField stringValue]];
    [self appendMessage:disconnectMsg];
    [[hostField window] makeFirstResponder:hostField];
}  // unsubscribe

#pragma mark UI
- (void)updateUI {
    const BOOL connected = [self isConnected];

    // Disable username and hostname while connected.
    [usernameField setEnabled:!connected];
    [hostField setEnabled:!connected];
    // Join becomes Leave when connected.
    [joinLeaveButton setTitle:connected? @"Leave" : @"Join"];
    [joinLeaveButton setAction:connected? @selector(leave:) : @selector(join:)];

    // Can only type or send messages while connected.
    [messageField setEnabled:connected];
    [sendButton setEnabled:connected];
}  // updateUI

- (void)appendMessage:(NSString *)msg {
    NSLog(@"%s: %@", __func__, msg);

    // Append the message.
    NSRange endOfText = NSMakeRange([[transcript string] length], 0);
    [transcript replaceCharactersInRange:endOfText withString:msg];

    // Make the end of the message visible.
    endOfText = NSMakeRange ([[transcript string] length], 0);
    [transcript scrollRangeToVisible:endOfText];
}  // appendMessage

- (void)runErrorMessage:(NSString *)message withErrno:(int)err
{
    bool no_errno = (0 == err);
    NSString *errnoString = (no_errno? @""
                             : [NSString stringWithUTF8String:strerror(err)]);
    
    (void)NSRunAlertPanel(message, errnoString, @"OK", nil, nil);
}  // runErrorMessage

#pragma mark Connection
- (void)connectToHost:(NSString *)hostname asUser:(NSString *)username {
    NSString *errorMessage = nil;
    int sysError = noErr;
    
    if (kInvalidSocket != sockfd) [self closeConnection];
    
    // sanity check our nick name before trying to connect
    if ([hostname length] < 1) {
        errorMessage = @"Hostname must not be empty.";
        goto bailout;
    }
    
    NSUInteger namelen = [username length];
    BOOL is_valid_name = (0 < namelen && namelen <= 8);
    if (!is_valid_name) {
        errorMessage = @"Username must be between 1 and 8 characters long.";
        goto bailout;
    }
    
    const char *hostname_cstr = [hostname UTF8String];
    sockfd = SocketConnectedToHostNamed(hostname_cstr);
    NSLog(@"[connected to %s port %d]", hostname_cstr, (int)kPortNumber);
    
    // UTF-8 length could be greater than the number of characters.
    const char *name = [username UTF8String];
    namelen = strlen(name);
    int nwritten = WriteMessage(sockfd, name, namelen);
    if (-1 == nwritten) {
        errorMessage = @"Failed to send username.";
        sysError = errno;
        goto bailout;
    }
    NSLog(@"[connected as user \"%@\"]", username);
    
    // make the socket non-blocking
    int err = fcntl(sockfd, F_SETFL, O_NONBLOCK);
    if (-1 == err) {
        errorMessage = @"Could not put socket into nonblocking mode.";
        sysError = errno;
        goto bailout;
    }
    
    [self startMonitoringSocket];

bailout:
    if (nil != errorMessage) {
        [self runErrorMessage:errorMessage withErrno:sysError];
        [self closeConnection];
    }
    return;
}  // connectToHost:asUser:

- (void)closeConnection {
    [self stopMonitoringSocket];
    close(sockfd), sockfd = kInvalidSocket;
}  // closeConnection

#pragma mark Socket
- (void)startMonitoringSocket
{
    CFSocketContext self_ctx = { 0, self, NULL, NULL, NULL };
    socket = CFSocketCreateWithNative(NULL,
                                      sockfd,
                                      kCFSocketDataCallBack,
                                      ReceiveMessage,
                                      &self_ctx);
    if (NULL == socket) {
        [self runErrorMessage: @"Unable to create CFSocketRef."
                    withErrno:noErr];
        goto bailout;
    }
    
    CFRunLoopSourceRef
    rls = CFSocketCreateRunLoopSource(NULL, socket, 0);
    if (NULL == rls) {
        [self runErrorMessage:@"Unable to create socket run loop source."
                    withErrno:noErr];
        goto bailout;
    }
    
    CFRunLoopRef rl = CFRunLoopGetCurrent();
    CFRunLoopAddSource(rl, rls, kCFRunLoopDefaultMode);
    CFRelease(rls);
    
bailout:
    return;
}  // startMonitoringSocket

- (void)stopMonitoringSocket {
    if (NULL != socket) {
        CFSocketInvalidate(socket);
        CFRelease(socket), socket = NULL;
    }
}  // stopMonitoringSocket

static void
ReceiveMessage(CFSocketRef socket __unused,
               CFSocketCallBackType type __unused,
               CFDataRef address __unused,
               const void *data, void *info) {
    AppController *self = info;
    NSData *messageData = (NSData *)data;
    [self handleMessageData:messageData];
}  // ReceiveMessage

- (void)handleMessageData:(NSData *)data {
    const BOOL connectionClosed = (0 == [data length]);
    if (connectionClosed) {
        [self closeConnection];
        NSLog (@"[connection closed]");
        [self runErrorMessage:@"The server closed the connection."
                    withErrno:noErr];
        return;
    }
    
    // Null-terminate the data.
    NSMutableData *messageData = [NSMutableData dataWithData:data];
    const char NUL = '\0';
    [messageData appendBytes:&NUL length:1];

    // Get a string.
    NSString *message = [NSString stringWithUTF8String:[messageData bytes]];
    if (nil == message) {
        [self runErrorMessage:@"Error reading from server."
                    withErrno:noErr];
        return;
    }
    
    [self appendMessage:message];
}  // handleMessageData:
@end  // AppController

#pragma mark CFRunLoopObserver challenge
#if RUN_LOOP_OBSERVER
typedef struct observerActivities {
    int		activity;
    const char *name;
} observerActivities;

observerActivities g_activities[] = {
    { kCFRunLoopEntry,          "Run Loop Entry" },
    { kCFRunLoopBeforeTimers, 	"Before Timers" },
    { kCFRunLoopBeforeSources,	"Before Sources" },
    { kCFRunLoopBeforeWaiting,	"Before Waiting" },
    { kCFRunLoopAfterWaiting,	"After Waiting" },
    { kCFRunLoopExit,           "Exit" }
};

static void
AddRunLoopObserver(void) {
    CFRunLoopRef rl;
    CFRunLoopObserverRef observer;
    
    rl = CFRunLoopGetCurrent ();
    
    observer = CFRunLoopObserverCreate (NULL, // allocator
                                        kCFRunLoopAllActivities, // activites
                                        1, // repeats
                                        0, // order
                                        ObserveRunLoopActivity,
                                        NULL); // context
    
    CFRunLoopAddObserver (rl, observer, kCFRunLoopDefaultMode);
    
    CFRelease (observer);
}  // addRunLoopObserver

static void
ObserveRunLoopActivity(CFRunLoopObserverRef observer, CFRunLoopActivity activity,
                       void *info)
{
    observerActivities *scan, *stop;
    
    scan = g_activities;
    stop = scan + (sizeof(g_activities) / sizeof(observerActivities));
    
    while (scan < stop) {
        if (scan->activity == activity) {
            NSLog (@"%s", scan->name);
            break;
        }
        scan++;
    }
    
}  // ObserveRunLoopActivity
#endif  // RUN_LOOP_OBSERVER

#pragma mark chatterclient.m
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
    uint8_t nleft = (uint8_t)length;
    ssize_t nwritten = write(fd, &nleft,
                             sizeof(nleft));
    if (nwritten <= 0) {
        goto CantWrite;
    }
    
    // Then, send the string bytes.
    while(nleft > 0) {
        nwritten = write(fd, buffer, nleft);
        if (nwritten <= 0) goto CantWrite;
        
        nleft  -= nwritten;
        buffer += nwritten;
    }
    
CantWrite:
    if (-1 == nwritten) perror("write");
    return nwritten;
}  // WriteMessage

#pragma mark simpleclient.m
/* * * THESE DON'T GET COPIED INTO THE BOOK AT THIS POINT * * */
/* They were already printed with simpleclient.m; we're just reusing them. */
// Returns -1 on failure, >= 0 on success.
int
SocketConnectedToHostNamed(const char *host_name) {
    int sockfd = -1;
    // for each family: gethostbyname2
    sa_family_t family[] = {AF_INET6, AF_INET};
    int family_count = sizeof(family) / sizeof(*family);
    struct hostent *host = NULL;
    for (int i = 0; -1 == sockfd && i < family_count; ++i) {
        printf("%s:\n",
               
               family[i] == AF_INET6? "AF_INET6" : "AF_INET");
        // Get the host address.
        host = gethostbyname2(host_name, family[i]);
        if (NULL == host) {
            herror("gethostbyname2");
            continue;
        }
        
        // for each address: try to connect
        struct sockaddr_storage server_addr;
        for (int addr_ix = 0;
             -1 == sockfd && GetAddressAtIndex(host, addr_ix, &server_addr);
             ++addr_ix) {
            char buffer[INET6_ADDRSTRLEN];
            printf("    Trying %s...\n",
                   inet_ntop(host->h_addrtype, host->h_addr_list[addr_ix],
                             buffer, sizeof(buffer)));
            
            // Get a socket.
            sockfd = socket(server_addr.ss_family, SOCK_STREAM, 0);
            if (-1 == sockfd) {
                perror("        socket");
                continue;
            }
            
            // Clients call connect() instead of bind() and listen().
            int err = connect(sockfd, (struct sockaddr *)&server_addr,
                              server_addr.ss_len);
            if (-1 == err) {
                perror("        connect");
                close(sockfd);
                sockfd = -1;
            }
            // successfully connected, so sockfd != -1
            // we will exit both loops at this point
        }
    }
    return sockfd;
}  // SocketConnectedToHostNamed

// Fills |server_addr| using the |addr_ix|th address in host->h_addr_list.
// Returns true if successful, false if no such address exists.
bool
GetAddressAtIndex(struct hostent *host, int addr_ix,
                  struct sockaddr_storage *out_server_addr) {
    const bool bad_args = (NULL == out_server_addr || NULL == host);
    if (bad_args) return false;
    
    const bool end_of_addrs = (NULL == host->h_addr_list[addr_ix]);
    if (end_of_addrs) return false;
    
    out_server_addr->ss_family = host->h_addrtype;
    if (AF_INET6 == out_server_addr->ss_family) {
        struct sockaddr_in6 *addr = (struct sockaddr_in6 *)out_server_addr;
        addr->sin6_len = sizeof(*addr);
        addr->sin6_port = htons(kPortNumber);
        addr->sin6_flowinfo = 0;
        addr->sin6_addr = *(struct in6_addr *)host->h_addr_list[addr_ix];
        addr->sin6_scope_id = 0;
    } else {
        struct sockaddr_in *addr = (struct sockaddr_in *)out_server_addr;
        addr->sin_len = sizeof(*addr);
        addr->sin_port = htons(kPortNumber);
        addr->sin_addr = *(struct in_addr *)host->h_addr_list[addr_ix];
        memset(&addr->sin_zero, 0, sizeof(addr->sin_zero));
    }
    return true;
}  // GetAddressAtIndex
