// filerefurl.m -- Play with file reference urls.

// clang -Weverything -framework Foundation -o filerefurl filerefurl.m

#import <Foundation/Foundation.h>

int main (void) {
    @autoreleasepool {

        system ("touch /tmp/oopack");
        NSURL *url = [NSURL fileURLWithPath: @"/tmp/oopack"];
        NSURL *fileReference = [url fileReferenceURL];
        
        NSLog (@"url: %@ : %@", url, url.path);
        NSLog (@"ref: %@ : %@", fileReference, fileReference.path);
        
        NSLog (@"moving the file");
        system ("mv /tmp/oopack /tmp/jo2yfund");
        
        NSLog (@"url: %@ : %@", url, url.path);
        NSLog (@"ref: %@ : %@", fileReference, fileReference.path);
    }

    return EXIT_SUCCESS;

} // main
