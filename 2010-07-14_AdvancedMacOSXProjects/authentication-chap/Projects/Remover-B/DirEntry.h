#import <Cocoa/Cocoa.h>

@interface DirEntry : NSObject {
	NSDictionary *attributes;
	DirEntry *parent;
	NSString *filename;
}
+ (NSMutableArray *)entriesAtPath:(NSString *)p 
                       withParent:(DirEntry *)d;
- (id)initWithFilename:(NSString *)fn
                parent:(DirEntry *)p;
- (NSString *)fullPath;
- (NSString *)filename;
- (BOOL)isDirectory;
- (BOOL)isLeaf;
- (NSArray *)children;
- (NSMutableArray *)components;
- (DirEntry *)parent;
@end
