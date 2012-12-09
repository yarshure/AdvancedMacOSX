#import <Cocoa/Cocoa.h>

@interface DirEntry : NSObject {
 @private
	NSDictionary *attributes;
	DirEntry *parent;
	NSString *fileName;
}
+ (NSMutableArray *)entriesAtPath:(NSString *)path 
                       withParent:(DirEntry *)d;
- (id)initWithFileName:(NSString *)fn
                parent:(DirEntry *)d;
@property(nonatomic, readonly, retain) NSDictionary *attributes;
@property(nonatomic, readonly, retain) DirEntry *parent;
@property(nonatomic, readonly, copy) NSString *fileName;
@property(nonatomic, readonly, copy) NSString *fullPath;
@property(nonatomic, readonly) unsigned long long fileSize;
@property(nonatomic, readonly) BOOL isDirectory;
@property(nonatomic, readonly) BOOL isLeaf;
@property(nonatomic, readonly, retain) NSArray *children;
@property(nonatomic, readonly, retain) NSMutableArray *components;
@end
