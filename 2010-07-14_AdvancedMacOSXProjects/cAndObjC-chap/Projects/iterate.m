// iterate.m -- spin through a collection.

/* compile with
gcc -g -Wall -framework Foundation -o iterate iterate.m
*/

#import <Foundation/Foundation.h>


int main (void) {
    [[NSAutoreleasePool alloc] init];

    NSArray *array = [NSArray arrayWithObjects:@"spicy", @"pony", @"head", nil];

    NSEnumerator *enumerator = [array objectEnumerator];
    NSString *string;
    while ((string = [enumerator nextObject])) {
        NSLog (@"%@", string);
    }

    for (NSString *string in array) {
        NSLog (@"%@", string);
    }

    enumerator = [array objectEnumerator];
    for (NSString *string in enumerator) {
        NSLog (@"%@", string);
    }

    return (0);

} // main
