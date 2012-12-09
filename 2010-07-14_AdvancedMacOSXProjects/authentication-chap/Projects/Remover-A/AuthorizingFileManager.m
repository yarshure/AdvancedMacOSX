#import "AuthorizingFileManager.h"

static AuthorizingFileManager *_defaultAuthFileManager;

@implementation AuthorizingFileManager

+ (id)defaultManager
{
    if (!_defaultAuthFileManager) {
        _defaultAuthFileManager = [[self alloc] init];
    }
    return _defaultAuthFileManager;
}

- (id)init
{
    [super init];
    fileManager = [[NSFileManager defaultManager] retain];
    return self;
}

- (void)dealloc
{
    [fileManager release];
    [super dealloc];
}

// This gets run as part of the creation of the NSInvocation object
// that is passed to forwardInvocation:
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSMethodSignature *result;
    result = [super methodSignatureForSelector:aSelector];
    if (!result){
        result = [fileManager methodSignatureForSelector:aSelector];
    }
    return result;
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    SEL aSelector = [invocation selector];
    if ([fileManager respondsToSelector:aSelector])
        [invocation invokeWithTarget:fileManager];
    else
        [self doesNotRecognizeSelector:aSelector];
}
@end
