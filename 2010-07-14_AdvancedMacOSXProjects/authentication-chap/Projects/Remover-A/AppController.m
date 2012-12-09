#import "AppController.h"
#import "DirEntry.h"
#import "AuthorizingFileManager.h"

@implementation AppController

- (void)logThis:(NSNotification *)note
{
    NSLog(@"received: %@", note);
}
- (id)init
{
    [super init];
    NSMutableArray *top;
    top = [DirEntry entriesAtPath:@"/"
                       withParent:nil];
    [self setTopLevelDirectories:top];
    NSNotificationCenter *nc;
    nc = [[NSWorkspace sharedWorkspace] notificationCenter];
    [nc addObserver:self 
           selector:@selector(logThis:)
               name:nil
             object:nil];
    
    return self;
}

- (void)setTopLevelDirectories:(NSMutableArray *)top
{
    [top retain];
    [topLevelDirectories release];
    topLevelDirectories = top;
}

- (IBAction)deleteSelection:(id)sender
{
    // Get the selection
    NSArray *selection = [treeController selectedObjects];
    
    // Is nothing selected?
    if ([selection count] == 0) {
        NSRunAlertPanel(@"Delete", 
                        @"Select something before deleting", 
                        nil, nil, nil);
        return;
    }
    
    // Loop through each selected DirEntry, ask user to confirm, then delete
    int i, count;
    count = [selection count];
    for (i = 0; i < count; i++){
        DirEntry *dirEntry = [selection objectAtIndex:i];
        NSString *path = [dirEntry fullPath];
        int choice = NSRunAlertPanel(@"Delete",
                                     @"Really delete \'%@\'?", 
                                     @"Delete",
                                     @"Cancel",
                                     nil,
                                     path);
        if (choice == NSAlertDefaultReturn) {
            
            // Send notifications that trigger KVO to update browser
            [[dirEntry parent] willChangeValueForKey:@"children"];
            
            // Actually delete the file or directory
            BOOL good;
            good = [[AuthorizingFileManager defaultManager] removeFileAtPath:path 
                                                            handler:self];
            [[dirEntry parent] didChangeValueForKey:@"children"];
            
            // Was the delete a failure?
            if (!good) {
                NSRunAlertPanel(@"Delete", @"Delete was not successful", 
                                nil, nil, nil);
            }
        }
    } 
}
// This gets called if something goes wrong with the delete
- (BOOL)fileManager:(NSFileManager *)manager
        shouldProceedAfterError:(NSDictionary *)errorInfo
{
    NSLog(@"error = %@", errorInfo);
    return NO;
}
@end
