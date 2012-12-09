// raise-native.m -- Raise an exception using native Objective-C mechanisms

// clang -g -Weverything -Wno-unreachable-code -Wno-missing-noreturn -framework Foundation -o raise-native raise-native.m

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
    @throw exception;

    NSLog (@"after the throw.  This won't be printed.");

} // doSomethingElse


static void doSomething () {
    doSomethingElse ();
} // doSomething


int main (void) {
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
        [pool drain];
    }

    return EXIT_SUCCESS;

} // main
