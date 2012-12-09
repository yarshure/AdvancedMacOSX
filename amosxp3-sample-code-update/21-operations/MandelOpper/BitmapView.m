#import "BitmapView.h"
#import "Bitmap.h"

@implementation BitmapView
@synthesize bitmap = _bitmap;

#if SELECTION_CHALLENGE
@synthesize delegate = _delegate;

// Return the rectangle bounded by the original dragging point and
// the current dragging point.
- (NSRect) selectedRect {
    CGFloat minX = MIN (_anchorPoint.x, _dragPoint.x);
    CGFloat maxX = MAX (_anchorPoint.x, _dragPoint.x);
    CGFloat minY = MIN (_anchorPoint.y, _dragPoint.y);
    CGFloat maxY = MAX (_anchorPoint.y, _dragPoint.y);

    NSRect selection = NSMakeRect (minX, minY, maxX - minX,  maxY - minY);

    return selection;

} // selectedRect

#endif


// Display the view's contents
- (void) drawRect: (NSRect) rect {
    // Go ahead and just draw everything every time.
    NSRect bounds = [self bounds];

    // Fill in the area with a nice (?) purplish color prior to drawing the bitmap
    [[NSColor purpleColor] set];
    NSRectFill (bounds);

    // Get the calculated bits and draw them.
    NSBitmapImageRep *rep = [self.bitmap imageRep];
    [rep drawAtPoint: NSZeroPoint];

#if SELECTION_CHALLENGE
    // Draw the selection rectangle on top of everything.
    if (_dragging) {
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
- (void) setBitmap: (Bitmap *) bitmap {
    _bitmap = bitmap;

    [self setNeedsDisplay: YES];

} // setBitmap


- (Bitmap *) bitmap {
    return _bitmap;
} // bitmap



// setNeedsDisplay: and setNeedsDisplayInRect: are not thread-safe,
// so they should only called from the main thread.
// performSelectorOnMainThread: only allows object arguments, not
// BOOL arguments (which is what setNeedsDisplay: really wants).
// This silly little method exists just so it can be called via
// performSelectorOnMainThread from another thread.

- (void) bnr_setNeedsDisplay {
    [self setNeedsDisplay: YES];
} // bnr_setNeedsDisplay


#if SELECTION_CHALLENGE

// Mouse click - this is the anchor point.
- (void) mouseDown: (NSEvent *) event {
    _dragging = YES;
    NSPoint mouse = [self convertPoint: [event locationInWindow]
                          fromView: nil];
    _anchorPoint = _dragPoint = mouse;

    [self setNeedsDisplay: YES];

} // mouseDown


// Mouse has been dragged.  Move the dragPoint to where the mouse pointer is.
- (void) mouseDragged: (NSEvent *) event {
    if (_dragging) {
        NSPoint mouse = [self convertPoint: [event locationInWindow]  fromView: nil];
        _dragPoint = mouse;
        
        [self setNeedsDisplay: YES];
    }

} // mouseDragged


// Mouse has been released.  Tell the delegate we have a new selection.
- (void) mouseUp: (NSEvent *) event {
    if (_dragging) {
        _dragging = NO;
        NSPoint mouse = [self convertPoint: [event locationInWindow]  fromView: nil];
        _dragPoint = mouse;

        // No need to check -respondsToSelector, because the protocol
        // adoption by the delegate means they have implemented it.
        NSRect selection = [self selectedRect];
        [self.delegate bitmapView: self
             rectSelected: selection];

        [self setNeedsDisplay: YES];
    }

} // mouseUp

#endif // SELECTION_CHALLENGE

@end // BitmapView

