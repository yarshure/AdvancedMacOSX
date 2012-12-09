// Bitmap.h -- Wrap a bucket of 4-byte pixels, with ready access to 
//             the base address of individual scanlines and easy image rep
//             creation.

#import <Cocoa/Cocoa.h>

// The buffer is composed of a linear array of 32-bit elements, ordered
// RGBA.

@interface Bitmap : NSObject {
    unsigned char *_buffer; // A bucket of bytes.
}

@property (readonly, assign) NSUInteger width;
@property (readonly, assign) NSUInteger height;

// Make a new bitmap with the given width and height.
- (id) initWithWidth: (NSUInteger) width
              height: (NSUInteger) height;

// Returns an image representation suitable for drawing.
- (NSBitmapImageRep *) imageRep;

// Get the location in memory for a particular scanline in the bitmap.
// You can safely travel width * 4 bytes along its path without a lock.
- (unsigned char *) baseAddressForLine: (NSUInteger) line;

@end // Bitmap
