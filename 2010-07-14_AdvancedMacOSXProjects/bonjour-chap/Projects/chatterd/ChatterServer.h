#import <Foundation/Foundation.h>
#import "ChatterServing.h"

@interface ChatterServer : NSObject <ChatterServing> {
    NSMutableArray *clients;
}
@end
