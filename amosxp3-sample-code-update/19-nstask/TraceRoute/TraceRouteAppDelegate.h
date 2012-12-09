//
//  TraceRouteAppDelegate.h
//  TraceRoute
//
//  Created by Mark Dalrymple on 8/19/10.
//  Copyright 2010 Borkware, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TraceRouteAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *__weak _window;
    NSButton *__weak _button;
    NSTextField *__weak _hostField;
    NSTextView *__unsafe_unretained _textView;
    NSPipe *_pipe;
    NSTask *_task;
}

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSButton *button;
@property (weak) IBOutlet NSTextField *hostField;
@property (unsafe_unretained) IBOutlet NSTextView *textView;

- (void) dataReady: (NSNotification *) notification;
- (void) taskTerminated: (NSNotification *) notification;
- (void) appendData: (NSData *) ddata;
- (void) cleanup;

- (IBAction) startStop: (id) sender;

@end // TraceRouteAppDelegatex
