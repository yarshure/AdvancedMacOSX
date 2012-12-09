// searchpath.m -- Show NSSearchPathForDirectoriesInDomains

#import <Foundation/Foundation.h>

// clang -g -Weverything -framework Foundation -o searchpath searchpath.m

int main (void) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSArray *paths =
        NSSearchPathForDirectoriesInDomains (NSApplicationSupportDirectory,
                                             NSAllDomainsMask, NO);

    for (NSString *path in paths) {
        NSLog (@"a path!  %@", path);
    }

    [pool drain];
    return 0;

} // main
