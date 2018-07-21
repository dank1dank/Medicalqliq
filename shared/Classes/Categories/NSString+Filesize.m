//
//  NSString+Filesize.m
//  qliq
//
//  Created by Aleksey Garbarev on 11/9/12.
//
//

#import "NSString+Filesize.h"

@implementation NSString (NSString_Filesize)

+ (NSString *) fileSizeFromBytes:(NSUInteger)bytes{

    if (bytes > 1024*1024*1024)
        return [NSString stringWithFormat:@"%g GB",floor((bytes*100)/(1024*1024*1024))/100];
    else if (bytes > 1024*1024)
        return [NSString stringWithFormat:@"%g MB",floor((bytes*100)/(1024*1024))/100];
    else
        return [NSString stringWithFormat:@"%g KB",floor((bytes*100)/(1024))/100];
    
}

@end