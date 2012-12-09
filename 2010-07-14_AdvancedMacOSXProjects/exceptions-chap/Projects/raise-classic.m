// raise.m -- raise an exception

/* compile with
cc -g -Wmost -o raise -framework Foundation raise.m
*/

#import <Foundation/Foundation.h>
#import <stdlib.h>			// for EXIT_SUCCESS


void doSomethingElse ()
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
					       @"hello", @"thing1",
					       @"bork", @"thing2", nil];
    NSException *exception;


    exception = [NSException exceptionWithName: @"MyException"
			     reason: @"doSomethingElse raised a MyException"
			     userInfo: userInfo];
    [exception raise];

    NSLog (@"after the raise.  This won't be executed");

} // doSomethingElse



void doSomething ()
{
    doSomethingElse ();
} // doSomething



int main (int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NS_DURING
	doSomething ();

    NS_HANDLER
	NSLog (@"inside of exception handler.");
	NSLog (@"name is : %@", [localException name]);
	NSLog (@"reason is : %@", [localException reason]);
	NSLog (@"userInfo dict: %@", [localException userInfo]);

    NS_ENDHANDLER

    [pool release];

    return (EXIT_SUCCESS);


} // main
