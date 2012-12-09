//
//  DirEntry.m
//  Remover
//
//  Created by Aaron Hillegass on Sun Sep 08 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "DirEntry.h"
#import "AuthorizingFileManager.h"
#define UNSET 3

@implementation DirEntry

+ (NSMutableArray *)entriesAtPath:(NSString *)p withParent:(DirEntry *)d
{
		int max, k;
		DirEntry *newEntry;
		AuthorizingFileManager *manager = [AuthorizingFileManager defaultManager];
		NSArray *filenames;
		NSMutableArray *result = [NSMutableArray array];
		NSLog(@"reading %@", p);
		filenames = [manager directoryContentsAtPath:p];
		if (filenames == nil) {
			NSLog(@"Unable to read %@", p);
			return result;
		}
		max = [filenames count];
		for (k = 0; k < max; k++) {
			newEntry = [[DirEntry alloc] initWithFilename:[filenames objectAtIndex:k] parent:d];
			[result addObject:newEntry];
			[newEntry release];
		}
		return result;
}

- (id)initWithFilename:(NSString *)fn
							parent:(DirEntry *)p
{
	[super init];
	parent = p;
	filename = [fn copy];
	isDirectory = UNSET;
	return self;
}
- (NSMutableArray *)components
{
	NSMutableArray *result;
	if (!parent) {
		result = [NSMutableArray array];
		[result addObject:@""];
	} else {
		result = [parent components];
	}
	[result addObject:[self filename]];
	return result;
}
		
- (NSString *)fullPath
{
	return [[self components] componentsJoinedByString:@"/"];
}
- (NSString *)filename
{
	return filename;
}

- (BOOL)isDirectory
{
	// Is this the first time we've been asked?
	if (!attributes) {
		NSString *path = [self fullPath];
		attributes = [[AuthorizingFileManager defaultManager] fileAttributesAtPath:path traverseLink:YES];
		[attributes retain];
	}
	return [[attributes fileType] isEqual:NSFileTypeDirectory];
}
- (NSArray *)children
{
	NSString *path = [self fullPath];
	return [DirEntry entriesAtPath:path withParent:self];
}

- (DirEntry *)parent
{
	return parent;
}

- (void)dealloc
{
	[attributes release];
	[filename release];
	[super dealloc];
}

@end
