/*!
 * @file AppController.h
 * @author Jeremy W. Sherman (Big Nerd Ranch, Inc.)
 * @date 2010-05-14
 *
 * Controls the main window.
 */

#import <Cocoa/Cocoa.h>

@interface AppController : NSObject {
 @private
    IBOutlet NSTreeController *treeController;
    NSMutableArray *topLevelDirectories;
}
- (IBAction)deleteSelectionAction:(NSButton *)sender;

@property(nonatomic, readonly, retain) NSArray *topLevelDirectories;
- (NSUInteger)countOfTopLevelDirectories;
- (id)objectInTopLevelDirectoriesAtIndex:(NSUInteger)index;
- (void)insertObject:(id)obj inTopLevelDirectoriesAtIndex:(NSUInteger)index;
- (void)removeObjectFromTopLevelDirectoriesAtIndex:(NSUInteger)index;
@end
