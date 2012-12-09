// quietlog.m -- NSLog, but quieter

/* compile with:
gcc -g -Wall -framework Foundation -o quietlog quietlog.m
*/

#import <Foundation/Foundation.h>

void QuietLog (NSString *format, ...)
{
    va_list argList;
    va_start (argList, format);

    // NSString luckily provides us with this handy method which
    // will do all the work for us, including handling %@
    NSString *string;
    string = [[NSString alloc] initWithFormat: format
                               arguments: argList];
    va_end  (argList);

    printf ("%s\n", [string UTF8String]);

    [string release];

} // QuietLog


int main (void) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSLog (@"NSLog is %@", [NSNumber numberWithInt:23]);
    QuietLog (@"QuietLog is %@", [NSNumber numberWithInt:42]);

    [pool drain];

    return (0);

} // main
