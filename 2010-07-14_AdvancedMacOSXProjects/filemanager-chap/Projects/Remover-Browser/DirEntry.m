/*!
 * @file DirEntry.h
 * @author Jeremy W. Sherman (Big Nerd Ranch, Inc.)
 * @date 2010-05-14
 */

#import "DirEntry.h"

@interface DirEntry ()
@property(nonatomic, readonly, copy) NSString *path;
@end

@implementation DirEntry
#pragma mark Overrides
- (id)init {
    self = [self initWithFilename:@"/" parent:nil];
    return self;
}

- (void)dealloc {
    [parent release], parent = nil;
    [filename release], filename = nil;
    [attributes release], attributes = nil;
    [super dealloc];
}

#pragma mark Initializers
- (id)initWithFilename:(NSString *)name
                parent:(DirEntry *)parentEntry {
    self = [super init];
    if (!self) return nil;
    if (nil == name) {
        [self release];
        return nil;
    }
    parent = [parentEntry retain];
    filename = [name copy];
    
    return self;
}

#pragma mark Properties
@synthesize parent;
@synthesize filename;

- (NSDictionary *)attributes {
    if (!attributes) {
        NSError *error = nil;
        attributes = [[[NSFileManager defaultManager]
                       attributesOfItemAtPath:[self path]
                       error:&error] retain];
    }
    return [[attributes retain] autorelease];
}

- (NSArray *)children {
    if ([self isLeaf]) return nil;
    
    NSError *error = nil;
    NSArray *fnams = [[NSFileManager defaultManager]
                      contentsOfDirectoryAtPath:[self path]
                      error:&error];
    if ([fnams count] < 1) {
        if (error) NSLog(@"%s: *** Error getting contents of %@: %@",
                         __func__, self, error);
    }
    
    NSMutableArray *children = [NSMutableArray arrayWithCapacity:[fnams count]];
    for (NSString *fnam in fnams) {
        id child = [[[[self class] alloc]
                     initWithFilename:fnam parent:self] autorelease];
        if (child) [children addObject:child];
    }
    return children;
}

- (BOOL)isLeaf {
    NSString *const fileType = [[self attributes] fileType];
    const BOOL isLeaf = ![NSFileTypeDirectory isEqualToString:fileType];
    return isLeaf;
}

#pragma mark Private
- (NSString *)path {
    NSString *const parentPath = [parent path]?/*gcc extension*/: @"";
    NSString *fnam = [self filename];
    NSString *const path = [parentPath
                            stringByAppendingPathComponent:fnam];
    return path;
}
@end
