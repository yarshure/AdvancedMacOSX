// urlenumerator.m -- Iterate with -enumeratorAtURL, show a tree listing,
//                    and calculate disk space consumption

// clang -g -Weverything -framework Foundation -o urlenumerator urlenumerator.m

#import <Foundation/Foundation.h>

int main (int argc, const char *argv[]) {
    @autoreleasepool {

        // Sanity-check, and make the target URL
        if (argc != 2) {
            printf ("usage: %s path -- enumerate starting from the path\n", argv[0]);
            return EXIT_FAILURE;
        }
        NSString *path = [NSString stringWithUTF8String: argv[1]];
        NSURL *pathUrl = [NSURL fileURLWithPath: path];

        // Prefetch these values.  The name is always displayed.
        // If the URL is a directory, don't accumulate its size.
        NSArray *keys = [NSArray arrayWithObjects: 
                                     NSURLLocalizedNameKey,
                                 NSURLIsDirectoryKey,
                                 NSURLFileSizeKey, nil];

        // Get the enumerator.
        NSFileManager *fm = [[[NSFileManager alloc] init] autorelease];
        NSDirectoryEnumerator *direnum = 
            [fm enumeratorAtURL: pathUrl
                includingPropertiesForKeys: keys
                options: 0
                errorHandler: ^(NSURL *url, NSError *error) {
                    NSLog (@"error for %@ : %@", url, error);
                    return YES;
                }];

        // Now actually iterate.  The block will be invoked in this loop if an
        // error happens.

        long long totalSize = 0;
        for (NSURL *url in direnum) {

            // Get the attributes for the URL.
            NSError *error;
            NSDictionary *attrs = [url resourceValuesForKeys: keys  error: &error];

            if (!attrs) {
                NSLog (@"could not get attributes for %@ : %@", url, error);
                continue;
            }

            // Indent the row.
            for (NSUInteger i = 0; i < direnum.level - 1; i++) printf ("  ");

            // Display the name
            NSString *name = [attrs objectForKey: NSURLLocalizedNameKey];
            printf ("%s ", [name UTF8String]);

            // Newline and continue if it's a directory.
            NSNumber *isDirectory = [attrs objectForKey: NSURLIsDirectoryKey];
            if ([isDirectory boolValue]) {
                printf ("\n");
                continue;
            }

            // Otherwise print the size, and accumulate the size sum
            NSNumber *filesize = [attrs objectForKey: NSURLFileSizeKey];
            long long size = [filesize longLongValue];
            if (size < 1024) printf ("%llu\n", size);
            else             printf ("%lluK\n", size / 1024);

            totalSize += size;
        }
    
        printf ("\nTotal Size: %lluM\n", totalSize / 1024 / 1024);
    
    }
    return EXIT_SUCCESS;
} // main
