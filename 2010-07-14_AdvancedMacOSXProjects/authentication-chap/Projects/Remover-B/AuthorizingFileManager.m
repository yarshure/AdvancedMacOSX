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
    OSStatus status;
    [super init];
    fileManager = [[NSFileManager defaultManager] retain];
    
    // Create an empty authorization structure
    status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, 
                                 kAuthorizationFlagDefaults, &authorizationRef);
    if (status != errAuthorizationSuccess) {
        NSLog(@"Failed to create the authref: %d.", status);
        [self release];
        return nil;
    }
    return self;
}

- (void)dealloc
{
    [fileManager release];
    AuthorizationFree(authorizationRef, kAuthorizationFlagDestroyRights);
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
- (BOOL)preauthorizeForRight:(const char *)rightName
{
    OSStatus status;
    AuthorizationItem right = { rightName, 0, NULL, 0 };
    AuthorizationRights rightSet = { 1, &right };
    AuthorizationFlags flags = kAuthorizationFlagDefaults | 
        kAuthorizationFlagPreAuthorize | 
        kAuthorizationFlagInteractionAllowed | 
        kAuthorizationFlagExtendRights;
    
    // This may cause the authorization panel to appear
    status = AuthorizationCopyRights(authorizationRef, &rightSet, 
                                     kAuthorizationEmptyEnvironment, flags, NULL);
    
    return (status == errAuthorizationSuccess);
}

- (NSData *)authorizationAsData
{
    AuthorizationExternalForm extAuth;
    if (AuthorizationMakeExternalForm(authorizationRef, &extAuth))
        return nil;
    return [NSData dataWithBytes:&extAuth length:sizeof(extAuth)];
}

// Create a task with pipes for input and output
- (NSTask *)taskForExecutable:(NSString *)execName 
                     argument:(NSString *)arg
{
    NSString *executablePath;
    NSPipe *inPipe, *outPipe;
    NSTask *task;
    
    // Create a task for the requested executable
    task = [[NSTask alloc] init];
    executablePath = [[NSBundle mainBundle] pathForResource:execName 
                                                     ofType:@""];
    [task setLaunchPath:executablePath];
    [task setArguments:[NSArray arrayWithObject:arg]];
    
    // Set up the inPipe
    inPipe = [[NSPipe alloc] init];
    [task setStandardInput:inPipe];
    [inPipe release];
    
    // Set up the outPipe
    outPipe = [[NSPipe alloc] init];
    [task setStandardOutput:outPipe];
    [outPipe release];
    
    [task autorelease];
    return task;
}
- (BOOL)removeFileAtPath:(NSString *)path handler:handler
{
    BOOL successful = [fileManager removeFileAtPath:path handler:self];
    if (!successful) {
        NSFileHandle *inFile;
        NSTask *task;
        NSData  *authData;
        
        // preauthorize
        if (![self preauthorizeForRight:DELETE_RIGHT]) {
            NSLog(@"Unable to preauthorize delete");
            return NO;
        }
        
        // Pack authorization for piping to tool
        authData = [self authorizationAsData];
        
        // Create a task
        task = [self taskForExecutable:@"remover_deletor" 
                              argument:path];
        if (!task) {
            NSLog(@"Unable to create task");
            return NO;
        }
        
        // Get filehandle for writing
        inFile = [[task standardInput] fileHandleForWriting];
        
        // Launch the task
        [task launch];
        
        // Pipe the authData to the tool and send EOF
        [inFile writeData:authData];
        [inFile closeFile];
        
        // Was it successful?
        [task waitUntilExit];
        successful = ([task terminationStatus] == 0);
    }
    
    return successful;
}
- (NSArray *)directoryContentsAtPath:(NSString *)path
{

    NSFileHandle *inFile, *outFile;
    NSArray *result = nil;
    NSTask *task;
    NSData *output = nil, *authData = nil;
    NSString *outputAsString = nil;
    
    // Can we do it the easy way?
    if ([fileManager isReadableFileAtPath:path]) {
        // List the directory with using NSFileManager
        result = [fileManager directoryContentsAtPath:path];
        return result;
    }
        
    // Preauthorize
    if (![self preauthorizeForRight:LIST_RIGHT]) {
        NSLog(@"Unable to preauthorize");
        return nil;
    }
    
    // Pack authorization for piping to tool
    authData = [self authorizationAsData];
    
    // Create a task
    // Pass the path of the directory to the tool as argv[1]
    task = [self taskForExecutable:@"remover_lister" argument:path];
    if (!task) {
        NSLog(@"Unable to create task");
        return nil;
    }
    
    // Get filehandles for reading and writing
    inFile = [[task standardInput] fileHandleForWriting];
    outFile = [[task standardOutput] fileHandleForReading];
    
    // Launch the task
    [task launch];
    
    // Pipe the authData to the tool and send EOF
    [inFile writeData:authData];
    [inFile closeFile];
    
    // Read the listing of the directory from the tool's
    // standard output
    output = [outFile readDataToEndOfFile];
    
    if ([output length] == 0) {
        result = [NSArray array];
    } else {
        // Convert to an NSString
        outputAsString = [[NSString alloc] initWithData:output 
                                               encoding:NSUTF8StringEncoding];
        
        // Break into components        
        result = [outputAsString componentsSeparatedByString:@"\n"];
        
        // Release the string
        [outputAsString release];
    }
    return result;
}

// This is sort of a cheap solution.  For the exercise,  we only 
// need to know if it is a directory and the size.  I should really 
// put together an entire dictionary of file attributes. 
// This is left as an exercise for the reader.

- (NSDictionary *)fileAttributesAtPath:(NSString *)path 
                          traverseLink:(BOOL)willTraverse
{
    NSDictionary *result;
    
    // Try to use NSFileManager
    result = [fileManager fileAttributesAtPath:path 
                                  traverseLink:willTraverse];
    
    // Was it successful?
    if (result) {
        return result;
    }
    
    // Stat the file the hard way
    NSFileHandle *inFile, *outFile;
    NSTask *task;
    NSData *output, *authData;
    NSString *outputAsString;
    
    // Preauthorize
    if (![self preauthorizeForRight:LIST_RIGHT]) {
        NSLog(@"Unable to preauthorize");
        return nil;
    }
    
    // Pack authorization for piping to tool
    authData = [self authorizationAsData];
    
    // Create a task
    task = [self taskForExecutable:@"remover_statter" 
                          argument:path];
    if (!task) {
        NSLog(@"Unable to create task");
        return nil;
    }
    
    // Get filehandles for reading and writing
    inFile = [[task standardInput] fileHandleForWriting];
    outFile = [[task standardOutput] fileHandleForReading];
    
    // Launch the task
    [task launch];
    
    // Pipe the authData to the tool and send EOF
    [inFile writeData:authData];
    [inFile closeFile];
    
    // Read the listing of the directory from the tool's
    // standard output
    output = [outFile readDataToEndOfFile];
    
    
    // Convert to an NSString
    outputAsString = [[NSString alloc] initWithData:output 
                                           encoding:NSUTF8StringEncoding];
    
    // Break into components
    NSArray *outputArray = [outputAsString componentsSeparatedByString:@"\n"];
    
    // Release the string
    [outputAsString release];
    
    NSMutableDictionary *statResult = [NSMutableDictionary dictionary];
    
    // Is there less than two lines of data?
    if ([outputArray count] < 2) {
        NSLog(@"no stat");
        return statResult;
    }
    
    NSString *fileType = [outputArray objectAtIndex:0];
    int fileSize = [[outputArray objectAtIndex:1] intValue];
    [statResult setObject:fileType 
                   forKey:NSFileType];
    [statResult setObject:[NSNumber numberWithInt:fileSize]
                   forKey:NSFileSize];
    return statResult;
}
@end
