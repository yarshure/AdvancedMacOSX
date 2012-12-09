// predef.m -- play with predefined macros

/* compile with
clang -g -Weverything -o predef -framework Foundation predef.m
*/


#import <Foundation/Foundation.h>
#import <stdio.h>

static void someFunc (void) {
    printf ("file %s, line %d, function %s\n", __FILE__, __LINE__, __FUNCTION__);
} // someFunc

@interface SomeClass : NSObject { } 
+ (void) someMethod;
@end

@implementation SomeClass
+ (void) someMethod {
    printf ("file %s, line %d, function %s\n", __FILE__, __LINE__, __FUNCTION__);
} // someMethod
@end

int main (void) {
    printf ("__APPLE__: %d,  __APPLE_CC__: %d\n",
	    __APPLE__, __APPLE_CC__);
    printf ("today is %s, the time is %s\n", __DATE__, __TIME__);
    printf ("file %s, line %d, function %s\n", __FILE__, __LINE__, __FUNCTION__);
    someFunc ();

    [SomeClass someMethod];

    return 0;

} // main
