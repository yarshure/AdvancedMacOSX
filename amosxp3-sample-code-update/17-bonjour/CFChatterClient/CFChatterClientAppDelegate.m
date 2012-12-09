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
static int SocketConnectedToAddress (NSData *data);
static bool GetAddressAtIndex (struct hostent *host, int addressIndex,
                               struct sockaddr_storage *outServerAddress);

// Forward references
@interface CFChatterClientAppDelegate () <
    NSNetServiceBrowserDelegate,
    NSNetServiceDelegate>

// UI
- (void) updateUI;
- (void) appendMessage: (NSString *) msg;
- (void) runErrorMessage: (NSString *) message  withErrno: (int) err;

// Connection
- (void) connectToAddress: (NSData *) hostname  asUser: (NSString *) username;
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
    }
    return self;
} // init


- (void) awakeFromNib {
    // Prepopulate the username field as a convenience.x
    [_usernameField setStringValue: NSUserName()];
    [self updateUI];

    _browser = [[NSNetServiceBrowser alloc] init];
    _services = [[NSMutableArray alloc] init];

    _browser.delegate = self;
    [_browser searchForServicesOfType: @"_chatter._tcp."
              inDomain: @"local."];
    NSLog (@"Begun browsing: %@", _browser);
} // awakeFromNib


- (void)netServiceBrowser: (NSNetServiceBrowser *) aNetServiceBrowser 
           didFindService: (NSNetService *) aNetService 
               moreComing: (BOOL) moreComing 
{
    NSLog(@"Adding new service: aNetService");
    [_services addObject: aNetService];
    if (!moreComing) {
        [_hostField reloadData];        
    }
} // didFindService

- (void)netServiceBrowser: (NSNetServiceBrowser *) aNetServiceBrowser 
         didRemoveService: (NSNetService *) aNetService 
               moreComing: (BOOL) moreComing 
{
    NSLog(@"Removing service");
    for (NSNetService *service in [_services objectEnumerator]) {
        if ([[service name] isEqual: [aNetService name]] &&
            [[service type] isEqual: [aNetService type]] &&
            [[service domain] isEqual: [aNetService domain]]) {

            [_services removeObject: service];
            break;
        }
    }
    if (!moreComing) {
        [_hostField reloadData];        
    }
} // didRemoveService


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

    if ([self isConnected]) {
        [_messageField setStringValue: @"unsubscribe first!"];
    } else {
        NSNetService *currentService =
            _services[[_hostField indexOfSelectedItem]];
        currentService.delegate = self;
        [currentService resolveWithTimeout: 30];
    }
    
} // join


- (void) netServiceDidResolveAddress: (NSNetService *) currentService {
    NSArray *addresses = [currentService addresses];

    // Take the first address.
    NSData *address = addresses[0];

    NSString *username = [_usernameField stringValue];
    [self connectToAddress: address  asUser: username];

    [self updateUI];

    if ([self isConnected]) {
        NSString *hostname = @"TOOO";
        NSString *connectMessage = 
            [NSString stringWithFormat: @"( * * * connected to %@ as %@ * * * ) \n",
                      hostname, username];
        [self appendMessage: connectMessage];
        [[_messageField window] makeFirstResponder: _messageField];
    }

} // netServiceDidResolveAddress


- (void) netService: (NSNetService *) sender
      didNotResolve: (NSDictionary *) errorDict {

    NSString *errorString = [NSString stringWithFormat: @"Unable to resolve %@",
                                      [sender name]];
    [_messageField setStringValue: errorString];
} // didNotResolve


// Sent by Join/Leave button when connected.
- (IBAction) leave: (id) sender {
    [self closeConnection];

    [self updateUI];

    NSString *disconnectMessage =
        [NSString stringWithFormat: @"( * * * disconnected from %@ * * *) \n",
                  [_hostField stringValue]];
    [self appendMessage: disconnectMessage];
    [[_hostField window] makeFirstResponder: _hostField];
} // leave


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
        errnoString = (@(strerror(error)));
    }
    
    NSRunAlertPanel (message, errnoString, @"OK", nil, nil);
} // runErrorMessage


- (void) connectToAddress: (NSData *) address asUser: (NSString *) username {
    NSString *errorMessage = nil;
    int sysError = noErr;
    
    if (_sockfd != kInvalidSocket) [self closeConnection];

    // sanity check our nickname before trying to connect
    if (username.length == 0 || username.length > 8) {
        errorMessage = @"Username must be between 1 and 8 characters long.";
        goto bailout;
    }

    _sockfd = SocketConnectedToAddress (address);
    if (_sockfd == -1) {
        errorMessage = @"Could not connect.";
        sysError = errno;
        goto bailout;
    }
    
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


- (int) numberOfItemsInComboBox: (NSComboBox *) aComboBox {
    return [_services count];
} // numberOfItemsInComboBox


- (id) comboBox: (NSComboBox *) aComboBox  objectValueForItemAtIndex: (int) index {
    NSNetService *item;
    item = _services[index];
    return [item name];
} // objectValueForItemAtIndex

- (unsigned int) comboBox: (NSComboBox *) aComboBox 
                  indexOfItemWithStringValue:(NSString *) string {
    unsigned int max = [_services count];
    for (unsigned int k = 0; k < max; k++) {
        NSNetService *item = _services[k];
        if ([string isEqual:[item name]]) {
            return k;
        }
    }
    return 0;
} // indexOfItemWithStringValue


@end // CFChatterClientAppDelegatex



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

static int SocketConnectedToAddress (NSData *data) {
    struct sockaddr_storage server_addr;
    [data getBytes: &server_addr length: data.length];

    // Get a socket.
    int sockfd = socket (server_addr.ss_family, SOCK_STREAM, 0);

    if (sockfd == -1) {
        perror ("        socket");
        goto bailout;
    }
    
    int err = connect (sockfd, (struct sockaddr *) &server_addr, 
                       server_addr.ss_len);
    if (err == -1) {
        perror ("        connect");
        close (sockfd);
        sockfd = -1;
    }

bailout:
    return sockfd;

} // SocketConnectedToAddress


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
