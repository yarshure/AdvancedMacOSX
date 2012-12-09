// MandelOpperAppDelegate.h -- MandelOpper controller class.  It responds to the user,
//                    schedules the operations, and coordinates the underlying
//                    graphics bitmap

#import <Cocoa/Cocoa.h>

@class Bitmap, BitmapView;

@interface MandelOpperAppDelegate : NSObject {
    Bitmap *_bitmap;                   // Where the Mandelbrot set image lives
    NSOperationQueue *_queue;          // Holds the calculation operations
    NSRect _region;                    // The region of the set being displayed.
}

@property (weak) IBOutlet BitmapView *bitmapView;
@property (weak) IBOutlet NSTextField *statusLine;

// Start calculating the set and display the results.
- (IBAction) start: (id) sender;
                         
@end // MandelOpperAppDelegate

