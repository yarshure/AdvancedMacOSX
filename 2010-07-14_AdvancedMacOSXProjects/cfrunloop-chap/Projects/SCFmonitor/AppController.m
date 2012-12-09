#import "AppController.h"
/* App lifecycle:
 * The UI is only updated by -reloadData.
 * -reloadData is called only by -awakeFromNib and StoreDidChange().
 * Updating the UI means setting the text fields to match the value returned
 * by the corresponding property accessor.
 * The property accessors always hit the dynamic store to retrieve their value.
 */

// Match any service's IP address.
// "[^/]+" means "match at least one non-slash character."
// "[[:digit:]]" means match one digit.
// See re_format(7) for details.
#define ANY_NETWORK_SERVICE "State:/Network/Service/[^/]+"
#define kIPPattern ANY_NETWORK_SERVICE "/IPv[[:digit:]]"

static void StoreDidChange(SCDynamicStoreRef, CFArrayRef, void *);

@interface AppController ()
@property(readonly) NSString *hostname;
@property(readonly) NSString *consoleUser;
@property(readonly) NSString *localIPs;

- (SCDynamicStoreRef)newDynamicStore;
- (void)setNotificationKeys;
- (void)unsetNotificationKeys;
- (void)reloadData;
@end  // AppController ()

@implementation AppController
#pragma mark Overrides
- (id)init {
    self = [super init];
    if (nil == self) return nil;

    dynamicStore = [self newDynamicStore];
    [self setNotificationKeys];
    return self;
}  // init

- (void)awakeFromNib {
    if ([[self superclass] instancesRespondToSelector:_cmd]) {
        [super awakeFromNib];
    }
    if (NULL != dynamicStore) [self reloadData];
}  // awakeFromNib

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)app {
#pragma unused (app)
    return YES;
}

- (void)dealloc {
    [self unsetNotificationKeys];
    CFRelease(dynamicStore), dynamicStore = NULL;
    [super dealloc];
}  // dealloc

#pragma mark Properties
// Changed by the Computer Name preference in the Sharing preference pane.
- (NSString *)hostname {
    CFStringRef hostname = SCDynamicStoreCopyLocalHostName(dynamicStore);
    return [(id)hostname autorelease];
} // hostname

// Changed by logging in as a different user.
- (NSString *)consoleUser {
    uid_t uid = 0;
    gid_t gid = 0;
    CFStringRef name = SCDynamicStoreCopyConsoleUser(dynamicStore,
                                                     &uid, &gid);
    
    // Build a string like "name (uid, gid)".
    NSString *desc = [NSString stringWithFormat:@"%@ (%lu, %lu)",
                      name, (unsigned long)uid, (unsigned long)gid];
    if (NULL != name) CFRelease(name);
    return desc;
} // consoleUser

// Changed all sorts of ways.
- (NSString *)localIPs {
    static NSString *const kIPErrorMsg = @"<error retrieving addresses>";

    // Use SCDynamicStoreCopyMultiple() to get a consistent snapshot.
    const void *pattern = CFSTR(kIPPattern);
    CFArrayRef patterns = CFArrayCreate(NULL, &pattern, 1,
                                        &kCFTypeArrayCallBacks);
    if (NULL == patterns) {
        NSLog(@"%s: *** Unable to create IP pattern array.");
        return kIPErrorMsg;
    }

    NSDictionary *results = [(id)SCDynamicStoreCopyMultiple(dynamicStore, 
                                                            NULL,
                                                            patterns)
                             autorelease];
    CFRelease(patterns);
    if (nil == results) {
        NSLog(@"%s: *** Unable to copy IP addresses.");
        return kIPErrorMsg;
    }

    // Accumulate the addresses.
    NSString *const SEP = @", ";
    NSMutableArray *addressStrings = [NSMutableArray array];
    for (NSString *key in results) {
        // Each result dictionary has a key "Addresses" whose value
        // is an array of IP addresses as strings.
        NSDictionary *value = [results objectForKey:key];
        // The same key is actually used for both IPv4 and IPv6 addresses.
        NSArray *addresses = [value objectForKey:(id)kSCPropNetIPv4Addresses];
        NSString *addressString = [addresses componentsJoinedByString:SEP];
        [addressStrings addObject:addressString];
    }

    NSString *localIPs = [addressStrings componentsJoinedByString:SEP];
    return localIPs;
}  // localIPs

#pragma mark Private
- (void)reloadData {
    [hostnameField setStringValue:[self hostname]];
    [consoleUserField setStringValue:[self consoleUser]];
    [localIPField setStringValue:[self localIPs]];
}  // reloadData

- (SCDynamicStoreRef)newDynamicStore {
    SCDynamicStoreContext self_ctx = {
        0, self, NULL, NULL, NULL
    };

    CFStringRef name = CFBundleGetIdentifier(CFBundleGetMainBundle());
    SCDynamicStoreRef
    store = SCDynamicStoreCreate(NULL, name,
                                 StoreDidChange, &self_ctx);
    if (NULL == store) {
        NSLog(@"%s: *** Failed to create SCDynamicStoreRef.");
    }
    return store;
}  // newDynamicStore

- (void)setNotificationKeys {
    // Build the key list.
    NSString *hostNameKey = [(id)SCDynamicStoreKeyCreateHostNames(NULL)
                             autorelease];
    NSString *consoleUserKey = [(id)SCDynamicStoreKeyCreateConsoleUser(NULL)
                                autorelease];
    CFArrayRef keys = (CFArrayRef)[NSArray arrayWithObjects:
                                   hostNameKey, consoleUserKey, nil];

    // Build the pattern list.
    CFArrayRef patterns = (CFArrayRef)[NSArray arrayWithObject:(id)CFSTR(kIPPattern)];

    // Register for notifications.
    Boolean
    okay = SCDynamicStoreSetNotificationKeys(dynamicStore, keys, patterns);
    if (!okay) {
        NSLog(@"%s: *** Failed to set notification keys.", __func__);
        return;
    }

    // Add the store to the run loop.
    storeChangeSource = SCDynamicStoreCreateRunLoopSource(NULL,
                                                          dynamicStore,
                                                          0/*order*/);
    if (NULL == storeChangeSource) {
        NSLog(@"%s: *** Failed to create dynamic store run loop source.",
              __func__);
        [self unsetNotificationKeys];
        return;
    }

    CFRunLoopRef rl = CFRunLoopGetCurrent();
    CFRunLoopAddSource(rl, storeChangeSource, kCFRunLoopCommonModes);

    // Run loop owns the source now, so release it.
    CFRelease(storeChangeSource);
}  // setNotificationKeys

- (void)unsetNotificationKeys {
    if (NULL != storeChangeSource) {
        CFRunLoopSourceInvalidate(storeChangeSource);
    }

    Boolean okay = SCDynamicStoreSetNotificationKeys(dynamicStore, NULL, NULL);
    if (!okay) {
        NSLog(@"%s: SCDynamicStoreSetNotificationKeys to NULL failed.",
              __func__);
    }
}  // unsetNotificationKeys
@end  // AppController

static void
StoreDidChange(SCDynamicStoreRef store, CFArrayRef changedKeys,
               void *self_ctx) {
    NSLog(@"%s: <SCDynamicStoreRef: %p> changed %@",
          __func__, store, changedKeys);
    AppController *self = (AppController *)self_ctx;
    [self reloadData];
}  // StoreDidChange
