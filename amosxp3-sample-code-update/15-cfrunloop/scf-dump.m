// scf-dump.m -- Dumps the current state of the System Configuration dynamic store.

// clang -g -Weverything -framework Foundation -framework SystemConfiguration
//     -o scf-dump scf-dump.m

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

int main (void)  {
    CFArrayRef patterns = NULL;
    CFDictionaryRef snapshot = NULL;
    SCDynamicStoreRef store = NULL;

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    // Connect to configd.
    SCDynamicStoreContext context = {
        0, NULL, NULL, NULL, NULL
    };

    store = SCDynamicStoreCreate (kCFAllocatorDefault, CFSTR("com.amosx.scf-dump"),
                                  NULL, // callback
                                  &context);
    if (store == NULL) {
        NSLog (@"*** Unable to connect to dynamic store.");
        goto bailout;
    }

    // Copy all keys and values.
    // SCDynamicStoreCopyMultiple() lets you simultaneously request values for
    // both specific keys and all keys matching a list of patterns.

    // Build the patterns array.
    // Use const void * instead of CFStringRef to avoid cast in CFArrayCreate().
    const void *matchAllRegex = CFSTR(".*");
    patterns = CFArrayCreate (kCFAllocatorDefault, &matchAllRegex, 1,
                              &kCFTypeArrayCallBacks);
    if (patterns == NULL) {
        NSLog (@"*** Unable to create key pattern array.");
        goto bailout;
    }

    // Perform the copy.
    snapshot = SCDynamicStoreCopyMultiple (store, NULL, patterns);

    if (snapshot == NULL) {
        NSLog(@"*** Unable to copy keys and values from dynamic store.");
        goto bailout;
    }

    // Use toll-free bridging to get a description.
    NSString *desc = [(id)snapshot descriptionInStringsFileFormat];

    // |desc| already ends in a newline, so use fputs() instead of puts()
    // to avoid appending another.
    fputs ([desc UTF8String], stdout);

bailout:
    if (patterns) CFRelease (patterns);
    if (snapshot) CFRelease (snapshot);
    if (store) CFRelease (store);

    [pool drain];
    return EXIT_SUCCESS;

}  // main
