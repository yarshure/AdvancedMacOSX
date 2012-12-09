/* AppController */

#import <Cocoa/Cocoa.h>

@interface AppController : NSObject
{
    IBOutlet NSImageView *imageView;
    IBOutlet NSTableView *tableView;
    NSMutableArray *users;
}
@end
