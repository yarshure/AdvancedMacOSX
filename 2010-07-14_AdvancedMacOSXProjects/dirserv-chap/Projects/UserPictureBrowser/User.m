//
//  User.m
//  UserPictureBrowser
//
//  Created by Aaron Hillegass on Mon Sep 30 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "User.h"

@implementation User

- (id)initWithUserName:(NSString *)un realName:(NSString *)rn picturePath:(NSString *)pp
{
    [super init];
    userName = [un copy];
    realName = [rn copy];
    picturePath = [pp copy];
    _imageCache = nil;
    return self;
}

- (NSString *)userName
{
    return userName;
}
- (NSString *)realName
{
    return realName;
}
- (NSImage *)picture
{
    if (!_imageCache) {
        _imageCache = [[NSImage alloc] initWithContentsOfFile:picturePath];
    }
    return _imageCache;
}
- (NSString *)picturePath
{
    return picturePath;
}

- (void)dealloc
{
    [userName release];
    [_imageCache release];
    [picturePath release];
    [realName release];
    [super dealloc];
}
@end
