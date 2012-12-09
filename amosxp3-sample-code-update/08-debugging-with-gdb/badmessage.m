// badmessage.m -- send a bad message to an object


// clang -Weverything -g -o badmessage -framework Foundation badmessage.m
#import <Foundation/Foundation.h>

@interface NSObject (QuietCompilerWarning)
- (void) frobulate: (id) frob;
@end // QuietCompilerWarning


int main (void) {
    @autoreleasepool {
        id array = [NSArray array];
        [array frobulate: nil];
    }

    return 0;
} // main
