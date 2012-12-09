// raise-classic.m -- raise an exception in old-school Cocoa

// clang -g -Weverything -framework Foundation -o raise-classic raise-classic.m

#import <Foundation/Foundation.h>
#import <stdlib.h>			// for EXIT_SUCCESS

static void doSomethingElse () {
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
					   @"hello", @"thing1",
                                           @"bork", @"thing2", nil];
    NSException *exception =
        [NSException exceptionWithName: @"GroovyException"
                     reason: @"doSomethingElse raised a GroovyException"
                     userInfo: userInfo];
    [exception raise];

    NSLog (@"after the raise.  This won't be printed.");

} // doSomethingElse


static void doSomething () {
    doSomethingElse ();
} // doSomething


int main (void) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NS_DURING
	doSomething ();

    NS_HANDLER
	NSLog (@"inside of exception handler.");
	NSLog (@"name is : %@", [localException name]);
	NSLog (@"reason is : %@", [localException reason]);
	NSLog (@"userInfo dict: %@", [localException userInfo]);

    NS_ENDHANDLER

    [pool drain];

    return EXIT_SUCCESS;
} // main
