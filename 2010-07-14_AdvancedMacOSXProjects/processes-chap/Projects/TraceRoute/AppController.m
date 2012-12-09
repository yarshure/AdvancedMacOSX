#import "AppController.h"

@implementation AppController

// Append the data to the string in the text view
- (void)appendData:(NSData *)d {
    NSRange endRange = NSMakeRange([[textView string] length],0);
    NSString *string = [[NSString alloc] initWithData:d 
                                  encoding:NSASCIIStringEncoding];
    [textView replaceCharactersInRange:endRange
                            withString:string];
    [string release];
}

- (void)cleanup 
{
    // Release the old task
    [task release];
    task = nil;

    // Release the pipe
    [pipe release];
    pipe = nil;

    // Change the title on the button
    [button setTitle:@"Trace the route"];

    // No longer an observer
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)taskTerminated:(NSNotification *)note
{
    NSData *leftInPipe;
    // Flush data still in pipe
    leftInPipe = [[pipe fileHandleForReading] readDataToEndOfFile];
    if (leftInPipe)
       [self appendData:leftInPipe];
    [self cleanup];
}

- (IBAction)startStop:(id)sender
{
   // Is the task already running?
   if ([task isRunning]) {
       // Stop it and tidy up
       [task terminate];
       [self cleanup];
   } else {
       // Create a task and pipe
       task = [[NSTask alloc] init];
       pipe = [[NSPipe alloc] init];

       // Set the attributes of the task
       [task setLaunchPath:@"/usr/sbin/traceroute"];
       [task setArguments:[NSArray arrayWithObject:
                                    [hostField stringValue]]];
       [task setStandardOutput:pipe];
       [task setStandardError:pipe];

       // Register for notifications
       [[NSNotificationCenter defaultCenter] addObserver:self 
                      selector:@selector(dataReady:)  
                          name:NSFileHandleReadCompletionNotification 
                        object:[pipe fileHandleForReading]];
       [[NSNotificationCenter defaultCenter] addObserver: self 
                      selector:@selector(taskTerminated:) 
                          name:NSTaskDidTerminateNotification 
                        object:task];
       // Launch the task
       [task launch];
       [button setTitle:@"Terminate"];
       [textView setString:@""];

       // Get the pipe reading in the background
       [[pipe fileHandleForReading] readInBackgroundAndNotify];
    }
}

- (void)dataReady:(NSNotification *)note 
{
    NSData *data = [[note userInfo] 
                  valueForKey:NSFileHandleNotificationDataItem]; 
    if (data)
       [self appendData:data];
    // Must restart reading in background after each notification
    [[pipe fileHandleForReading] readInBackgroundAndNotify];
}

@end

