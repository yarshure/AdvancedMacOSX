/* AppController */

#import <Cocoa/Cocoa.h>

@interface AppController : NSObject {
    IBOutlet NSTreeController *treeController;
    NSMutableArray *topLevelDirectories;
}
- (void)setTopLevelDirectories:(NSMutableArray *)top;
- (IBAction)deleteSelection:(id)sender;
@end
