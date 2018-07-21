//
//  LogCustomFormatter.m
//  CCiPhoneApp
//
//  Created by Adam Sowa on 9/14/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "LogCustomFormatter.h"


@implementation LogCustomFormatter

- (id)init
{
    if((self = [super init]))
    {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
        [dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss:SSS"];
    }
    return self;
}

static const char *fileNameFromPath(const char *path)
{
	const char *prev = path;
	const char *p = 0;
	
	while ((p = strstr(prev, "/"))) {
		prev = p + 1;
	}
	
	return prev;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    NSString *logLevel;
    switch (logMessage->_flag)
    {
        case LOG_FLAG_ERROR     : logLevel = @"E"; break;
        case LOG_FLAG_WARN      : logLevel = @"W"; break;
        case LOG_FLAG_INFO      : logLevel = @"I"; break;
        case LOG_FLAG_DEBUG     : logLevel = @"D"; break;
        case LOG_FLAG_SUPPORT   : logLevel = @"S"; break;
        default                 : logLevel = @"V"; break;
    }
    
    NSString *dateAndTime = [dateFormatter stringFromDate:(logMessage->_timestamp)];
    NSString *logMsg = logMessage->_message;
    
    return [NSString stringWithFormat:@"%@ %@ | %@\n", logLevel, dateAndTime, logMsg];
}

- (void)dealloc
{
    [dateFormatter release];
    [super dealloc];
}

@end
