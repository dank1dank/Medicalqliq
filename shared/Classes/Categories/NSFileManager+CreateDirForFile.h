//
//  NSFileManager+CreateDirForFile.h
//  qliq
//
//  Created by Paul Bar on 5/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (CreateDirForFile)

-(BOOL) createDirectoryForFileAtPath:(NSString*)path;

@end
