// BitmapView.h -- View that displays a Bitmap, which usually contains a
//                 Mandelbrot set.

#import <Cocoa/Cocoa.h>

@class Bitmap;

@interface BitmapView : NSView {
    Bitmap *bitmap; // Contains the bits to draw

#if SELECTION_CHALLENGE
    BOOL dragging;       // Is the user currently dragging?
    NSPoint anchorPoint; // Where the drag started
    NSPoint dragPoint;   // Where the drag is now
    id delegate;         // whom to notify about the drag.
#endif
}

// This is the bitmap to use for drawing.
- (void) setBitmap: (Bitmap *) bitmap;

// For causing a redraw from another thread.
- (void) setNeedsDisplay;

#if SELECTION_CHALLENGE
// Whom to bother when the user drags out a selection rectangle.
- (void) setDelegate: (id) delegate;
#endif

@end // BitmapView


#if SELECTION_CHALLENGE

@interface NSObject (BitmapViewDelegate)

// Implement this in your class, and set an object to be the
// view's delegate to get notified of drags.

- (void) bitmapView: (BitmapView *) view
       rectSelected: (NSRect) selection;

@end // BitmapViewDelegate

#endif
