#import <Cocoa/Cocoa.h>

@interface RemoverAppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, weak) IBOutlet NSWindow *window;
@property (nonatomic, weak) IBOutlet NSTreeController *treeController;
@property (nonatomic, readonly, strong) NSArray *topLevelDirectories;

- (IBAction) deleteSelection: (id) sender;

@end // RemoverAppDelegate

