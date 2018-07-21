//
//  NSError_Shortcuts.h
//  qliq
//
//  Created by Aleksey Garbarev on 11/14/12.
//
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>


@interface NSError(NSError_Shortcuts)

+ (NSError *) errorWithCode:(NSInteger) code description:(NSString *) description;

@end

@implementation NSError (NSError_Shortcuts)

+ (NSError *) errorWithCode:(NSInteger) code description:(NSString *) description{
    return [NSError errorWithDomain:@"com.qliq" code:code userInfo: @{ NSLocalizedDescriptionKey : description} ];
} 

@end