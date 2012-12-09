// predef.m -- play with predefined macros

/* compile with
gcc -g -Wall -o predef -framework Foundation predef.m
*/

#import <Foundation/Foundation.h>
#import <stdio.h>  // for printf()

void someFunc (void) {
    printf ("file %s, line %d, function %s\n", __FILE__, __LINE__, __FUNCTION__);
} // someFunc

@interface SomeClass : NSObject
+ (void) someMethod;
@end

@implementation SomeClass
+ (void) someMethod {
    printf ("file %s, line %d, function %s\n", __FILE__, __LINE__, __FUNCTION__);
} // someMethod
@end

int main (int argc, char *argv[]) {
    printf ("__APPLE__: %d\n", __APPLE__);
    printf ("today is %s, the time is %s\n",
            __DATE__, __TIME__);
    printf ("file %s, line %d, function %s\n",
            __FILE__, __LINE__, __FUNCTION__);
    someFunc ();
    [SomeClass someMethod];

#if __LITTLE_ENDIAN__
    printf ("I'm (most likely) running on intel! woo!\n");
#endif
#if __BIG_ENDIAN__
    printf ("I'm (most likely) running on powerPC! woo!\n");
#endif
    return (0);
} // main
