// SnarfOperation.h -- An operation that reads an image from an URL

#import <Cocoa/Cocoa.h>

// In 10.5, this would be a concurrent operation, meaning that we
// won't get a thread automatically from Cocoa.  For 10.6, this is a
// complex-lifetime operation, meaning we will be controlling the
// object lifecycle and handling the KVO foobage.  
// All SnarfOperations operation will perform their url loading on the main thread.

@interface SnarfOperation : NSOperation {
    BOOL _isExecuting;             // YES if we're loading an image
    BOOL _isFinished;              // YES if the image loaded (or theres an error)
    BOOL _wasSuccessful;           // YES if life is groovy

    NSURL *_url;                   // Where to load the image from
    NSImage *_image;               // The completed image.

    NSURLConnection *_connection;  // Our conduit to the internet
    NSMutableData *_imageData;     // Data accumulates here as it comes in.
}

// Generate the appropriate interfaces.

@property (readonly) BOOL isExecuting;
@property (readonly) BOOL isFinished;
@property (readonly) BOOL wasSuccessful;
@property (readonly) NSURL *url;
@property (nonatomic, readonly) NSImage *image;

// Make a new operation what URL to download images from.
- (id) initWithURL: (NSURL *) url;

@end // SnarfOperation
