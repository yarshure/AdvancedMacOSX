// badmessage.m -- send a bad message to an object

/* compile with
cc -g -o badmessage -framework Foundation badmessage.m
*/

#import <Foundation/Foundation.h>

int main (int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    id array = [NSArray array];

    [array frobulate: nil];

} // main
