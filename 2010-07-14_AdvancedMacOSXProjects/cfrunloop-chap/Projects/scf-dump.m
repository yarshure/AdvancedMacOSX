/* scf-dump.m
 * Dumps the current state of the System Configuration dynamic store.
 */

/* Compile with:
gcc -g -Wall -framework Foundation -framework SystemConfiguration \
  -o scf-dump scf-dump.m
*/

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

int main(void) 
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    // Connect to configd.
    SCDynamicStoreContext context = {
        0, NULL, NULL, NULL, NULL
    };

    SCDynamicStoreRef
    store = SCDynamicStoreCreate(NULL/*allocator*/,
                                 CFSTR("com.amosx.scf-dump")/*name*/,
                                 NULL/*callback*/,
                                 &context);
    if (NULL == store) {
        NSLog(@"*** Unable to connect to dynamic store.");
        goto CantConnect;
    }

    // Copy all keys and values.
    // SCDynamicStoreCopyMultiple() lets you simultaneously request values for
    // both specific keys and all keys matching a list of patterns.

    // Build the patterns array.
    // Use const void * instead of CFStringRef to avoid cast in CFArrayCreate().
    const void *matchAllRegex = CFSTR(".*");
    CFArrayRef patterns = CFArrayCreate(NULL, &matchAllRegex, 1,
                                        &kCFTypeArrayCallBacks);
    if (NULL == patterns) {
        NSLog(@"*** Unable to create key pattern array.");
        goto CantCreatePatterns;
    }

    // Perform the copy.
    CFDictionaryRef
    snapshot = SCDynamicStoreCopyMultiple(store, NULL/*keys*/,
                                          patterns);
    CFRelease(patterns), patterns = NULL;
    if (NULL == snapshot) {
        NSLog(@"*** Unable to copy keys and values from dynamic store.");
        goto CantCopyStore;
    }

    // Use toll-free bridging to get a description.
    NSString *desc = [(id)snapshot descriptionInStringsFileFormat];
    CFRelease(snapshot), snapshot = NULL;

    // |desc| already ends in a newline, so use fputs() instead of puts()
    // to avoid appending another.
    fputs([desc UTF8String], stdout);

CantCreatePatterns:
CantCopyStore:
    CFRelease(store), store = NULL;

CantConnect:
    [pool drain], pool = nil;
    return EXIT_SUCCESS;
}  // main
