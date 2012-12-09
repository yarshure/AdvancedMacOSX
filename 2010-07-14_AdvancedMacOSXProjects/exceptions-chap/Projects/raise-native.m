// raise-native.m -- raise an exception

/* compile with
cc -g -Wmost -fobjc-exceptions -o raise-native \
   -framework Foundation raise-native.m
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
    @throw exception;

    NSLog (@"after the raise.  This won't be executed");

} // doSomethingElse



void doSomething ()
{
    doSomethingElse ();
} // doSomething



int main (int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    @try {
	doSomething ();
    }
    @catch (NSException *exception) {
	NSLog (@"inside of exception handler.");
	NSLog (@"name is : %@", [exception name]);
	NSLog (@"reason is : %@", [exception reason]);
	NSLog (@"userInfo dict: %@", [exception userInfo]);
    }
    @finally {
        [pool release];
    }

    return (EXIT_SUCCESS);

} // main
