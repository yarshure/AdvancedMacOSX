#import "FilePeekerD.h"

@implementation FilePeekerD

- (NSArray *) dirListingAtPath: (in bycopy NSString *) path {
    NSArray *files;
    NSError *error = nil;

    files = [[NSFileManager defaultManager]
                contentsOfDirectoryAtPath: path
                error: &error];
    if (files == nil) files = [NSArray array];

    return (files);

} // dirListingAtPath


- (NSData *) bytesFromFileAtPath: (in bycopy NSString *) path {
    NSError *error = nil;

    NSData *data = [NSData dataWithContentsOfFile: path
                           options: 0
                           error: &error];
    if (data == nil) data = [NSData data];

    return (data);

} // bytesFromFileAtPath

@end // FilePeekerD

