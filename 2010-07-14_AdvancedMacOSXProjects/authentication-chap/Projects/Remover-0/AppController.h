/* AppController */

#import <Cocoa/Cocoa.h>
@class DirEntry;

@interface AppController : NSObject
{
    IBOutlet NSBrowser *browser;
	
	// 'directories' is an array of arrays of DirEntry
	// Each array represents the entries in one column
	NSMutableArray *directories;

}
- (IBAction)deleteSelection:(id)sender;
- (void)reload;

@end
