#import "RemoverAppDelegate.h"
#import "DirEntry.h"


@interface RemoverAppDelegate ()
@property (nonatomic, readwrite, strong) NSArray *topLevelDirectories;
@end // RemoveAppDelegate


@implementation RemoverAppDelegate

- (id) init {
    if ((self = [super init])) {
        // Seed the directories to display.
        NSURL *rootURL = [NSURL fileURLWithPath: @"/"  isDirectory: YES];
        _topLevelDirectories =
            [DirEntry entriesAtURL: rootURL  withParent: nil];
    }
    
    return self;
    
} // init



- (IBAction) deleteSelection: (id) sender {
    // Get the selection
    NSArray *selection = [_treeController selectedObjects];
    NSUInteger count = [selection count];

    // Bail if there's an empty selection?
    if (count == 0) {
        NSRunAlertPanel (@"Nothing to Delete", 
                         @"Select an item to delete and try again.",
                         nil, nil, nil);
        return;
    }
    
    NSFileManager *fm = [[NSFileManager alloc] init];
    fm.delegate = self;
    
    [selection enumerateObjectsUsingBlock:
                   ^(DirEntry *dirEntry, NSUInteger index, BOOL *stop) {
            NSString *path = dirEntry.fullPath;
            NSString *title =
                [NSString stringWithFormat: @"Delete \"%@\"?", path];

            NSInteger choice = NSRunAlertPanel (title,
                                                @"Deletion cannot be undone.", 
                                                @"Delete", @"Cancel",
                                                nil);
            if (choice != NSAlertDefaultReturn) return;
            
            // Send notifications that trigger KVO to update the browser.
            BOOL didDelete = NO;
            NSError *error;

            [dirEntry.parent willChangeValueForKey: @"children"]; {
                // Actually delete the file or directory
                didDelete = [fm removeItemAtURL: dirEntry.fileURL
                                error: &error];
            } [dirEntry.parent didChangeValueForKey: @"children"];
            
            // Was the deletion a failure?
            if (!didDelete) {
                [[NSApplication sharedApplication] presentError: error];
            }
        }];

} // deleteSelection


// NSFileManager calls this delegate method if something goes wrong.
- (BOOL) fileManager: (NSFileManager *) manager
  shouldProceedAfterError: (NSError *) error
       removingItemAtPath: (NSString *) path {

    NSLog (@"%s: error = %@", __FUNCTION__, error);
    return NO;

} // shouldProceedAfterError

@end // RemoverAppDelegate
