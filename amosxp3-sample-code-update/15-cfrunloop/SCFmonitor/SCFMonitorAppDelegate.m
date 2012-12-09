#import "SCFMonitorAppDelegate.h"

// Useful regular expressions.  See re_format(7) for details.
// Match any service's IP address.
// "[^/]+" means "match at least one non-slash character."
#define ANY_NETWORK_SERVICE "State:/Network/Service/[^/]+"

// "[[:digit:]]" means match one digit.
#define kIPPattern ANY_NETWORK_SERVICE "/IPv[[:digit:]]"

static void StoreDidChange(SCDynamicStoreRef, CFArrayRef, void *);

@interface SCFMonitorAppDelegate ()

// Declare private accessors.  These dudes always hit the dynamic store for values.
@property(weak, readonly) NSString *hostname;
@property(weak, readonly) NSString *consoleUser;
@property(weak, readonly) NSString *localIPs;

// Forward references
- (SCDynamicStoreRef) newDynamicStore;
- (void) setNotificationKeys;
- (void) unsetNotificationKeys;
- (void) updateUI;

@end // extension


@implementation SCFMonitorAppDelegate {
    SCDynamicStoreRef _dynamicStore;
    CFRunLoopSourceRef _storeChangeSource;
}


- (id) init {
    if ((self = [super init])) {
        _dynamicStore = [self newDynamicStore];
        [self setNotificationKeys];
    }
    return self;
} // init


- (void) awakeFromNib {
    [self updateUI];
} // awakeFromNib

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication *) app {
    return YES;
} // applicationShouldTerminateAfterLastWindowClosed

- (void) dealloc {
    [self unsetNotificationKeys];
    CFRelease(_dynamicStore) , _dynamicStore = NULL;
} // dealloc


// This value changes if the user changes the Computer Name in the 
// Sharing preference pane.
- (NSString *) hostname {
    if (_dynamicStore == NULL) return nil;

    CFStringRef hostname = SCDynamicStoreCopyLocalHostName (_dynamicStore);
    return CFBridgingRelease(hostname);
} // hostname


// This value changes if this user logs in as a different user.
// Somewhat difficult to catch at runtime.
- (NSString *) consoleUser {
    if (_dynamicStore == NULL) return nil;

    uid_t uid = 0;
    gid_t gid = 0;
    CFStringRef name = SCDynamicStoreCopyConsoleUser(_dynamicStore, &uid, &gid);
    
    // Build a string like "name (uid, gid) ".
    NSString *desc = [NSString stringWithFormat: @"%@ (%lu, %lu) ",
                               name, (unsigned long) uid, (unsigned long) gid];
    if (name != NULL) CFRelease (name);
    return desc;
} // consoleUser


// This value can change easily, especially if a new network is joined.
- (NSString *) localIPs {
    if (_dynamicStore == NULL) return nil;

    static NSString *const kIPErrorMsg = @"<error retrieving addresses>";

    // Use SCDynamicStoreCopyMultiple() to get a consistent snapshot.
    const void *pattern = CFSTR (kIPPattern);
    CFArrayRef patterns = 
        CFArrayCreate (kCFAllocatorDefault, &pattern, 1, &kCFTypeArrayCallBacks);

    if (patterns == NULL) {
        NSLog (@"*** Unable to create IP pattern array.");
        return kIPErrorMsg;
    }

    NSDictionary *results =
        (id)CFBridgingRelease(SCDynamicStoreCopyMultiple (_dynamicStore, NULL,
                                         patterns));
    CFRelease(patterns);

    if (results == nil) {
        NSLog (@"*** Unable to copy IP addresses.");
        return kIPErrorMsg;
    }

    // Accumulate the addresses.
    NSString *const separator = @", ";
    NSMutableArray *addressStrings = [NSMutableArray array];

    for (NSString *key in results) {

        // Each result dictionary has a key "Addresses" whose value
        // is an array of IP addresses as strings.
        NSDictionary *value = [results objectForKey: key];

        // The same key is actually used for both IPv4 and IPv6 addresses.
        NSArray *addresses = [value objectForKey: (id) kSCPropNetIPv4Addresses];
        NSString *addressString = [addresses componentsJoinedByString: separator];
        [addressStrings addObject: addressString];
    }

    NSString *localIPs = [addressStrings componentsJoinedByString: separator];
    return localIPs;
} // localIPs


- (void) updateUI {
    [self.hostnameField setStringValue: self.hostname];
    [self.consoleUserField setStringValue: self.consoleUser];
    [self.localIPField setStringValue: self.localIPs];
} // updateUI


static void StoreDidChange(SCDynamicStoreRef store, CFArrayRef changedKeys,
               void *selfContext) {
    NSLog (@"%s: <SCDynamicStoreRef: %p> changed %@", __func__, store, changedKeys);
    SCFMonitorAppDelegate *self = (__bridge SCFMonitorAppDelegate *) selfContext;
    [self updateUI];
} // StoreDidChange


- (SCDynamicStoreRef) newDynamicStore {
    SCDynamicStoreContext selfContext = { 0, (__bridge void *)(self), NULL, NULL, NULL };

    CFStringRef name = CFBundleGetIdentifier(CFBundleGetMainBundle());
    SCDynamicStoreRef store = SCDynamicStoreCreate (kCFAllocatorDefault, name,
                                                    StoreDidChange, &selfContext);
    if (store == NULL) NSLog (@"*** Failed to create SCDynamicStoreRef.");

    return store;
} // newDynamicStore


- (void) setNotificationKeys {
    // Build the key list.
    NSString *hostNameKey =
        (id)CFBridgingRelease(SCDynamicStoreKeyCreateHostNames(kCFAllocatorDefault));
    NSString *consoleUserKey = 
        (id)CFBridgingRelease(SCDynamicStoreKeyCreateConsoleUser(kCFAllocatorDefault));
    CFArrayRef keys = 
        (__bridge CFArrayRef)[NSArray arrayWithObjects: hostNameKey, consoleUserKey, nil];

    // Build the pattern list.
    CFArrayRef patterns = (__bridge CFArrayRef) [NSArray arrayWithObject: (id) CFSTR(kIPPattern) ];

    // Register for notifications.
    Boolean success = SCDynamicStoreSetNotificationKeys (_dynamicStore, keys, patterns);
    if (!success) {
        NSLog(@"%s: *** Failed to set notification keys.", __func__);
        return;
    }

    // Add the store to the run loop.
    _storeChangeSource = SCDynamicStoreCreateRunLoopSource (kCFAllocatorDefault,
                                                            _dynamicStore, 0);
    if (_storeChangeSource == NULL) {
        NSLog(@"%s: *** Failed to create dynamic store run loop source.", __func__);
        [self unsetNotificationKeys];
        return;
    }

    CFRunLoopRef rl = CFRunLoopGetCurrent ();
    CFRunLoopAddSource (rl, _storeChangeSource, kCFRunLoopCommonModes);

    // Orinarily we'd release _storeChangeSource, but we will invalidate it 
    // when unsetting the notification keys.

} // setNotificationKeys


- (void) unsetNotificationKeys {
    if (_storeChangeSource != NULL) {
        CFRunLoopSourceInvalidate (_storeChangeSource);
    }

    Boolean success = SCDynamicStoreSetNotificationKeys (_dynamicStore, NULL, NULL);
    if (!success) {
        NSLog(@"%s: SCDynamicStoreSetNotificationKeys to NULL failed.",  __func__);
    }
} // unsetNotificationKeys

@end // SCFMonitorAppDelegatex
