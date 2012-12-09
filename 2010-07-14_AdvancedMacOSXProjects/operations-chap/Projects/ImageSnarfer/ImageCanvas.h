// ImageCanvas.h -- interface for a view that displays a list of images
// 	            located at random places in the view.

#import <Cocoa/Cocoa.h>

@interface ImageCanvas : NSView {
    NSMutableArray *images;  // array of NSImages
    NSMutableArray *origins; // array of NSPoint values
}

// Add an image to the canvas.  The canvas will choose a random location
// to draw the image.
- (void) addImage: (NSImage *) image;

@end // ImageCanvas


