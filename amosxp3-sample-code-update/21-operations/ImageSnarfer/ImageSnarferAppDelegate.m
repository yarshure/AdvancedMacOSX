// ImageSnarferAppDelegate.h -- ImageSnarfer controller class.  It
//                              responds to the user, schedules the
//                              operation, and adds loaded images to
//                              the image canvas.

#import "ImageSnarferAppDelegate.h"

#import "SnarfOperation.h"
#import "ImageCanvas.h"

// Tell Objective-C that these are properties.  These are not in 
// the header because users of this class shouldn't be poking at these.

@interface ImageSnarferAppDelegate ()
@property NSOperationQueue *runQueue;
@property int concurrentExecution;
@end // extension


@implementation ImageSnarferAppDelegate

@synthesize runQueue = _runQueue;
@synthesize imageCanvas = _imageCanvas;
@synthesize concurrentExecution = _concurrentExecution;

// Reads a text file called "contents.txt" from the application bundle.
// This file is a sequence of URLs that should point to some kind of
// image.  Returns a randomzied array of strings.

- (NSArray *) contents {
    // Get the path to the contents file.
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *contentsPath = [bundle pathForResource: @"contents"  ofType: @"txt"];

    // Read the file and turn it into an array of strings split
    // on newlines.
    NSString *contentsString = 
        [NSString stringWithContentsOfFile: contentsPath
                  encoding: NSUTF8StringEncoding  error: NULL];
    
    NSArray *rawContents = [contentsString componentsSeparatedByString: @"\n"];
    NSMutableArray *mutableContents = [rawContents mutableCopy];

    // Eat a stray newline at the end which would cause an empty
    // string.
    NSUInteger count = [mutableContents count];
    if (count == 0) goto bailout;

    if ([mutableContents[count - 1] length] == 0) {
        [mutableContents removeLastObject];
        count--;
    }

    // Shuffle the array.
    srandom (time(NULL));

    // Shuffle the image addresses.
    for (NSUInteger i = count - 1; i != 0; i--) {
        NSUInteger newIndex = random() % i;
        [mutableContents exchangeObjectAtIndex: i  withObjectAtIndex: newIndex];
    }

bailout:
    return mutableContents;

} // contents


// The user told us to start downloading images.
- (IBAction) start: (id) sender {
    // Stop any work that's in-progress.
    [self.runQueue cancelAllOperations];

    // Make a new queue to put our operations.
    self.runQueue = [[NSOperationQueue alloc] init];

    // Since we're funneling everything into one thread, we
    // don't really care about the number of processers.  But it's good
    // to throttle ourselves so we're not too mean to the server.
    [self.runQueue setMaxConcurrentOperationCount: 4];

    // Get the set of URLs to load
    NSArray *contents = [self contents];

    // Also be nice to the server.  50 should be enough to demonstrate
    // concurrency and still give a pleasing display, vs always loading
    // 290 images every run.
    int max = MIN ([contents count], 50);

    // Walk the array and make download operations.
    for (NSInteger i = 0; i < max; i++) {
        // Turn the string into an URL
        NSString *urlString = contents[i];
        NSURL *url = [NSURL URLWithString: urlString];

        // Make a new operation to download that URL
        SnarfOperation *op = [[SnarfOperation alloc] initWithURL: url];

        // Watch for the finished state of this operation.
        [op addObserver: self
            forKeyPath: @"isFinished"
            options: 0  // It just changes state once, so don't
                        // worry about what's in the notification
            context: NULL];

        // Watch for when this operation starts executing, so we can update
        // the user interface.
        [op addObserver: self
            forKeyPath: @"isExecuting"
            options: NSKeyValueObservingOptionNew
            context: NULL];

        // Schedule the operation for running.
        [self.runQueue addOperation: op];
    }
} // start


// Watch for KVO notifications about operations, specifically when they
// start executing and when they finish.
- (void) observeValueForKeyPath: (NSString *) keyPath
                       ofObject: (id) object
                         change: (NSDictionary *) change
                        context: (void *) context {
    
    if ([keyPath isEqualToString: @"isFinished"]) {
        // If it's done, it has downloaded the image.  Get the image
        // from the operation and put it on the display list.
        SnarfOperation *op = (SnarfOperation *) object;
        NSImage *image = op.image;
        [_imageCanvas addImage: image];

        // Unhook the observation.
        [op removeObserver: self  forKeyPath: @"isFinished"];
        [op removeObserver: self  forKeyPath: @"isExecuting"];

    } else if ([keyPath isEqualToString: @"isExecuting"]) {
        SnarfOperation *op = (SnarfOperation *) object;

        // Update concurrentExecution to reflect to the number of
        // operations currently running.  A status line text field is
        // bound to concurrentExecution.
        if (op.isExecuting) self.concurrentExecution++;
        else self.concurrentExecution--;

    } else {
        // The notification is uninteresting to us, let someone else
        // handle it.
        [super observeValueForKeyPath: keyPath
               ofObject: object
               change: change
               context: context];
    }
} // observeValueForKeyPath

@end // ImageSnarferAppDelegate
