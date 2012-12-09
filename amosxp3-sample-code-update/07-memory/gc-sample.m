// gc-sample.m -- A simple GC app that shows it working.

// clang -fobjc-gc-only -g -Wall -framework Foundation -o gc-sample gc-sample.m

#import <Foundation/Foundation.h>
#import <objc/objc-auto.h>  // for GC runtime API

@interface Snorgle : NSObject {
    int number;
}
- (id) initWithNumber: (int) num;
@end // Snorgle

@implementation Snorgle

- (id) initWithNumber: (int) num {
    if ((self = [super init])) {
        number = num;
    }
    return (self);
} // initWithNumber

- (void)finalize {
    NSLog (@"finalized %d", number);
    [super finalize];
} // finalize

@end // Snorgle

int main (void) {
    NSGarbageCollector *gc = [NSGarbageCollector defaultCollector];

    if (gc != nil) NSLog (@"GC active");

    Snorgle *sn1 = [[Snorgle alloc] initWithNumber: 1];

    NSLog (@"collect with snorgle object still live.");
    [gc collectExhaustively];
    sleep (2);

    sn1 = nil;

    NSLog (@"collect after removing reference");
    [gc collectExhaustively];
    sleep (2);

    return 0;

} // main

