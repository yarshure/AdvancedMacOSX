#import "CalcOperation.h"

#import "Bitmap.h"
#import "BitmapView.h"
#import <complex.h>

// This determines how fine the Mandelbrot set calculations are.
#define LOOP 500
#define LIMIT 256


@implementation CalcOperation

// This determines what colors go with which values.
// I've set it up for a pleasing blue-cast scheme.

void gradient (int value, unsigned char *buffer) {
    unsigned char *ptr = buffer;
    value = value * 4;
    if (value > 255) value = 255;

    *ptr++ = value / 3;  // Red
    *ptr++ = value / 2;  // Green
    *ptr++ = value;      // Blue
    *ptr++ = 0xFF;	 // Alpha
} // gradient


// buffer is a pointer to the four bytes that will hold 
// the resulting color

void mandelbrot (double x, double y, unsigned char *buffer) {
    int i;
    _Complex long double z,c;
 
    c = x + (y * 1.0i);
    z = 0;
    
    for (i = 0; i < LOOP; i++) {
        z = (z * z) + c;
        if (cabs(z) > LIMIT) {
            gradient (i, buffer);
            return;
        }
    }
    gradient (0, buffer);
} // mandelbrot


- (id) initWithBitmap: (Bitmap *) bitmap
           bitmapView: (BitmapView *) view
        calculateLine: (NSUInteger) line
               xStart: (double) xStart
                 xEnd: (double) xEnd
                    y: (double) y {

    if ((self = [super init])) {
        _bitmap = bitmap;
        _view = view;
        _line = line;
        _xStart = xStart;
        _xEnd = xEnd;
        _y = y;
    }

    return self;

} // initWithBitmap


// The NSOperation calls -main to start things running.  Since we are
// non-concurrent, we'll actually be run in our own thread, so just 
// trundle on and calculate to our heart's content.
- (void) main {

    // Make sure we weren't cancelled before starting.
    if ([self isCancelled]) {
        NSLog(@"Cancelling");
        return;
    }

    // Putting in a pause makes the scan lines fill in slower, giving
    // a groovier look to things.  Take this out for maximum performance.
#define SLOWUSDOWN 1
#if SLOWUSDOWN
    int usec = random() % 1000;
    usec *= 3000;
    usleep (usec);
#endif

    // This is where we start filling in memory.
    unsigned char *scanline = [_bitmap baseAddressForLine: _line];

    // How far in the Mandelbrot set to advance for each pixel.
    double xDelta = (_xEnd - _xStart) / _bitmap.width;
    
    // Start here.
    double x = _xStart;

    for (int i = 0; i < _bitmap.width; i++) {

        // Figure out where in memory to put the next pixel.
        unsigned char *pixel = (scanline + i * 4);

        // Scoot over and draw.
        x += xDelta;
        mandelbrot (x, _y, pixel);

        // Check every now and then for a cancellation.

        if (i % 50 == 0) {
            if ([self isCancelled]) {
                NSLog(@"cancelling!");
                return;
            }
        }
    }

    // We're done!  Tell the view to update itself when convenient.
    [_view performSelectorOnMainThread: @selector(bnr_setNeedsDisplay)
           withObject: nil
           waitUntilDone: NO];
} // main

@end // CalcOperation
