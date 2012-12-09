//
//  SortThemAppDelegate.m
//  SortThem
//
//  Created by Mark Dalrymple on 1/8/11.
//  Copyright 2011 Borkware, LLC. All rights reserved.
//

#import "SortThemAppDelegate.h"

@implementation SortThemAppDelegate
@synthesize window = _window;
@synthesize inText = _inText;
@synthesize outText = _outText;

- (IBAction) sort: (id) sender {
    NSTask *task = [[NSTask alloc] init];
    NSPipe *inPipe = [[NSPipe alloc] init];
    NSPipe *outPipe = [[NSPipe alloc] init];

    [task setLaunchPath: @"/usr/bin/sort"];
    [task setStandardOutput: outPipe];
    [task setStandardInput: inPipe];
    [task setArguments: @[@"-f"]];
    
    [task launch];

    NSFileHandle *writingHandle = [inPipe fileHandleForWriting];
    NSData *outData = [[self.inText string] dataUsingEncoding: NSUTF8StringEncoding];
    [writingHandle writeData: outData];
    [writingHandle closeFile];

    NSData *inData = [[outPipe fileHandleForReading] readDataToEndOfFile];
    NSString *string = [[NSString alloc] initWithData: inData
                                         encoding: NSUTF8StringEncoding];
    [self.outText setString: string];


} // sort

@end // SortThemAppDelegate
