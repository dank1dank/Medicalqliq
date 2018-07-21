//
//  NSString+Path.h
//  qliq
//
//  Created by Vita on 7/11/12.
//  Copyright (c) 2012 Al Digit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Path)

- (NSString*)lastFolderAndFilename; // returns from aaa/bbb/ccc/ddd/eee.ff ddd/eee.ff

@end
