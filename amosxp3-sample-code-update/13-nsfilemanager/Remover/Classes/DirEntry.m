#import "DirEntry.h"

@interface DirEntry ()
@property (nonatomic, weak) DirEntry *parent;
@end // DirEntry


@implementation DirEntry

// The default set of attributes to pre-fetch.
+ (NSArray *) attributeKeys {
    static NSArray *s_keys;
    if (s_keys == nil) {
        s_keys = @[NSURLNameKey, 
                               NSURLFileSizeKey, 
                               NSURLIsDirectoryKey];
    }
    return s_keys;
} // attributeKeys


#pragma mark Creation and Initialization

- (id) initWithFileURL: (NSURL *) fileURL
                parent: (DirEntry *) parent {
    if ((self = [super init])) {
        _fileURL = fileURL;
        _parent = parent;
    }
    return self;
} // initWithFilename


+ (NSArray *) entriesAtURL: (NSURL *) url
                withParent: (DirEntry *) parent {
    NSMutableArray *result = [NSMutableArray array];

    // Get URLs for the contents of the given directory.
    NSArray *attributeKeys = [self attributeKeys];
    NSError *error;
    NSArray *fileURLs =
        [[NSFileManager defaultManager] contentsOfDirectoryAtURL: url
                                        includingPropertiesForKeys: attributeKeys
                                        options: 0
                                        error: &error];
    if (fileURLs == nil)  {
        NSRunAlertPanel(@"Read failed",
                        @"Unable to read \'%@\' with error %@",
                        nil, nil, nil,
                        url, error) ;
        return result;
    }

    // Create DirEntries for each of resulting URLs
    [fileURLs enumerateObjectsUsingBlock:
                   ^(id fileURL, NSUInteger index, BOOL *stop) {
            DirEntry *newEntry =
                [[DirEntry alloc] initWithFileURL: fileURL
                                  parent: parent];
            [result addObject: newEntry];
        }];

    return [result copy];  // strip off mutability

} // entriesAtURL



#pragma mark File info

- (NSString *) fullPath {
    return [self.fileURL path];
} // fullPath


- (NSString *) filename {
    NSString *filename;
    NSError *error;
    if ([self.fileURL getResourceValue: &filename
             forKey: NSURLNameKey  error: &error]) {
        return filename;
    } else {
        NSRunAlertPanel (@"Attributes failed",
                         @"Unable to get file name for \'%@\' with error %@",
                         nil, nil, nil, self.fileURL, error) ;
        return nil;
    }

} // filename


- (BOOL) isDirectory {
    NSNumber *isDirectory;
    NSError *error;
    if ([self.fileURL getResourceValue: &isDirectory
             forKey: NSURLIsDirectoryKey  error: &error]) {
        return [isDirectory boolValue];
    } else {
        NSRunAlertPanel (@"Attributes failed",
                         @"Unable to get isDirectory for \'%@\' with error %@",
                         nil, nil, nil, self.fileURL, error) ;
        return NO;
    }

} // isDirectory


- (unsigned long long) filesize {
    NSNumber *filesize;
    NSError *error;
    if ([self.fileURL getResourceValue: &filesize
             forKey: NSURLFileSizeKey  error: &error]) {
        return [filesize longLongValue];
    } else {
        NSRunAlertPanel (@"Attributes failed",
                         @"Unable to get file size for \'%@\' with error %@",
                         nil, nil, nil, self.fileURL, error) ;
        return 0;
    }
} // filesize


#pragma mark For use in bindings

- (BOOL) isLeaf {
    return !self.isDirectory;
} // isLeaf


- (NSArray *) children {
    return [DirEntry entriesAtURL: self.fileURL  withParent: self];
} // children

@end // DirEntry
