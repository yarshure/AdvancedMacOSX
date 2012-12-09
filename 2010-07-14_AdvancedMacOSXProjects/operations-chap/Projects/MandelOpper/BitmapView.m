#import "BitmapView.h"
#import "Bitmap.h"

@implementation BitmapView

#if SELECTION_CHALLENGE

// Return the rectangle bounded by the original dragging point and
// the current dragging point.
- (NSRect) selectedRect {

    float minX = MIN(anchorPoint.x, dragPoint.x);
    float maxX = MAX(anchorPoint.x, dragPoint.x);
    float minY = MIN(anchorPoint.y, dragPoint.y);
    float maxY = MAX(anchorPoint.y, dragPoint.y);

    NSRect selection = NSMakeRect (minX, minY, maxX - minX,  maxY - minY);

    return (selection);

} // selectedRect

#endif


// Display the view's contents
- (void) drawRect: (NSRect) rect {

    // Go ahead and just draw everything every time.
    NSRect bounds = [self bounds];

    // Fill in the area with a nice (?) purplish color prior to drawing
    // the bitmap
    [[NSColor purpleColor] set];
    NSRectFill (bounds);

    // Get the calculated bits and draw them.
    NSBitmapImageRep *rep = [bitmap imageRep];
    [rep drawAtPoint: NSZeroPoint];

#if SELECTION_CHALLENGE
    // Draw the selection rectangle on top of everything.
    if (dragging) {
        NSRect selection = [self selectedRect];
        [[NSColor yellowColor] set];
        NSFrameRect (selection);
    }
#endif

    // And finally put a nice thin border around the view.
    [[NSColor blackColor] set];
    NSFrameRect (bounds);

} // drawRect


// Time to use a new bitmap.

- (void) setBitmap: (Bitmap *) b {
    [bitmap autorelease];
    bitmap = [b retain];

    [self setNeedsDisplay: YES];

} // setBitmap


// Clean up our mess.
- (void) dealloc {

    [bitmap release];
    [super dealloc];

} // dealloc


// setNeedsDisplay: and setNeedsDisplayInRect: are not thread-safe,
// so they should only called from the main thread.
// performSelectorOnMainThread: only allows object arguments, not
// BOOL arguments (which is what setNeedsDisplay: really wants).
// This silly little method exists just so it can be called via
// performSelectorOnMainThread from another thread.

- (void) setNeedsDisplay {
    [self setNeedsDisplay: YES];
} // setNeedsDisplay


#if SELECTION_CHALLENGE

// Whom to annoy when the user completes a drag.
- (void) setDelegate: (id) d {
    delegate = d;
} // setDelegate


// Mouse click - this is the anchor point.

- (void) mouseDown: (NSEvent *) event {
    dragging = YES;
    NSPoint mouse = [self convertPoint: [event locationInWindow]
                          fromView: nil];
    anchorPoint = dragPoint = mouse;

    [self setNeedsDisplay: YES];

} // mouseDown


// Mouse has been dragged.  Move the dragPoint to where the mouse pointer
// is.

- (void) mouseDragged: (NSEvent *) event {
    if (dragging) {
        dragging = YES;
        NSPoint mouse = [self convertPoint: [event locationInWindow]
                              fromView: nil];
        dragPoint = mouse;
        
        [self setNeedsDisplay: YES];
    }

} // mouseDown


// Mouse-up, baby.  Tell the delegate (if they're interested) that
// we have a new selection.

- (void) mouseUp: (NSEvent *) event {

    if (dragging) {

        dragging = NO;
        NSPoint mouse = [self convertPoint: [event locationInWindow]
                              fromView: nil];
        dragPoint = mouse;

        if ([delegate respondsToSelector:
                          @selector(bitmapView:rectSelected:)]) {
            NSRect selection = [self selectedRect];
            [delegate bitmapView: self
                      rectSelected: selection];
        }

        [self setNeedsDisplay: YES];
    }

} // mouseUp

#endif // SELECTION_CHALLENGE

@end // BitmapView

