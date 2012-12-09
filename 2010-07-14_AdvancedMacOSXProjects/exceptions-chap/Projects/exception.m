// exception.m -- show simple exception handling in Cocoa

/* compile with
cc -g -Wmost -o exception -framework Foundation exception.m
*/

#import <Foundation/Foundation.h>
#import <stdlib.h>		 	// for EXIT_SUCCESS

int main (int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *string = @"hello";
    
    NS_DURING
	NSLog (@"character at index 0: %c", [string characterAtIndex: 0]);
	NSLog (@"character at index 1: %c", [string characterAtIndex: 1]);
	NSLog (@"character at index 2000: %c", [string characterAtIndex: 2000]);
	NSLog (@"character at index 2: %c", [string characterAtIndex: 2]);

    NS_HANDLER
	NSLog (@"inside of exception handler.");
	NSLog (@"name is : %@", [localException name]);
	NSLog (@"reason is : %@", [localException reason]);
	NSLog (@"userInfo dict: %@", [localException userInfo]);

    NS_ENDHANDLER

    [pool release];

    return (EXIT_SUCCESS);

} // main
