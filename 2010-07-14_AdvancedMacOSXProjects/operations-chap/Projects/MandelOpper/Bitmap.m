#import "Bitmap.h"

@implementation Bitmap

- (id) initWithWidth: (int) w
              height: (int) h {

    if (self = [super init]) {
        width = w;
        height = h;

        // Get a chunk of memory, then fill it with gray.
        buffer = malloc (width * height * 4);
        memset (buffer, 0x55, width * height * 4);
    }

    return (self);

} // initWithWidth


- (int) width {
    return (width);
} // width


- (int) height {
    return (height);
} // height


- (void) dealloc {

    free (buffer);
    [super dealloc];

} // dealloc


// Wrap an image represenation around the bitmap.  This can be used for
// drawing.

- (NSBitmapImageRep *) imageRep {
    
    NSBitmapImageRep *rep;
    rep = [[NSBitmapImageRep alloc]
              initWithBitmapDataPlanes: &buffer
              pixelsWide: width
              pixelsHigh: height
              bitsPerSample: 8
              samplesPerPixel: 4
              hasAlpha: YES
              isPlanar: NO
              colorSpaceName: NSDeviceRGBColorSpace
              bytesPerRow: width * 4
              bitsPerPixel: 32];

    return [rep autorelease];

} // imageRep


// Perform some pointer math to give the caller the starting address for
// a particular scanline.

- (unsigned char *) baseAddressForLine: (int) line {

    unsigned char *addr = buffer + (line * width * 4);
    return (addr);

} // baseAddressForLine

@end // Bitmap

