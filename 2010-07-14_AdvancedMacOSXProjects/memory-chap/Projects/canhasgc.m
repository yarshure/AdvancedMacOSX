// canhasgc.m -- do we have garbage collection?

/* compile with:
gcc -g -Wall -framework Foundation -o canhasgc canhasgc.m
or
gcc -fobjc-gc-only -g -Wall -framework Foundation -o canhasgc canhasgc.m
*/

#import <Foundation/Foundation.h>

int main (void) {
    if ([NSGarbageCollector defaultCollector] != nil) {
        NSLog (@"GC active");
    } else {
        NSLog (@"GC not active");
    }

    return (0);

} // main
