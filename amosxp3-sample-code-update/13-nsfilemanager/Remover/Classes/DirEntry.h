#import <Foundation/Foundation.h>

@interface DirEntry : NSObject

+ (NSArray *) entriesAtURL: (NSURL *) url
                withParent: (DirEntry *) parent;

@property (nonatomic, readonly, strong) NSURL *fileURL;
@property (nonatomic, readonly, weak) DirEntry *parent;
@property (nonatomic, readonly, strong) NSArray *children;
@property (nonatomic, readonly, copy) NSString *fullPath;
@property (nonatomic, readonly, copy) NSString *filename;
@property (nonatomic, readonly, assign) unsigned long long filesize;
@property (nonatomic, readonly, assign) BOOL isDirectory;
@property (nonatomic, readonly, assign) BOOL isLeaf;

@end // DirEntry
