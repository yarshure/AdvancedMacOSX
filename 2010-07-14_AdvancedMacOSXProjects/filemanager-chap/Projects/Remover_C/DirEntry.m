#import "DirEntry.h"

@implementation DirEntry

#pragma mark Creation and Destruction
+ (NSMutableArray *)entriesAtPath:(NSString *)p 
                       withParent:(DirEntry *)d {
    NSMutableArray *result = [NSMutableArray array];
    NSArray *fileNames;
    fileNames = [[NSFileManager defaultManager] directoryContentsAtPath:p];
    if (fileNames == nil) {
        NSRunAlertPanel(@"Read failed", @"Unable to read \'%@\'", nil, nil, nil, p);
        return result;
    }
    int max, k;
    max = [fileNames count];
    for (k = 0; k < max; k++) {
        DirEntry *newEntry;
        NSString *fileName = [fileNames objectAtIndex:k];
        newEntry = [[DirEntry alloc] initWithFileName:fileName
                                               parent:d];
        [result addObject:newEntry];
        [newEntry release];
    }
    return result;
}

- (id)initWithFileName:(NSString *)fn
                parent:(DirEntry *)p {
	[super init];
	parent = [p retain];
	fileName = [fn copy];
	return self;
}

- (void)dealloc {
	[attributes release];
	[fileName release];
    [parent release];
	[super dealloc];
}

#pragma File info
@synthesize fileName, parent;

- (NSMutableArray *)components {
	NSMutableArray *result = (parent? [parent components]
	                          : [NSMutableArray arrayWithObject:@"/"]);
	[result addObject:[self fileName]];
	return result;
}

- (NSString *)fullPath {
	return [NSString pathWithComponents:[self components]];
}

- (NSDictionary *)attributes {
	if (!attributes) {
		NSString *path = [self fullPath];
		attributes = [[NSFileManager defaultManager]
		              fileAttributesAtPath:path 
		              traverseLink:YES];
		[attributes retain];
	}
	return attributes;
}

- (BOOL)isDirectory {
	NSString *fileType = [[self attributes] fileType];
	return [fileType isEqual:NSFileTypeDirectory];
}

#pragma mark For use in bindings
- (BOOL)isLeaf {
    return ![self isDirectory];
}

- (unsigned long long)fileSize {
    return [[self attributes] fileSize];
}

- (NSArray *)children {
	NSString *path = [self fullPath];
	return [DirEntry entriesAtPath:path 
                        withParent:self];
}
@end
