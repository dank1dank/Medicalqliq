//
//  FileLogger.h
//  qliq
//
//  Created by Evgeniy Gushchin on 2/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DDFileLogger.h"

@interface FileLoggerManager : NSObject<DDLogFileManager>
{
	NSUInteger maximumNumberOfLogFiles;
	NSString *_logsDirectory;
}
@property (readwrite, assign) NSUInteger maximumNumberOfLogFiles;
- (id)init;
- (id)initWithLogsDirectory:(NSString *)logsDirectory;

- (NSArray *)unsortedLogFilePaths;

+ (NSString *)defaultLogsDirectory;
@end



