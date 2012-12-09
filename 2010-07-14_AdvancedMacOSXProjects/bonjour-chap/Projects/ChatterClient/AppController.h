#import <Cocoa/Cocoa.h>
#import "ChatterServing.h"

@interface AppController : NSObject <ChatterUsing>
{
    IBOutlet NSTextField *messageField;
    IBOutlet NSTextField *nicknameField;
    IBOutlet NSTextView *textView;
    NSString *nickname;
    NSString *serverHostname;
    id proxy;

    // +++ new stuff
    NSData *address;
    NSNetServiceBrowser *browser;
    NSMutableArray *services;
    IBOutlet NSComboBox *hostField;
    // --- end of new stuff
}
- (IBAction)sendMessage:(id)sender;
- (IBAction)subscribe:(id)sender;
- (IBAction)unsubscribe:(id)sender;

// +++ new stuff
// Combo box data source methods
- (int)numberOfItemsInComboBox:(NSComboBox *)aComboBox;
- (id)comboBox:(NSComboBox *)aComboBox 
           objectValueForItemAtIndex:(int)index;
- (unsigned int)comboBox:(NSComboBox *)aComboBox 
           indexOfItemWithStringValue:(NSString *)string;
// --- end of new stuff

@end
