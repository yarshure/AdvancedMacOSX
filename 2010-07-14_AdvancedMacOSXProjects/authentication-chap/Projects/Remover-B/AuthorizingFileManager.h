#define LIST_RIGHT "com.bignerdranch.remover.readforbiddendirectories"
#define DELETE_RIGHT "com.bignerdranch.remover.deleteforbiddendirectories"

#import <Foundation/Foundation.h>
#import <Security/Security.h>

@interface AuthorizingFileManager : NSObject {
    AuthorizationRef authorizationRef;
    NSFileManager *fileManager;
}
+ (id)defaultManager;
@end
