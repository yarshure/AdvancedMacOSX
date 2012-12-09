// urldirectory.m -- Use URLForDirectory:inDomain:etc

#import <Foundation/Foundation.h>

// clang -g -Weverything -framework Foundation -o urldirectory urldirectory.m

int main (int argc, const char *argv[]) {

    @autoreleasepool {
        
        if (argc == 1) {
            printf ("usage: %s filename\n", argv[0]);
            return 0;
        }

        NSURL *appropriateFor = nil;
        if (argc == 2) {
            NSString *path = [NSString stringWithUTF8String: argv[1]];
            appropriateFor = [NSURL fileURLWithPath: path];
        }
        
        NSFileManager *fm = [[[NSFileManager alloc] init] autorelease];
        
        NSError *error;
        NSURL *directoryURL =
            [fm URLForDirectory: NSItemReplacementDirectory
                inDomain: NSUserDomainMask
                appropriateForURL: appropriateFor
                create: YES
                error: &error];
        
        if (directoryURL == nil) {
            NSLog (@"Could not get directory URL. Error %@", error);
        } else {
            NSLog (@"directoryURL is %@", directoryURL);
        }
    }

    return EXIT_SUCCESS;
} // main

