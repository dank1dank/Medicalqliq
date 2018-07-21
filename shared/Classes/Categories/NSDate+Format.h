//
//  NSDate+Format.h
//  qliq
//
//  Created by Vita on 1/18/12.
//  Copyright (c) 2012 Al Digit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Format)

- (NSString*)stringWithTimeAndDate; // return string like Jan 20 11:45 AM
- (NSString*)stringWithTimeWithSecondsAndDate; // return string like Jan 20 11:45:50 AM

@end
