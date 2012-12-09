//
//  AuthorizingFileManager.m
//  Remover
//
//  Created by Aaron Hillegass on Tue Sep 10 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

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

	// Create an empty authorization
	status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &authorizationRef);
	if (status != errAuthorizationSuccess) {
		fprintf(stderr, "Failed to create the authref: %ld.\n", status);
		return NO;
	}
	return self;
}

#if 0
- (BOOL)preauthorizeForRight:(const char *)rightName
{
	OSStatus status;
	AuthorizationItem right = { rightName, 0, NULL, 0 };
	AuthorizationRights rightSet = { 1, &right };
	AuthorizationFlags flags = kAuthorizationFlagDefaults | kAuthorizationFlagPreAuthorize | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagExtendRights;

	status = AuthorizationCopyRights(authorizationRef, &rightSet, kAuthorizationEmptyEnvironment, flags, NULL);

	return (status == errAuthorizationSuccess);
}
- (NSData *)authorizationAsData
{
	NSData *result;
	AuthorizationExternalForm extAuth;
	if (AuthorizationMakeExternalForm(authorizationRef, &extAuth))
        return nil;
	result = [NSData dataWithBytes:&extAuth length:sizeof(extAuth)];
	return result;
}
// Create a task with pipes for input and output
- (NSTask *)taskForExecutable:(NSString *)execName argument:(NSString *)arg
{
	NSString *executablePath;
	NSPipe *inPipe, *outPipe;
	NSTask *task;

	// Create a task for the requested executable
	task = [[NSTask alloc] init];
	executablePath = [[NSBundle mainBundle] pathForResource:execName ofType:@""];
    if (!executablePath) {
        NSRunAlertPanel(@"No executable", @"Can not find %@",  nil, nil, nil, execName);
        return nil;
    }
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


- (NSArray *)directoryContentsAtPath:(NSString *)path
{
	NSFileHandle *inFile, *outFile;
	NSArray *result = nil;
	NSTask *task;
	NSData *output = nil, *authData = nil;
	NSString *outputAsString = nil;

	result = [fileManager directoryContentsAtPath:path];

	// Is there no result (because the file manager didn't have
	// permissions probably.
	if (!result) {

		// preauthorize
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
			outputAsString = [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];

			// Break into components
			result = [outputAsString componentsSeparatedByString:@"\n"];

			// Release the string
			[outputAsString release];
		}
	}
	return result;
}

- (NSDictionary *)fileAttributesAtPath:(NSString *)path traverseLink:(BOOL)willTraverse
{
	NSDictionary *result;
	result = [fileManager fileAttributesAtPath:path traverseLink:willTraverse];
	if (!result) {
		NSFileHandle *inFile, *outFile;
		NSTask *task;
		NSData *output, *authData;
		NSString *outputAsString;

		// preauthorize
		if (![self preauthorizeForRight:LIST_RIGHT]) {
			NSLog(@"Unable to preauthorize");
			return nil;
		}

		// Pack authorization for piping to tool
		authData = [self authorizationAsData];

		// Create a task
		task = [self taskForExecutable:@"remover_statter" argument:path];
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
		outputAsString = [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];

		// Break into components
		result = [NSMutableDictionary dictionary];
		[(NSMutableDictionary *)result setObject:outputAsString forKey:NSFileType];

		// Release the string
		[outputAsString release];
	}
	return result;
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
		task = [self taskForExecutable:@"remover_deletor" argument:path];
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
#endif

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

- (void)dealloc
{
	[fileManager release];
	AuthorizationFree(authorizationRef, kAuthorizationFlagDestroyRights);
	[super dealloc];
}
@end
