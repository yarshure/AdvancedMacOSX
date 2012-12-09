#import "AppController.h"
#import <sys/socket.h>
#import <netinet/in.h>

@implementation AppController

// +++ new stuff
- (void)awakeFromNib
{
    browser = [[NSNetServiceBrowser alloc] init];
    services = [[NSMutableArray array] retain];
    [browser setDelegate:self];
    [browser searchForServicesOfType:@"_chatter._tcp" inDomain:@"local."];
    NSLog(@"begun browsing: %@", browser);
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
           didFindService:(NSNetService *)aNetService 
               moreComing:(BOOL)moreComing 
{
    NSLog(@"Adding new service");
    [services addObject:aNetService];
    [aNetService setDelegate:self];
    [aNetService resolve];
    if (!moreComing) {
        [hostField reloadData];        
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
         didRemoveService:(NSNetService *)aNetService 
               moreComing:(BOOL)moreComing 
{
    NSLog(@"Removing service");
    NSEnumerator *enumerator = [services objectEnumerator];
    NSNetService *currentNetService;
    while (currentNetService = [enumerator nextObject]) {
        if ([[currentNetService name] isEqual:[aNetService name]] && 
            [[currentNetService type] isEqual:[aNetService type]] && 
            [[currentNetService domain] isEqual:[aNetService domain]]) {
            [services removeObject:currentNetService];
            break;
        }
    }
    if (!moreComing) {
        [hostField reloadData];        
    }
}

// --- end of new stuff

// Private method to clean up connection and proxy
// Seems to be leaking NSSocketPorts
- (void)cleanup
{
    NSConnection *connection = [proxy connectionForProxy];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [connection invalidate];
    [proxy release];
    proxy = nil;
}

// Show message coming in from server
- (oneway void)showMessage:(in bycopy NSString *)message 
              fromNickname:(in bycopy NSString *)n
{
    NSString *string = [NSString stringWithFormat:@"%@ says, \"%@\"\n", 
                        n, message];
    NSTextStorage *currentContents = [textView textStorage];
    NSRange range = NSMakeRange([currentContents length], 0);
    [currentContents replaceCharactersInRange:range withString:string];
    range.length = [string length];
    [textView scrollRangeToVisible:range];
    // Beep to get user's attention
    NSBeep();
}

// Accessors
- (bycopy NSString *)nickname
{
    return nickname;
}

- (void)setNickname:(NSString *)s
{
    [s retain];
    [nickname release];
    nickname = s;
}

- (void)setServerHostname:(NSString *)s
{
    [s retain];
    [serverHostname release];
    serverHostname = s;
}

// +++ new stuff
- (void)setAddress:(NSData *)s
{
    [s retain];
    [address release];
    address = s;
}
// --- end of new stuff

// Connect to the server
- (void)connect
{
    BOOL successful;
    NSConnection *connection;
    NSSocketPort *sendPort;
    
    // Create the send port
    // +++ new stuff
    sendPort = [[NSSocketPort alloc] initRemoteWithProtocolFamily:AF_INET 
                                                       socketType:SOCK_STREAM 
                                                         protocol:IPPROTO_TCP
                                                          address:address];
    // --- end of new stuff
    
    // Create an NSConnection
    connection = [NSConnection connectionWithReceivePort:nil 
                                                sendPort:sendPort];
    
    // Set timeouts to something reasonable
    [connection setRequestTimeout:10.0];
    [connection setReplyTimeout:10.0];
    
    // The send port is retained by the connection
    [sendPort release];
    
    NS_DURING
    // Get the proxy
    proxy = [[connection rootProxy] retain];
    
    // Get informed when the connection fails
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(connectionDown:) 
                                                 name:NSConnectionDidDieNotification 
                                               object:connection];
    
    // By telling the proxy about the protocol for the object 
    // it represents, we significantly reduce the network 
    // traffic involved in each invocation
    [proxy setProtocolForProxy:@protocol(ChatterServing)];
    
    // Try to subscribe with chosen nickname
    successful = [proxy subscribeClient:self];
    if (successful) {
        [messageField setStringValue:@"Connected"];
    } else {
        [messageField setStringValue:@"Nickname not available"];
        [self cleanup];
    }
    NS_HANDLER
    // If the server does not respond in 10 seconds,  
    // this handler will get called
    [messageField setStringValue:@"Unable to connect"];
    [self cleanup];
    NS_ENDHANDLER
}

// Read hostname and nickname then connect
- (IBAction)subscribe:(id)sender
{
    NSNetService *currentService;
    NSArray *addresses;
    
    // Is the user already subscribed?
    if (proxy) {
        [messageField setStringValue:@"unsubscribe first!"];
    } else {
        // +++ new stuff
        // What is the selected service in the combobox?
        currentService = [services objectAtIndex:
                          [hostField indexOfSelectedItem]];
        addresses = [currentService addresses];
        
        // Did it resolve?
        if ([addresses count] == 0) {
            [messageField setStringValue:@"Unable to resolve address"];
            return;
        }
        
        // Just take the first address
        [self setAddress:[addresses objectAtIndex:0]];
        [self setNickname:[nicknameField stringValue]];
        
        // Connect to selected server
        [self connect];
        // --- end of new stuff
    }
}

- (IBAction)sendMessage:(id)sender
{
    NSString *inString;
    
    // If there is no proxy,  try to connect.
    if (!proxy) {
        [self connect];
        // If there is still no proxy, bail
        if (!proxy){
            return;
        }
    }
    
    // Read the message from the text field
    inString = [messageField stringValue];
    NS_DURING
    // Send a message to the server
    [proxy sendMessage:inString fromClient:self];
    NS_HANDLER
    // If something goes wrong
    [messageField setStringValue:@"The connection is down"];
    [self cleanup];
    NS_ENDHANDLER
}

- (IBAction)unsubscribe:(id)sender
{
    NS_DURING
    [proxy unsubscribeClient:self];
    [messageField setStringValue:@"Unsubscribed"];
    [self cleanup];
    NS_HANDLER
    [messageField setStringValue:@"Error unsubscribing"];
    NS_ENDHANDLER
}

// Delegate methods

//  If the connection goes down,  do cleanup
- (void)connectionDown:(NSNotification *)note
{
    NSLog(@"connectionDown:");
    [messageField setStringValue:@"connection down"];
    [self cleanup];
}

// +++ new stuff
- (int)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    return [services count];
}

- (id)comboBox:(NSComboBox *)aComboBox 
objectValueForItemAtIndex:(int)index
{
    NSNetService *item;
    item = [services objectAtIndex:index];
    return [item name];
}

- (unsigned int)comboBox:(NSComboBox *)aComboBox 
indexOfItemWithStringValue:(NSString *)string
{
    unsigned int k, max;
    NSNetService *item;
    max = [services count];
    for (k = 0; k < max; k++) {
        item = [services objectAtIndex:k];
        if ([string isEqual:[item name]]) {
            return k;
        }
    }
    return 0;
}

// --- end of new stuff

// If the app terminates,  unsubscribe.
- (NSApplicationTerminateReply)applicationShouldTerminate:
(NSApplication *)app
{
    NSLog(@"invalidating connection");
    if (proxy) {
        [proxy unsubscribeClient:self];
        [[proxy connectionForProxy] invalidate];
    }
    return NSTerminateNow;
}

- (void)dealloc
{
    [self cleanup];
    [super dealloc];
}

@end
