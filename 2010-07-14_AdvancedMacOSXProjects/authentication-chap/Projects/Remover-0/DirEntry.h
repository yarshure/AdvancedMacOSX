//
//  DirEntry.h
//  Remover
//
//  Created by Aaron Hillegass on Sun Sep 08 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//
// DirEntry represents one node in the file heirarchy
// It may be a file, symlink, directory, etc.
// This class does no caching.
// It doesn't retain its parent.

#import <Foundation/Foundation.h>

@interface DirEntry : NSObject {
	NSDictionary *attributes;
	DirEntry *parent;
	NSString *filename;
	unsigned char isDirectory;
}
+ (NSMutableArray *)entriesAtPath:(NSString *)p withParent:(DirEntry *)d;
- (id)initWithFilename:(NSString *)fn
				parent:(DirEntry *)p;
- (NSString *)fullPath;
- (NSString *)filename;
- (BOOL)isDirectory;
- (NSArray *)children;
- (NSMutableArray *)components;
- (DirEntry *)parent;
@end
