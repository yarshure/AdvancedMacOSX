// Bitmap.h -- Wrap a bucket of 4-byte pixels, with ready access to 
//             the base address of individual scanlines and easy image rep
//             creation.

#import <Cocoa/Cocoa.h>

// The buffer is composed of a linear array of 32-bit elements, ordered
// RGBA.

@interface Bitmap : NSObject {
    int width;          // number of pixels per line.
    int height;         // number of lines.
    unsigned char *buffer;  // A bucket of bytes.
}

// Make a new bitmap with the given width and height.
- (id) initWithWidth: (int) width
              height: (int) height;

- (int) width;
- (int) height;

// Returns an image representation suitable for drawing.
- (NSBitmapImageRep *) imageRep;

// Get the location in memory for a particular scanline in the bitmap.
// You can safely travel width * 4 bytes along its path without a lock.
- (unsigned char *) baseAddressForLine: (int) line;

@end // Bitmap
