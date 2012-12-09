// ImageCanvas.m -- Implementation for a view that displays images in random
//                  locations.

#import "ImageCanvas.h"

@implementation ImageCanvas

- (id) initWithFrame: (NSRect) frame {
    if (self = [super initWithFrame: frame]) {
        // Create the place to store the images and their display locations.
        _images = [NSMutableArray array];
        _origins = [NSMutableArray array];
    }

    return self;

} // initWithFrame


// Add an image to the view's list of images to display.

- (void) addImage: (NSImage *) image {
    // Bail out if we're given an obviously bad image.
    if (image == nil) return;
    
    // Add it to the list.
    [_images addObject: image];

    // In parallel to the images list, store an origin NSPoint wrapped
    // in an NSValue.  Pick a random location in the view so that the
    // entire image is visible in the view.
    NSRect bounds = [self bounds];
    int maxX = bounds.size.width - [image size].width;
    int maxY = bounds.size.height - [image size].height;

    NSPoint origin = NSMakePoint (random() % maxX, random() % maxY);

    // Wrap the point in an NSValue and add to the list of origins.
    NSValue *value = [NSValue valueWithPoint: origin];
    [_origins addObject: value];

    // New stuff to see, so cause a redraw sometime in the future.
    [self setNeedsDisplay: YES];

} // addImage


// Display all of the images.
- (void) drawRect: (NSRect) rect {

    // Redraw everything every time.
    NSRect bounds = [self bounds];

    // Make a nice white background.
    [[NSColor whiteColor] set];
    NSRectFill (bounds);

    // We'll be putting a black rectangle around each image, so go ahead
    // and make black the current drawing color.
    [[NSColor blackColor] set];

    // Walk the images
    [_images enumerateObjectsUsingBlock: ^(id object, NSUInteger index, BOOL *stop) {
            // Get the image to draw, and where it lives
            NSValue *pointValue = _origins[index];
            NSPoint origin = [pointValue pointValue];
            
            NSImage *image = (NSImage *)object;
            
            // Draw the image.
            [image drawAtPoint: origin
                   fromRect: NSZeroRect // the entire image
                   operation: NSCompositeCopy
                   fraction: 1.0];
            
            // Give it a nice little border.
            NSRect imageBounds = { origin, image.size };
            NSFrameRect (imageBounds);
        }];

    NSFrameRect (bounds);

} // drawRect

@end // ImageCanvas
