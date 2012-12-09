// properties.m -- play with properties.

/* compile with
gcc -g -Wall -framework Cocoa -o properties properties.m
*/

// 1 == setter/getter, 2 == properties
// define on the compile line with -DVARIANT=42

#ifndef VARIANT
#define VARIANT 1
#endif

#import <Cocoa/Cocoa.h>

#if VARIANT == 1

@interface LotusBlossom : NSObject {
    NSString *name;
    NSColor *color;
    int size;
}

- (void) setName: (NSString *) n;
- (NSString *) name;

- (void) setColor: (NSColor *) c;
- (NSColor *) color;

- (void) setSize: (int) s;
- (int) size;

@end // LotusBlossom(setter/getter)

@implementation LotusBlossom

- (void) setName: (NSString *) n {
    if (name != n) {
        [name release];
        name = [n copy];
    }
} // setName
- (NSString *) name {
    return (name);
} // name

- (void) setColor: (NSColor *) c {
    if (color != c) {
        [color release];
        color = [c retain];
    }
}
- (NSColor *) color {
    return (color);
} // color

- (void) setSize: (int) s {
    size = s;
} // setSize
- (int) size {
    return (size);
} // size


- (void) dealloc {
    [name release];
    [color release];

    [super dealloc];
} // dealloc

- (NSString *) description {
    return ([NSString stringWithFormat: @"blossom %@ : %@ / %d", 
                      name, color, size]);
} // description

@end // LotusBlossom(setter/getter)

#endif


#if VARIANT == 2

@interface LotusBlossom : NSObject {
    NSString *name;
    NSColor *color;
    int size;
}
@property (readwrite, copy) NSString *name;
@property (readwrite, retain) NSColor *color;
@property (readwrite) int size;


@end // LotusBlossom(properties)

@implementation LotusBlossom
@synthesize name;
@synthesize color;
@synthesize size;

- (void) dealloc {
    [name release];
    [color release];

    [super dealloc];
} // dealloc

- (NSString *) description {
    return ([NSString stringWithFormat: @"blossom %@ : %@ / %d", 
                      name, color, size]);
} // description

@end // LotusBlossom(properties)

#endif


int main (void) {
    [[NSAutoreleasePool alloc] init];

#if VARIANT == 1
    LotusBlossom *blossom = [[LotusBlossom alloc] init];
    [blossom setName: @"Hoff"];
    [blossom setColor: [NSColor whiteColor]];
    [blossom setSize: 23];
#endif

#if VARIANT == 2
    LotusBlossom *blossom = [[LotusBlossom alloc] init];
    blossom.name = @"Hoff";
    blossom.color = [NSColor whiteColor];
    blossom.size = 23;

    NSLog (@"%@ of color %@ has size %d",
           blossom.name, blossom.color, blossom.size);
#endif

    NSLog (@"%@", blossom);

    [blossom release];

    return (0);

} // main
