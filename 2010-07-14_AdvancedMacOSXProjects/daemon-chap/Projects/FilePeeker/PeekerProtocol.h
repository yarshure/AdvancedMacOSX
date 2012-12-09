// Protocol for FilePeeker

#import <Foundation/Foundation.h>

// Clients send these to the server.

#define kFilePeekerPortName @"com.borkware.filepeekerd"

@protocol PeekerProtocol

// Get a directory listing at the given path.
// Returns an array of NSStrings of relative paths with the contents
// of the given directory.  The array is empty if the path doesn't
// exist or the directory could not be read.

- (NSArray *) dirListingAtPath: (in bycopy NSString *) path;


// Read some bytes from the file at the given absolute path and return
// them.

- (NSData *) bytesFromFileAtPath: (in bycopy NSString *) path;

@end // PeekerProtocol
