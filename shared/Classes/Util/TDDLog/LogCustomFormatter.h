//
//  LogCustomFormatter.h
//  CCiPhoneApp
//
//  Created by Adam Sowa on 9/14/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Log.h"

@interface LogCustomFormatter : NSObject <DDLogFormatter>
{       
    NSDateFormatter *dateFormatter;
}

@end
