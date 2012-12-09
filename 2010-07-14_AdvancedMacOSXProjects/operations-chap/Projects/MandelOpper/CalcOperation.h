// CalcOperation.h -- Operation to calculate a single line of the Mandelbrot
//

#import <Cocoa/Cocoa.h>

@class Bitmap, BitmapView;

@interface CalcOperation : NSOperation {
    Bitmap *bitmap;   // The bitmap that holds the pixel's memory.
    int line;         // The scanline of the bitmap we're responsible for
    BitmapView *view; // Whom to tell to redraw when we're done calculating.

    // The region of the mandelbrot set to calculate.
    double xStart;
    double xEnd;
    double y;
}

- (id) initWithBitmap: (Bitmap *) bitmap
           bitmapView: (BitmapView *) view
        calculateLine: (int) line
               xStart: (double) xStart
                 xEnd: (double) xEnd
                    y: (double) y;

@end // CalcOperation
