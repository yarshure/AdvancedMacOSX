// SnarfOperation.h -- Interface to an operation that reads an image from
// 		       an URL.

#import <Cocoa/Cocoa.h>

// This is a concurrent operation, meaning that we won't get a thread
// automatically from Cocoa.  URL loading is an asynchronous operation,
// so doing all of our work on the main thread is ok.

@interface SnarfOperation : NSOperation {
    BOOL isExecuting;	 // YES if we're loading an image
    BOOL isFinished;     // YES if the image loaded (or theres an error)
    BOOL wasSuccessful;  // YES if life is groovy

    NSURL *url;		 // Where to load the image from
    NSImage *image;	 // The completed image.

    NSURLConnection *connection;  // Our conduit to the internet
    NSMutableData *imageData;     // Data accumulates here as it comes in.
}

// Generate the appropriate interfaces.

@property (readonly) BOOL isExecuting;
@property (readonly) BOOL isFinished;
@property (readonly) BOOL wasSuccessful;
@property (readonly) NSURL *url;
@property (readonly) NSImage *image;

// Tell a new operation what URL to download images from.
- (id) initWithURL: (NSURL *) url;

@end // SnarfOperation
