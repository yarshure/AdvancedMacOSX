#import "DirEntry.h"
#import "AuthorizingFileManager.h"

@implementation DirEntry

#pragma mark Creation and Destruction

+ (NSMutableArray *)entriesAtPath:(NSString *)p 
                       withParent:(DirEntry *)d
{
    NSMutableArray *result = [NSMutableArray array];
    NSArray *filenames;
    filenames = [[AuthorizingFileManager defaultManager] directoryContentsAtPath:p];
    if (filenames == nil) {
        NSRunAlertPanel(@"Read failed", @"Unable to read \'%@\'", nil, nil, nil, p);
        return result;
    }
    int max, k;
    max = [filenames count];
    for (k = 0; k < max; k++) {
        DirEntry *newEntry;
        NSString *filename = [filenames objectAtIndex:k];
        newEntry = [[DirEntry alloc] initWithFilename:filename
                                               parent:d];
        [result addObject:newEntry];
        [newEntry release];
    }
    return result;
}

- (id)initWithFilename:(NSString *)fn
                parent:(DirEntry *)p
{
	[super init];
	parent = [p retain];
	filename = [fn copy];
	return self;
}

- (void)dealloc
{
	[attributes release];
	[filename release];
    [parent release];
	[super dealloc];
}

#pragma File info

- (NSMutableArray *)components
{
	NSMutableArray *result;
	if (!parent) {
		result = [NSMutableArray arrayWithObject:@"/"];
	} else {
		result = [parent components];
	}
	[result addObject:[self filename]];
	return result;
}

- (NSString *)fullPath
{
	return [NSString pathWithComponents:[self components]];
}

- (NSString *)filename
{
	return filename;
}

- (NSDictionary *)attributes
{
	if (!attributes) {
		NSString *path = [self fullPath];
		attributes = [[AuthorizingFileManager defaultManager] fileAttributesAtPath:path 
                                                             traverseLink:YES];
		[attributes retain];
	}
    return attributes;
}

- (BOOL)isDirectory
{
    NSString *fileType = [[self attributes] fileType];
	return [fileType isEqual:NSFileTypeDirectory];
}

- (DirEntry *)parent
{
	return parent;
}

#pragma mark For use in bindings

- (BOOL)isLeaf
{
    return ![self isDirectory];
}

- (unsigned long long)fileSize
{
    return [[self attributes] fileSize];
}

- (NSArray *)children
{
	NSString *path = [self fullPath];
	return [DirEntry entriesAtPath:path 
                        withParent:self];
}

@end
