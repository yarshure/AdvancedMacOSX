// datasource.m -- look at ObjC2 protocol additions.

// clang -g -Weverything -framework Foundation -o datasource datasource.m

#import <Foundation/Foundation.h>

// --------------------------------------------------
// Datasource for the new table view

@protocol NewTableViewDataSource
- (NSUInteger) rowCount; // defaults to being required

@optional
- (BOOL) shouldEncheferizeStrings;
- (NSIndexSet *) emptyRows;

@required
- (id) dataValueAtRow: (NSUInteger) row;
@end // NewTableViewDataSource protocol

// --------------------------------------------------
// a datasource class

@interface DataSource : NSObject <NewTableViewDataSource>
@end // DataSource

@implementation DataSource

- (NSUInteger) rowCount {
    return 23;
} // rowCount

- (id) dataValueAtRow: (NSUInteger) row {
    return [NSNumber numberWithUnsignedLong: row * 7];
} // dataValueAtRow


- (BOOL) shouldEncheferizeStrings {
    return YES; // bork bork bork
} // should EncheferizeStrings

@end // DataSource

// --------------------------------------------------
// the new table view

@interface NewTableView : NSObject {
    id datasource;
}

- (void) setDataSource: (id <NewTableViewDataSource>) ds;
- (void) doStuff;

@end // NewTableView

@implementation NewTableView

- (void) setDataSource: (id <NewTableViewDataSource>) ds {
    datasource = ds;
} // setDataSource

- (void) doStuff {
    // Don't need to check for respondsToSelector - the compiler does
    // some sanity checking for us.
    NSLog (@"rowCount: %lu", [datasource rowCount]);
    NSLog (@"value at row 5: %@", [datasource dataValueAtRow: 5]);

    // These are optional, so check that the datasource responds to
    // them.
    if ([datasource respondsToSelector: @selector(shouldEncheferizeStrings)]) {
        NSLog (@"bork bork bork? %@",
               [datasource shouldEncheferizeStrings] ? @"YES" : @"NO");
    }
    if ([datasource respondsToSelector: @selector(emptyRows)]) {
        NSLog (@"the empty rows: %@", [datasource emptyRows]);
    }

} // doStuff

@end // NewTableView

// --------------------------------------------------
// Use everything.

int main (void) {
    @autoreleasepool {
        
        NewTableView *tableview = [[NewTableView alloc] init];
        
        DataSource *ds = [[DataSource alloc] init];
        
        [tableview setDataSource: [NSNull null]]; // should warn
        [tableview setDataSource: ds];
        [tableview doStuff];
    }
    return 0;

} // main
