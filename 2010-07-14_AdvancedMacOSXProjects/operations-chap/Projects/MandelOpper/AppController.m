#import "AppController.h"

#import "Bitmap.h"
#import "BitmapView.h"
#import "CalcOperation.h"

@implementation AppController


// Change the message in a text field in the window.

- (void) updateStatus: (NSString *) message {
    [statusLine setStringValue: message];
} // updateStatus


- (void) awakeFromNib {

    // Awaiting instructions, O Master
    [self updateStatus: @"idle"];

    // This gives us a nice view of the entire Mandelbrot set
    region = NSMakeRect (-2.0, -1.2, 3, 2.4);

#if SELECTION_CHALLENGE
    // Tell the bitmapView whom to bug when the user has dragged out a 
    // selection
    [bitmapView setDelegate: self];

    // Let the user have something to look at.
    [self start: self];
#endif

} // awakeFromNib


// Clean up our mess.

- (void) dealloc {
    [bitmap release];
    [queue release];

    [super dealloc];

} // dealloc


// This is called by an NSInvocationOperation when all of the calculations
// are done.  Since we're running non-concurrent (auto-threading), this
// will probably be called on something other than the main thread.
// Banging the UI in something other than the main thread leads to
// terror and mayhem.

- (void) allDone {

    // Most likely this is *not* the main thread, and we need to
    // be on the main thread to update the status line.

    [self performSelectorOnMainThread: @selector(updateStatus:)
          withObject: @"done!"
          waitUntilDone: NO];

} // allDone


// Time to start calculating the set.

- (IBAction) start: (id) sender {

    // Stop any in-flight calculations.
    [queue cancelAllOperations];
    [queue release];

    // Inform the user what's going on.
    [self updateStatus: @"running"];

    // This is the queue that will run all of our operations.
    queue = [[NSOperationQueue alloc] init];

    // Make a new operation to tell us we've finished calculating.
    // Every other action will become a dependency of this one, making
    // it wait until all of the calculations are done.
    NSInvocationOperation *allDone;
    allDone = [[NSInvocationOperation alloc]
                  initWithTarget: self
                  selector: @selector(allDone)
                  object: nil];

    // Construct a bitmap the size of the frame (using one point == one
    // pixel)
    NSRect frame = [bitmapView frame];
    int height = frame.size.height;
    int width = frame.size.width;

    [bitmap release];
    bitmap = [[Bitmap alloc] initWithWidth: width
                             height: height];

    // Tell the bitmap view to use this new bitmap.
    [bitmapView setBitmap: bitmap];

    // This is the change in Y covered by one line of the bitmap
    double deltaY = region.size.height / height;

    // This is the starting point for the y coordinates given to each
    // calculation operation.
    double y = NSMaxY (region);

    // Create a new CalcOperation for each line of the bitmap.
    int i;
    for (i = 0; i < frame.size.height; i++) {
        CalcOperation *op;
        op = [[CalcOperation alloc]
                 initWithBitmap: bitmap
                 bitmapView: bitmapView
                 calculateLine: i
                 xStart: NSMinX(region)
                 xEnd: NSMaxX(region)
                 y: y];

        // Set the dependency for the allDone operation, and put in the
        // queue.  The operation may start running immediately.
        [allDone addDependency: op];
        [queue addOperation: op];

        y -= deltaY;
    }

    // Finaly add the all-done operation.  We could not have done this
    // first, since the queue may have drained before we added all of
    // the CalcOperations
    [queue addOperation: allDone];

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
    newRegion.origin.x = region.origin.x
        + newRegion.origin.x * region.size.width;

   newRegion.origin.y = region.origin.y
        + newRegion.origin.y * region.size.height;
   newRegion.size.width = region.size.width * newRegion.size.width;
   newRegion.size.height = region.size.height * newRegion.size.height;
   
   region = newRegion;
   
   // Go ahead and recalculate for the user's convenience.
   [self start: self];
   
} // rectSelected

#endif // SELECTION_CHALLENGE

@end // AppController
