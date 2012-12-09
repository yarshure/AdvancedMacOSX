/*!
 * @file DirEntry.h
 * @author Jeremy W. Sherman (Big Nerd Ranch, Inc.)
 * @date 2010-05-14
 *
 * Represents a directory entry.
 */

#import <Foundation/Foundation.h>

@interface DirEntry : NSObject {
 @private
    DirEntry *parent;  // nil iff volume root
    NSString *filename;
    NSDictionary *attributes;
}
- (id)initWithFilename:(NSString *)name
                parent:(DirEntry *)parentEntry;

@property(nonatomic, readonly, retain) DirEntry *parent;
@property(nonatomic, readonly, copy) NSString *filename;
@property(nonatomic, readonly, retain) NSDictionary *attributes;

@property(nonatomic, readonly, retain) NSArray *children;
@property(nonatomic, readonly, assign) BOOL isLeaf;
@end
