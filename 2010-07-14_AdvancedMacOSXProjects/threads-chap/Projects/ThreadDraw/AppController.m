#import "AppController.h"
#import <unistd.h> // for sleep

@implementation AppController



- (NSPoint) randomPointInBounds: (NSRect) bounds
{
    NSPoint result;
    int width, height;
    width = round (bounds.size.width);
    height = round (bounds.size.height);
    result.x = (random() % width) + bounds.origin.x;
    result.y = (random() % height) + bounds.origin.y;

    return (result);

} // randomPointInBounds



- (void) threadDraw: (NSColor *) color
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSPoint lastPoint = [drawView bounds].origin;

    while (1) {

	if ([drawView lockFocusIfCanDraw]) {
	    NSPoint point = [self randomPointInBounds: [drawView bounds]];

	    [color set];

	    [NSBezierPath strokeLineFromPoint: lastPoint  toPoint: point];
	    [[drawView window] flushWindow];

	    [drawView unlockFocus];
	    usleep (random() % 500000); // up to 1/2 second

	    lastPoint = point;
	}
    }

    [pool release];

} // threadDraw



- (void) awakeFromNib
{
    [drawView setNeedsDisplay: YES];

    [NSThread detachNewThreadSelector: @selector(threadDraw:) 
	      toTarget: self
	      withObject: [NSColor redColor]];

    [NSThread detachNewThreadSelector: @selector(threadDraw:) 
	      toTarget: self
	      withObject: [NSColor blueColor]];

    [NSThread detachNewThreadSelector: @selector(threadDraw:) 
	      toTarget: self
	      withObject: [NSColor greenColor]];

    [NSThread detachNewThreadSelector: @selector(threadDraw:) 
	      toTarget: self
	      withObject: [NSColor yellowColor]];

} // awakeFromNib



@end // AppController
