#import "TraceRouteAppDelegate.h"
#import <dispatch/dispatch.h>

@implementation TraceRouteAppDelegate

@synthesize window = _window;
@synthesize button = _button;
@synthesize hostField = _hostField;
@synthesize textView = _textView;


// Append the data to the string in the text view

- (void) appendData: (NSData *) data {
    NSRange endRange = NSMakeRange (self.textView.string.length, 0);
    NSString *string = [[NSString alloc] initWithData: data
                                         encoding: NSUTF8StringEncoding];
    [self.textView replaceCharactersInRange: endRange  withString: string];
} // appendData


- (void) cleanup  {
    // Release the old task
    _task = nil;
        
    // Release the pipe
    _pipe = nil;
        
    // Change the title on the button
    [self.button setTitle: @"Trace the route"];
        
    // No longer an observer
    [[NSNotificationCenter defaultCenter] removeObserver: self];
} // cleanup


- (void) taskTerminated: (NSNotification *) notification {
    NSData *leftInPipe;

    // Flush data still in pipe.
    leftInPipe = [[_pipe fileHandleForReading] readDataToEndOfFile];

    if (leftInPipe) [self appendData: leftInPipe];
    [self cleanup];
} // taskTerminated


- (IBAction) startStop: (id) sender {
    // Is the task already running?
    if ([_task isRunning])  {
        // Stop it and tidy up
        [_task terminate];
        [self cleanup];

    } else {
        // Create a task and pipe
        _task = [[NSTask alloc] init];
        _pipe = [[NSPipe alloc] init];
                
        // Set the attributes of the task
        [_task setLaunchPath: @"/usr/sbin/traceroute"];
        [_task setArguments: @[self.hostField.stringValue]];
        [_task setStandardOutput: _pipe];
        [_task setStandardError: _pipe];
                
        // Register for notifications
        [[NSNotificationCenter defaultCenter]
            addObserver: self 
            selector: @selector(dataReady:)
            name: NSFileHandleReadCompletionNotification 
            object: [_pipe fileHandleForReading]];

        [[NSNotificationCenter defaultCenter]
            addObserver:  self 
            selector: @selector(taskTerminated:)  
            name: NSTaskDidTerminateNotification 
            object: _task];

        // Launch the task
        [_task launch];
        [self.button setTitle: @"Terminate"];
        [self.textView setString: @""];
                
        // Get the pipe reading in the background
        [[_pipe fileHandleForReading] readInBackgroundAndNotify];
    }
}


- (void) dataReady: (NSNotification *) notification {
    NSData *data =
        [[notification userInfo]  valueForKey: NSFileHandleNotificationDataItem];
    if (data != nil) [self appendData: data];

    // Must restart reading in background after each notification
    [[_pipe fileHandleForReading] readInBackgroundAndNotify];

} // dataReady

@end // TraceRouteAppDelegate
