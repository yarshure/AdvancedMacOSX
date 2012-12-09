// path-string.m

// clang -g -Weverything -framework Foundation -o path-string path-string.m

#import <Foundation/Foundation.h>

int main (void) {
    @autoreleasepool {

        NSString *path = NSHomeDirectory ();
        path = [path stringByAppendingPathComponent: @"Documents"];
        path = [path stringByAppendingPathComponent: @"Badgers"];
        path = [path stringByAppendingPathExtension: @"acorn"];
        
        NSLog (@"a path: %@", path);
        
        path = [path stringByAbbreviatingWithTildeInPath];
        NSLog (@"tilde: %@", path);
        path = [path stringByExpandingTildeInPath];
        NSLog (@"expanded: %@", path);
    }

    return 0;

} // main
