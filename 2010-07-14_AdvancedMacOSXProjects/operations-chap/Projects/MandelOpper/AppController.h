// AppController.h -- MandelOpper controller class.  It responds to the user,
//                    schedules the operations, and coordinates the underlying
//                    graphics bitmap

#import <Cocoa/Cocoa.h>

@class Bitmap, BitmapView;

@interface AppController : NSObject {
    Bitmap *bitmap;     // Where the Mandelbrot set image lives
    IBOutlet BitmapView *bitmapView;  // Where it gets displayed
    
    IBOutlet NSTextField *statusLine; // Tell the user what we're doing
    
    NSOperationQueue *queue; // Holds the calculation operations
    
    NSRect region;  // The region of the set being displayed.
}

// Start calculating the set and display the results.
- (IBAction) start: (id) sender;
                         
@end // AppController

