//
//  NSString+Filesize.h
//  qliq
//
//  Created by Aleksey Garbarev on 11/9/12.
//
//

#import <Foundation/Foundation.h>

@interface NSString (NSString_Filesize)

+ (NSString *) fileSizeFromBytes:(NSUInteger)bytes;

@end
