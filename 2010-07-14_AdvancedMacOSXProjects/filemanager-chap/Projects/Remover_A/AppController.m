#import "AppController.h"
#import "DirEntry.h"

@implementation AppController

- (id)init {
    [super init];
    NSMutableArray *top = [DirEntry entriesAtPath:@"/"
                                       withParent:nil];
    [self setTopLevelDirectories:top];
    return self;
}

- (void)setTopLevelDirectories:(NSMutableArray *)top {
    [top retain];
    [topLevelDirectories release];
    topLevelDirectories = top;
}

// You will implement this later
- (IBAction)deleteSelection:(id)sender
{
    NSLog(@"-[AppController deleteSelection:] to be implemented");
}
@end
