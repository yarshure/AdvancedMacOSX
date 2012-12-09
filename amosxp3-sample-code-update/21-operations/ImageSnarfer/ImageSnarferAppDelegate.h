// ImageSnarferAppDelegate.h -- ImageSnarfer controller class.  It
//                              responds to the user, schedules the operation,
//                              and adds loaded images to the image canvas.

#import <Cocoa/Cocoa.h>

@class ImageCanvas;

@interface ImageSnarferAppDelegate : NSObject {
    NSOperationQueue     *_runQueue;   // Holds the image loading operations
    int _concurrentExecution;          // The number of operations currently in-flight.
}

@property (strong) IBOutlet ImageCanvas *imageCanvas;

// Start loading the images.
- (IBAction) start: (id) sender;

@end // ImageSnarferAppDelegate

