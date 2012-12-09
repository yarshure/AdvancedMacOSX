#import <Cocoa/Cocoa.h>

@interface AuthorizingFileManager : NSObject {
    NSFileManager *fileManager;
}
+ (id)defaultManager;
@end
