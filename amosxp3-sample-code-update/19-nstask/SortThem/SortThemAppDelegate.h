//
//  SortThemAppDelegate.h
//  SortThem
//
//  Created by Mark Dalrymple on 1/8/11.
//  Copyright 2011 Borkware, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SortThemAppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (unsafe_unretained) IBOutlet NSTextView *inText;
@property (unsafe_unretained) IBOutlet NSTextView *outText;

- (IBAction) sort: (id) sender;

@end // SortThemAppDelegate
