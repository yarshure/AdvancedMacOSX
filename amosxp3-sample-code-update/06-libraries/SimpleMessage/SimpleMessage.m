// SimpleMessage.m -- a simple plug-in that returns a simple, hard-coded messagex

#import <Foundation/Foundation.h>
#import "BundlePrinter.h"

@interface SimpleMessage : NSObject <BundlePrinterProtocol>
@end // SimpleMessage


@implementation SimpleMessage

+ (BOOL) activate {
    NSLog (@"SimpleMessage plug-in activated");
    return YES;
} // activate

+ (void) deactivate {
    NSLog (@"SimpleMessage plug-in deactivated");
} // deactivate

- (NSString *) message {
    return (@"This is a Simple Message");
} // message

@end // SimpleMessage


