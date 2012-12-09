// describeObjects.m -- varargs with Objective-C

// clang -g -Weverything -o describeObjects -framework Foundation describeObjects.m

#import <Foundation/Foundation.h>

@interface Describer : NSObject
- (void) describeObjects: (id) firstObject, ...
    __attribute__((sentinel));

@end // Describer


@implementation Describer

- (void) describeObjects: (id) firstObject, ... {
    va_list args;
    id obj = firstObject;

    va_start (args, firstObject);

    while (obj) {
	NSString *string = [obj description];
	NSLog (@"the description is:\n    %@", string);
	obj = va_arg (args, id);
    }

    va_end (args);

} // describeObjects

@end // Describer


int main (void) {
    @autoreleasepool {
        
        Describer *obj = [[Describer alloc] init];
        
        NSString *someString = @"someString";
        NSNumber *num = [NSNumber numberWithInt: 23];
        NSDate *date = [NSCalendarDate calendarDate];
        
        [obj describeObjects:someString, num, date, nil];
    }

    return 0;

} // main
