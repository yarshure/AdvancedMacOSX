#import "Bitmap.h"

@implementation Bitmap

@synthesize width = _width;
@synthesize height = _height;

- (id) initWithWidth: (NSUInteger) width
              height: (NSUInteger) height {

    if (self = [super init]) {
        _width = width;
        _height = height;

        // Get a chunk of memory, then fill it with gray.
        _buffer = malloc (_width * _height * 4);

        // Fill with a semitransparent gray color.
        memset (_buffer, 0x55, _width * _height * 4);
    }

    return self;

} // initWithWidth


- (void) dealloc {
    free (_buffer);

} // dealloc


// Wrap an image represenation around the bitmap.  This can be used for
// drawing.

- (NSBitmapImageRep *) imageRep {
    NSBitmapImageRep *rep;
    rep = [[NSBitmapImageRep alloc]
              initWithBitmapDataPlanes: &_buffer
              pixelsWide: self.width
              pixelsHigh: self.height
              bitsPerSample: 8
              samplesPerPixel: 4
              hasAlpha: YES
              isPlanar: NO
              colorSpaceName: NSDeviceRGBColorSpace
              bytesPerRow: self.width * 4
              bitsPerPixel: 32];

    return rep;

} // imageRep


// Perform some pointer math to give the caller the starting address for
// a particular scanline.

- (unsigned char *) baseAddressForLine: (NSUInteger) line {
    unsigned char *addr = _buffer + (line * self.width * 4);
    return addr;

} // baseAddressForLine

@end // Bitmap

