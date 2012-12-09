/*!
 * @file AppController.m
 * @author Jeremy W. Sherman (Big Nerd Ranch, Inc.)
 * @date 2010-05-14
 */

#import "AppController.h"
#import "DirEntry.h"

@implementation AppController
#pragma mark Override
- (id)init {
    self = [super init];
    if (!self) return nil;
    DirEntry *rootEntry = [[DirEntry alloc] initWithFilename:@"/" parent:nil];
    topLevelDirectories = [[NSMutableArray alloc]
                           initWithObjects:rootEntry, (void *)nil];
    return self;
}

- (void)dealloc {
    [topLevelDirectories release], topLevelDirectories = nil;
    [super dealloc];
}

#pragma mark Actions
- (IBAction)deleteSelectionAction:(NSButton *)sender {
    NSLog(@"%s: NOT YET IMPLEMENTED", __func__);
    NSBeep();
}

#pragma mark Properties
@synthesize topLevelDirectories;
- (NSUInteger)countOfTopLevelDirectories {
    return [topLevelDirectories count];
}
- (id)objectInTopLevelDirectoriesAtIndex:(NSUInteger)index {
    return [topLevelDirectories objectAtIndex:index];
}
- (void)insertObject:(id)obj inTopLevelDirectoriesAtIndex:(NSUInteger)index {
    return [topLevelDirectories insertObject:obj atIndex:index];
}
- (void)removeObjectFromTopLevelDirectoriesAtIndex:(NSUInteger)index {
    return [topLevelDirectories removeObjectAtIndex:index];
}
@end
