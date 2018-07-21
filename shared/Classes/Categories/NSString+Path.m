//
//  NSString+Path.m
//  qliq
//
//  Created by Vita on 7/11/12.
//  Copyright (c) 2012 Al Digit. All rights reserved.
//

#import "NSString+Path.h"

@implementation NSString (Path)

- (NSString*)lastFolderAndFilename {
    NSString * filename = [self lastPathComponent];
    NSString * folder = [[self stringByDeletingLastPathComponent] lastPathComponent];
    return [NSString stringWithFormat:@"%@/%@", folder, filename];
}

@end
