// describeObjects.m -- varargs with Objective-C

/* compile with
cc -g -Wall -o describeObjects -framework Foundation describeObjects.m
*/

#import <Foundation/Foundation.h>


@interface Describer : NSObject { }
- (void) describeObjects: (id) firstObject, ...;

@end // Describer


@implementation Describer

- (void) describeObjects: (id) firstObject, ...
{
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


int main (int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    Describer *obj = [[Describer alloc] init];

    NSString *someString = @"someString";
    NSNumber *num = [NSNumber numberWithInt: 23];
    NSDate *date = [NSCalendarDate calendarDate];

    [obj describeObjects:someString, num, date, nil];
    
    [pool release];

    return (0);

} // main
