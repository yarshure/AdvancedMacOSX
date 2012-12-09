// iterate.m -- spin through a collection.

/* compile with
clang -g -Weverything -framework Foundation -o iterate iterate.m
*/

#import <Foundation/Foundation.h>


int main (void) {
    @autoreleasepool {
        
        NSArray *array = [NSArray arrayWithObjects:@"spicy", @"pony", @"head", nil];
        
        NSEnumerator *enumerator = [array objectEnumerator];
        NSString *string;

        while ((string = [enumerator nextObject])) {
            NSLog (@"%@", string);
        }
        
        for (string in array) {
            NSLog (@"%@", string);
        }
        
        enumerator = [array objectEnumerator];
        for (string in enumerator) {
            NSLog (@"%@", string);
        }
    }

    return 0;

} // main
