// zone.m
// play around with NSZones

#import <Foundation/Foundation.h>

int main (int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSZone *zone;

    zone = NSCreateZone (50 * 1024, 4 * 1024, NO);

    
    
    [pool release];

    exit (0);

} // main

