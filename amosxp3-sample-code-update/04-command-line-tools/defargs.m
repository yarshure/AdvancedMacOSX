// defargs.m -- Get command-line arguments from user defaults.

#import <Foundation/Foundation.h>
#import <stdlib.h>

/* compile with:
clang -g -Weverything -framework Foundation -o defargs defargs.m
*/

int main (void) {
    @autoreleasepool {
        NSUserDefaults *const defs = [NSUserDefaults standardUserDefaults];
        
        NSLog(@"cat toy: %@", [defs stringForKey:@"cattoy"]);
        NSLog(@"file name: %@", [defs stringForKey:@"filename"]);
        
    }
    return EXIT_SUCCESS;
}  // main
