//
//  User.h
//  UserPictureBrowser
//
//  Created by Aaron Hillegass on Mon Sep 30 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface User : NSObject {
    NSString *userName;
    NSString *realName;
    NSString *picturePath;
    NSImage *_imageCache;
}

- (id)initWithUserName:(NSString *)un realName:(NSString *)rn picturePath:(NSString *)pp;;

- (NSString *)userName;
- (NSString *)realName;
- (NSImage *)picture;
- (NSString *)picturePath;

@end
