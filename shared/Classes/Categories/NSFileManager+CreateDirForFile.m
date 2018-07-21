//
//  NSFileManager+CreateDirForFile.m
//  qliq
//
//  Created by Paul Bar on 5/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSFileManager+CreateDirForFile.h"

@implementation NSFileManager (CreateDirForFile)

-(BOOL) createDirectoryForFileAtPath:(NSString *)path
{
    BOOL rez = NO;
    NSString *dirPath = [path stringByDeletingLastPathComponent];
    if(![self fileExistsAtPath:dirPath])
    {
        rez = [self createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    else
    {
        rez = YES;
    }
    return rez;
}

@end
