// properties.m -- play with properties.

// clang -g -Weverything -framework Cocoa -o properties properties.m

// 1 == setter/getter, 2 == properties
// define on the compile line with -DVARIANT=1 or -DVARIANT=2

#ifndef VARIANT
#define VARIANT 1
#endif

#import <Cocoa/Cocoa.h>

#if VARIANT == 1

@interface LotusBlossom : NSObject {
    NSString *_name;
    NSColor *_color;
    int _size;
}

- (void) setName: (NSString *) name;
- (NSString *) name;

- (void) setColor: (NSColor *) color;
- (NSColor *) color;

- (void) setSize: (int) size;
- (int) size;

@end // LotusBlossom(setter/getter)

@implementation LotusBlossom

- (void) setName: (NSString *) name {
    if (_name != name) {
        [_name release];
        _name = [name copy];
    }
} // setName
- (NSString *) name {
    return _name;
} // name

- (void) setColor: (NSColor *) color {
    if (_color != color) {
        [_color release];
        _color = [color retain];
    }
}
- (NSColor *) color {
    return _color;
} // color

- (void) setSize: (int) size {
    _size = size;
} // setSize
- (int) size {
    return _size;
} // size


- (void) dealloc {
    [_name release];
    [_color release];

    [super dealloc];
} // dealloc

- (NSString *) description {
    return ([NSString stringWithFormat: @"blossom %@ : %@ / %d", 
                      _name, _color, _size]);
} // description

@end // LotusBlossom(setter/getter)

#endif


#if VARIANT == 2

@interface LotusBlossom : NSObject {
    NSString *_name;
    NSColor *_color;
    int _size;
}
// You can leave the |atomic| out, which is the default.
// -Weverything warns about assumed atomicity, so go ahead and
// explicitly add it here.
@property (atomic, copy) NSString *name;
@property (atomic, retain) NSColor *color;
@property (atomic, assign) int size;


@end // LotusBlossom(properties)

@implementation LotusBlossom
@synthesize name = _name;
@synthesize color = _color;
@synthesize size = _size;

- (void) dealloc {
    [_name release];
    [_color release];

    [super dealloc];
} // dealloc

- (NSString *) description {
    return [NSString stringWithFormat: @"blossom %@ : %@ / %d", 
                     _name, _color, _size];
} // description

@end // LotusBlossom(properties)

#endif


int main (void) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

#if VARIANT == 1
    LotusBlossom *blossom = [[LotusBlossom alloc] init];
    [blossom setName: @"Hoff"];
    [blossom setColor: [NSColor whiteColor]];
    [blossom setSize: 23];

    NSLog (@"%@", blossom);
#endif

#if VARIANT == 2
    LotusBlossom *blossom = [[LotusBlossom alloc] init];
    blossom.name = @"Hoff";
    blossom.color = [NSColor whiteColor];
    blossom.size = 23;

    NSLog (@"%@ of color %@ has size %d",
           blossom.name, blossom.color, blossom.size);
#endif

    [blossom release];
    [pool drain];

    return 0;

} // main
