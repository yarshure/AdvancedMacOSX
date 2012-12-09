#import "AppController.h"
#import "DirEntry.h"

@implementation AppController

- (void)logWorkspaceNotification:(NSNotification *)note {
    NSLog(@"received: %@", note);
}

- (id)init {
    [super init];
    NSMutableArray *top;
    top = [DirEntry entriesAtPath:@"/"
                       withParent:nil];
    [self setTopLevelDirectories:top];
    // Register to receive all NSWorkspace notifications.
    NSNotificationCenter *nc = [[NSWorkspace sharedWorkspace]
                                notificationCenter];
    [nc addObserver:self
           selector:@selector(logWorkspaceNotification:)
               name:nil
             object:nil];
    return self;
}

- (void)setTopLevelDirectories:(NSMutableArray *)top {
    [top retain];
    [topLevelDirectories release];
    topLevelDirectories = top;
}

- (IBAction)deleteSelection:(id)sender {
    // Get the selection
    NSArray *selection = [treeController selectedObjects];
    NSUInteger count = [selection count];

    // Is nothing selected?
    if (0 == count) {
        NSRunAlertPanel(@"Nothing to Delete", 
                        @"Select an item to delete and try again.", 
                        /*defaultButton*/nil, /*alternateButton*/nil,
                        /*otherButton*/nil);
        return;
    }

    // Loop through each selected DirEntry, ask user to confirm, then delete
    for (NSUInteger i = 0; i < count; i++) {
        DirEntry *dirEntry = [selection objectAtIndex:i];
        NSString *path = [dirEntry fullPath];
        NSString *title = [NSString stringWithFormat:@"Delete \"%@\"?", path];
        NSInteger choice = NSRunAlertPanel(title,
                                           @"Deletion cannot be undone.", 
                                           @"Delete",
                                           @"Cancel",
                                           nil);
        if (NSAlertDefaultReturn != choice) return;

        // Send notifications that trigger KVO to update browser
        BOOL didDelete = NO;
        NSError *error = nil;
        [[dirEntry parent] willChangeValueForKey:@"children"]; {
            // Actually delete the file or directory
            NSFileManager *fm = [NSFileManager defaultManager];
            id priorDelegate = [fm delegate];
            
            [fm setDelegate:self];
            didDelete = [fm removeItemAtPath:path error:&error];
            
            [fm setDelegate:priorDelegate];
        }
        [[dirEntry parent] didChangeValueForKey:@"children"];

        // Was the delete a failure?
        if (!didDelete) {
            [[NSApplication sharedApplication] presentError:error];
        }
    }
}

// This delegate method of NSFileManager gets called if something
// goes wrong with the deletion.
- (BOOL)fileManager:(NSFileManager *)manager
shouldProceedAfterError:(NSError *)error
 removingItemAtPath:(NSString *)path {
    NSLog(@"%s: error = %@", __FUNCTION__, error);
    return NO;
}
@end
