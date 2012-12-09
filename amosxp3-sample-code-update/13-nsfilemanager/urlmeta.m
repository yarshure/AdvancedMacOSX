// urlmeta.m -- Get file metadata about a file via URLs

#import <Foundation/Foundation.h>

// clang -g -Weverything -framework Foundation -o urlmeta urlmeta.m

int main (int argc, const char *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    if (argc != 2) {
        printf ("usage: %s path -- print metadata about file\n", argv[0]);
        printf ("   use / for volume information\n");
        return EXIT_FAILURE;
    }

    if (strlen(argv[1]) == 1 && argv[1][0] == '/') {
        NSFileManager *fm = [[[NSFileManager alloc] init] autorelease];
        NSArray *volumes = [fm mountedVolumeURLsIncludingResourceValuesForKeys: nil
                               options: 0];
        NSLog (@"volumes are %@", volumes);

    } else {
        NSArray *keys = [NSArray arrayWithObjects: 
                                     NSURLNameKey, NSURLLocalizedNameKey,
                                     NSURLIsDirectoryKey,
                                     NSURLCreationDateKey, nil];
    
        NSString *path = [NSString stringWithUTF8String: argv[1]];
        NSURL *url = [NSURL fileURLWithPath: path];

        NSLog (@"url is %@", url);

        NSError *error;
        NSDictionary *attributes = [url resourceValuesForKeys: keys
                                        error: &error];
        NSLog (@"Attributes for %s", argv[1]);
        NSLog (@"%@", attributes);
    }    

    [pool drain];
    return EXIT_SUCCESS;

} // main

