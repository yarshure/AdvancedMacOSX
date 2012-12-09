#import "AppController.h"

@implementation AppController

- (IBAction) sort: (id) sender
{
    NSData *data;
    NSPipe *inPipe, *outPipe;
    NSFileHandle *writingHandle;
    NSTask *task;
    NSString *aString;

    task = [[NSTask alloc] init];
    inPipe = [[NSPipe alloc] init];
    outPipe = [[NSPipe alloc] init];

    [task setLaunchPath: @"/usr/bin/sort"];
    [task setStandardOutput: outPipe];
    [task setStandardInput: inPipe];
    [task setArguments: [NSArray arrayWithObject: @"-f"]];
    
    [task launch];

    writingHandle = [inPipe fileHandleForWriting];
    [writingHandle writeData: [[inText string] dataUsingEncoding: NSASCIIStringEncoding]];
    [writingHandle closeFile];

    data = [[outPipe fileHandleForReading] readDataToEndOfFile];
    aString = [[NSString alloc] initWithData: data
				encoding: NSASCIIStringEncoding];
    [outText setString: aString];
    [aString release];

    [task release];
    [inPipe release];
    [outPipe release];

} // sort

@end // AppController

