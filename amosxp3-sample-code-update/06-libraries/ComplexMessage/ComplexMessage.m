// ComplexMessage -- a plug-in that returns a message using some stored state

#import <Foundation/Foundation.h>

#import "BundlePrinter.h"

#import <stdlib.h>      // for random number routines
#import <time.h>        // for time() to seed the random generator

@interface ComplexMessage : NSObject <BundlePrinterProtocol> {
    NSUInteger _randomValue;
}

@end // ComplexMessage


@implementation ComplexMessage

+ (BOOL) activate {
    NSLog (@"ComplexMessage plug-in activated");
    return YES;
} // activate

+ (void) deactivate {
    NSLog (@"ComplexMessage plug-in deactivated");
} // deactivate

- (id) init {
    if ((self = [super init])) {
        srandom ((unsigned)time(NULL));
        _randomValue = random () % 500;
    }

    return self;

} // init

- (NSString *) message {
    return [NSString stringWithFormat: @"Here is a random number: %lu", 
                     _randomValue];
} // messagee

@end // ComplexMessage


