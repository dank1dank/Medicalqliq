//
//  NSDate+Format.m
//  qliq
//
//  Created by Vita on 1/18/12.
//  Copyright (c) 2012 Al Digit. All rights reserved.
//

#import "NSDate+Format.h"

@implementation NSDate (Format)

+ (NSDateFormatter *) dateFormatterForDateTime{
    static NSDateFormatter * dateFormatter;
    if (!dateFormatter){
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MMM d hh:mm a"];
    }
    return dateFormatter;
}

+ (NSDateFormatter *) dateFormatterForDateTimeSeconds{
    static NSDateFormatter * dateFormatter;
    if (!dateFormatter){
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MMM d hh:mm:ss a"];
    }
    return dateFormatter;
}

- (NSString*)stringWithTimeAndDate{
    
    return [[NSDate dateFormatterForDateTime] stringFromDate:self];
}

- (NSString*)stringWithTimeWithSecondsAndDate{
    
    return [[NSDate dateFormatterForDateTimeSeconds] stringFromDate:self];
}

@end
