//
//  QliqLogFormatter.m
//  qliq
//
//  Created by Aleksey Garbarev on 10/9/12.
//
//

#import "QliqLogFormatter.h"

@implementation QliqLogFormatter{
    NSDateFormatter * dateFormatter;
}

@synthesize showClassName, insertNewLine, showThreadID;


- (id)init{
    self = [super init];
    if(self){
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
        [dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss:SSS"];
        self.showClassName = YES;
        self.insertNewLine = YES;
        self.showThreadID  = YES;
        self.isAslFormatter = NO;
    }
    return self;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage{
    
    NSString *logLevel;
    switch (logMessage->_flag)
    {
        case LOG_FLAG_ERROR   : logLevel = @"E"; break;
        case LOG_FLAG_WARN    : logLevel = @"W"; break;
        case LOG_FLAG_INFO    : logLevel = @"I"; break;
        case LOG_FLAG_DEBUG   : logLevel = @"D"; break;
        case LOG_FLAG_SUPPORT : logLevel = @"S"; break;
        default               : logLevel = @"V"; break;
    }
    NSMutableString * message = nil;;
    
    if (!self.isAslFormatter)
    {
        NSString *dateAndTime = [dateFormatter stringFromDate:(logMessage->_timestamp)];
        
        message = [NSMutableString stringWithFormat:@"%@ %@ |",logLevel,dateAndTime];
        
        if (self.showThreadID){
            [message appendFormat:@"%@|",logMessage->_threadID];
        }
    }
    else
    {
        message = [NSMutableString stringWithFormat:@"%@|",logLevel];
        if (self.showThreadID)
            [message appendFormat:@"%@|",logMessage->_threadID];
    }
    
    if (self.showClassName)
    {
        NSString * classFileName = [logMessage->_file lastPathComponent];
        [message appendFormat:@" %@:",[classFileName stringByDeletingPathExtension]];
    }
    
    [message appendFormat:@" %@",logMessage->_message];
    
    if (self.insertNewLine)
        [message appendString:@"\n"];
    
    
    return message;
}

@end
