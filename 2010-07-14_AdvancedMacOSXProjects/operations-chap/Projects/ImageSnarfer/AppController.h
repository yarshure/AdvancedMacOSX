// AppController.h -- ImageSnarfer controller class.  It responds to the user,
//                    schedules the operation, and adds loaded images to the
// 		      image canvas.

#import <Cocoa/Cocoa.h>

@class ImageCanvas;

@interface AppController : NSObject {
    NSOperationQueue     *runQueue;   // Holds the image loading operations
    IBOutlet ImageCanvas *imageCanvas;  // Where to draw the images
    int concurrentExecution;  // The number of operations currently in-flight.
}

// Start loading the images.
- (IBAction) start: (id) sender;

@end // AppController

