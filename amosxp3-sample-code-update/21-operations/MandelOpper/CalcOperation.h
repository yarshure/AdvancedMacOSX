// CalcOperation.h -- Operation to calculate a single line of the Mandelbrot Set
//

#import <Cocoa/Cocoa.h>

@class Bitmap, BitmapView;

@interface CalcOperation : NSOperation {
    Bitmap *_bitmap;   // The bitmap that holds the pixel's memory.
    BitmapView *_view; // Whom to tell to redraw when we're done calculating.
    NSUInteger _line;  // The scanline of the bitmap we're responsible for

    // The region of the Mandelbrot set to calculate.
    double _xStart;
    double _xEnd;
    double _y;
}

- (id) initWithBitmap: (Bitmap *) bitmap
           bitmapView: (BitmapView *) view
        calculateLine: (NSUInteger) line
               xStart: (double) xStart
                 xEnd: (double) xEnd
                    y: (double) y;

@end // CalcOperation
