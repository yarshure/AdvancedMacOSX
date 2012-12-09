#import "MandelOpperAppDelegate.h"

#import "Bitmap.h"
#import "BitmapView.h"
#import "CalcOperation.h"

// Adopt the protocol here so we don't have to pollute our header with it.
@interface MandelOpperAppDelegate () <BitmapViewDelegate>
@end // extension


@implementation MandelOpperAppDelegate
@synthesize bitmapView = _bitmapView;
@synthesize statusLine = _statusLine;

// Change the message in a text field in the window.
- (void) updateStatus: (NSString *) message {
    [self.statusLine setStringValue: message];
} // updateStatus


- (void) awakeFromNib {
    // Awaiting instructions, O Master
    [self updateStatus: @"idle"];

    // This gives us a nice view of the entire Mandelbrot set
    _region = NSMakeRect (-2.0, -1.2, 3.0, 2.4);

#if SELECTION_CHALLENGE
    // Tell the bitmapView whom to bug when the user has dragged out a 
    // selection
    self.bitmapView.delegate = self;

    // Let the user have something to look at.
    [self start: self];
#endif

} // awakeFromNib



// Time to start calculating the set.

- (IBAction) start: (id) sender {
    // Stop any in-flight calculations.
    [_queue cancelAllOperations];

    // Inform the user what's going on.
    [self updateStatus: @"running"];

    // This is the queue that will run all of our operations.
    _queue = [[NSOperationQueue alloc] init];

    // on my 2011 era MacBook Air, letting it run full bore when using the
    // sleeps in CalcOperation casues startup to be really slow as it spawns
    // dozens of threads.  Throttle it down a bit.
    _queue.maxConcurrentOperationCount = 50;

    // Make a new operation to tell us we've finished calculating.
    // Every other action will become a dependency of this one, making
    // it wait until all of the calculations are done.
    NSBlockOperation *allDone = [NSBlockOperation blockOperationWithBlock: ^{
            // Most likely we are *not* the main thread when this block runs,
            // and we need to be on the main thread to update the status line
            // text field.
            
            [self performSelectorOnMainThread: @selector(updateStatus:)
                  withObject: @"done!"
                  waitUntilDone: NO];
        }];

    // Construct a bitmap the size of the frame (using one point == one pixel)
    NSRect frame = self.bitmapView.frame;
    NSUInteger height = frame.size.height;
    NSUInteger width = frame.size.width;

    _bitmap = [[Bitmap alloc] initWithWidth: width  height: height];

    // Tell the bitmap view to use this new bitmap.
    [self.bitmapView setBitmap: _bitmap];

    // This is the change in Y covered by one line of the bitmap
    double deltaY = _region.size.height / height;

    // The starting point for the y coordinates given to each
    // calculation operation.
    double y = NSMaxY (_region);

    // Create a new CalcOperation for each line of the bitmap.
    for (int i = 0; i < frame.size.height; i++) {
        CalcOperation *op;
        op = [[CalcOperation alloc]
                 initWithBitmap: _bitmap
                 bitmapView: self.bitmapView
                 calculateLine: i
                 xStart: NSMinX(_region)
                 xEnd: NSMaxX(_region)
                 y: y];

        // Set the dependency for the allDone operation, and put in the
        // queue.  The operation may start running immediately.
        [allDone addDependency: op];
        [_queue addOperation: op];

        y -= deltaY;
    }

    // Finaly add the all-done operation.  We could not have done this
    // first, because the queue may have drained before we added all of
    // the CalcOperations
    [_queue addOperation: allDone];

} // start


#if SELECTION_CHALLENGE

// The user dragged a rectangle in the bitmap view.  Interpret that to
// be "zoom in on this region of the set."

- (void) bitmapView: (BitmapView *) view
       rectSelected: (NSRect) selection {

    // Don't treat stray clicks as zooming in on something impossibly
    // small, and totally blowing our numerical precision.
    if (NSIsEmptyRect(selection)) return;

    NSRect bounds = [view frame];
    NSRect newRegion;

    // Calculate newRegion as if in the unit square
    newRegion.origin.x = selection.origin.x / bounds.size.width;
    newRegion.origin.y = selection.origin.y / bounds.size.height;
    newRegion.size.width = selection.size.width / bounds.size.width;
    newRegion.size.height = selection.size.height / bounds.size.height;

    // Scale to region's size
    newRegion.origin.x = _region.origin.x
        + newRegion.origin.x * _region.size.width;

   newRegion.origin.y = _region.origin.y
        + newRegion.origin.y * _region.size.height;
   newRegion.size.width = _region.size.width * newRegion.size.width;
   newRegion.size.height = _region.size.height * newRegion.size.height;
   
   _region = newRegion;
   
   // Go ahead and recalculate for the user's convenience.
   [self start: self];
   
} // rectSelected

#endif // SELECTION_CHALLENGE

@end // MandelOpperAppDelegate
