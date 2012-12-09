//
//  AuthorizingFileManager.h
//  Remover
//
//  Created by Aaron Hillegass on Tue Sep 10 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#define LIST_RIGHT "com.bignerdranch.readForbiddenDirectories"
#define DELETE_RIGHT "com.bignerdranch.deleteForbiddenDirectories"

#import <Foundation/Foundation.h>
#import <Security/Security.h>

@interface AuthorizingFileManager : NSObject {
	AuthorizationRef authorizationRef;
	NSFileManager *fileManager;
}

+ (id)defaultManager;
- (id)init;

- (BOOL)removeFileAtPath:(NSString *)path handler:handler;
- (NSArray *)directoryContentsAtPath:(NSString *)path;
- (NSDictionary *)fileAttributesAtPath:(NSString *)path traverseLink:(BOOL)willTraverse;
- (void)forwardInvocation:(NSInvocation *)anInvocation;

@end
