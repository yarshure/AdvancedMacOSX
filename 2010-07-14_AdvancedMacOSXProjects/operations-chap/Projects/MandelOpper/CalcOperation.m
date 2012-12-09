#import "CalcOperation.h"

#import "Bitmap.h"
#import <complex.h>

// This determines how fine the Mandelbrot set calculations are.
#define LOOP 500
#define LIMIT 256


@implementation CalcOperation

// This determines what colors go with which values.
// I've set it up for a pleasing blue-cast scheme.

void gradient(int value, unsigned char *buffer) {
    unsigned char *ptr = buffer;
    value = value * 4;
    if (value > 255) value = 255;

    *ptr++ = value / 3;  // Red
    *ptr++ = value / 2;  // Green
    *ptr++ = value;      // Blue
    *ptr++ = 0xFF;	 // Alpha
}


// buffer is a pointer to the four bytes that will hold 
// the resulting color

void mandelbrot(double x, double y, unsigned char *buffer) {
    int i;
    complex z,c;
 
    c = x + (y * 1.0i);
    z = 0;
    
    for (i = 0; i < LOOP; i++) {
        z = (z * z) + c;
        if (cabs(z) > LIMIT) {
            gradient(i, buffer);
            return;
        }
    }
    gradient(0, buffer);
}


- (id) initWithBitmap: (Bitmap *) b
           bitmapView: (BitmapView *) v
        calculateLine: (int) ln
               xStart: (double) xs
                 xEnd: (double) xe
                    y: (double) theY {

    if (self = [super init]) {
        line = ln;
        bitmap = [b retain];
        view = [v retain];
        xStart = xs;
        xEnd = xe;
        y = theY;
    }

    return (self);

} // initWithBitmap


- (void) dealloc {
    [bitmap release];
    [view release];

    [super dealloc];

} // dealloc


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
    usec *= 1000;
    usleep (usec);
#endif

    // This is where we start filling in memory.
    unsigned char *scanline = [bitmap baseAddressForLine: line];

    // How far in the Mandelbrot set to advance for each pixel.
    double xDelta = (xEnd - xStart) / [bitmap width];
    
    // Start here.
    double x = xStart;

    int i;
    for (i = 0; i < [bitmap width]; i++) {

        // Figure out where in memory to put the next pixel.
        unsigned char *pixel = (scanline + i * 4);

        // Scoot over and draw.
        x += xDelta;
        mandelbrot (x, y, pixel);

        // Check every now and then for a cancellation.

        if (i % 50 == 0) {
            if ([self isCancelled]) {
                NSLog(@"cancelling!");
                return;
            }
        }
    }

    // We're done!  Tell the view to update itself when convenient.

    [view performSelectorOnMainThread: @selector(setNeedsDisplay)
          withObject: nil
          waitUntilDone: NO];

} // main

@end // CalcOperation
