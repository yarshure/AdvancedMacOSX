// defargs.m -- Get command-line arguments from user defaults.

#import <Foundation/Foundation.h>
#import <stdlib.h>

/* compile with:
gcc -g -Wall -framework Foundation -o defargs defargs.m
*/

int main (int argc, const char *argv[]) {
    NSAutoreleasePool *const pool = [[NSAutoreleasePool alloc] init];
    NSUserDefaults *const defs = [NSUserDefaults standardUserDefaults];

    NSLog(@"cat toy: %@", [defs stringForKey:@"cattoy"]);
    NSLog(@"file name: %@", [defs stringForKey:@"filename"]);

    [pool drain];
    return EXIT_SUCCESS;
}  // main
