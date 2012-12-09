// BitmapView.h -- View that displays a Bitmap, which usually contains a
//                 Mandelbrot set.

#import <Cocoa/Cocoa.h>

@class Bitmap;

#if SELECTION_CHALLENGE
@protocol BitmapViewDelegate;
#endif

@interface BitmapView : NSView {
#if SELECTION_CHALLENGE
    BOOL _dragging;       // Is the user currently dragging?
    NSPoint _anchorPoint; // Where the drag started
    NSPoint _dragPoint;   // Where the drag is now
#endif
}

// The bitmap to use for drawing.
@property (strong) Bitmap *bitmap;

#if SELECTION_CHALLENGE
// Whom to bother when the user drags out a selection rectangle.
@property (weak) id<BitmapViewDelegate> delegate;
#endif

// Cause a redraw from another thread becaue passing a scalar through
// to -performSelectorOnMainThread is awkward.  The prefix is to avoid
// any future name collision, because "setNeedsDisplay" is a very
// obvious name, and Apple may add their own setNeedsDisplay that
// takes no parameters.
- (void) bnr_setNeedsDisplay;

@end // BitmapView


#if SELECTION_CHALLENGE

@protocol BitmapViewDelegate

// Implement this in your class, and set an object to be the
// view's delegate to get notified of drags.
- (void) bitmapView: (BitmapView *) view  rectSelected: (NSRect) selection;

@end // BitmapViewDelegate

#endif
