//
//  FileLogger.m
//  qliq
//
//  Created by Evgeniy Gushchin on 2/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FileLoggerManager.h"
#define LOG_LEVEL 2

#define NSLogError(frmt, ...)    do{ if(LOG_LEVEL >= 1) NSLog((frmt), ##__VA_ARGS__); } while(0)
#define NSLogWarn(frmt, ...)     do{ if(LOG_LEVEL >= 2) NSLog((frmt), ##__VA_ARGS__); } while(0)
#define NSLogInfo(frmt, ...)     do{ if(LOG_LEVEL >= 3) NSLog((frmt), ##__VA_ARGS__); } while(0)
#define NSLogVerbose(frmt, ...)  do{ if(LOG_LEVEL >= 4) NSLog((frmt), ##__VA_ARGS__); } while(0)

@implementation FileLoggerManager

@synthesize maximumNumberOfLogFiles;
@synthesize logFilesDiskQuota;

- (id)init
{
	return [self initWithLogsDirectory:nil];
}

- (id)initWithLogsDirectory:(NSString *)aLogsDirectory
{
	if ((self = [super init]))
	{
        maximumNumberOfLogFiles = 5;//DEFAULT_LOG_MAX_NUM_LOG_FILES;
		
		if (aLogsDirectory)
			_logsDirectory = [aLogsDirectory copy];
		else
			_logsDirectory = [[FileLoggerManager defaultLogsDirectory] copy];
		
		NSKeyValueObservingOptions kvoOptions = NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew;
		
		[self addObserver:self forKeyPath:@"maximumNumberOfLogFiles" options:kvoOptions context:nil];
		
		NSLogVerbose(@"DDFileLogManagerDefault: logsDirectory:\n%@", [self logsDirectory]);
		NSLogVerbose(@"DDFileLogManagerDefault: sortedLogFileNames:\n%@", [self sortedLogFileNames]);
	}
	return self;
}

- (void)dealloc
{
	[_logsDirectory release];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Configuration
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
	NSNumber *old = [change objectForKey:NSKeyValueChangeOldKey];
	NSNumber *new = [change objectForKey:NSKeyValueChangeNewKey];
	
	if ([old isEqual:new])
	{
		// No change in value - don't bother with any processing.
		return;
	}
	
	if ([keyPath isEqualToString:@"maximumNumberOfLogFiles"])
	{
		NSLogInfo(@"DDFileLogManagerDefault: Responding to configuration change: maximumNumberOfLogFiles");
		
//		if (IS_GCD_AVAILABLE) //AII
//		{
//#if GCD_MAYBE_AVAILABLE
//			
			dispatch_async([DDLog loggingQueue], ^{
                
                @autoreleasepool {
                    
                    [self deleteOldLogFiles];
                }
			});
//			
//#endif
//		}
//		else
//		{
//#if GCD_MAYBE_UNAVAILABLE
//			
//			[self performSelector:@selector(deleteOldLogFiles)
//			             onThread:[DDLog loggingThread]
//			           withObject:nil
//			        waitUntilDone:NO];
//			
//#endif
//		}
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark File Deleting
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Deletes archived log files that exceed the maximumNumberOfLogFiles configuration value.
 **/
- (void)deleteOldLogFiles
{
	NSLogVerbose(@"DDLogFileManagerDefault: deleteOldLogFiles");
	
	NSArray *sortedLogFileInfos = [self sortedLogFileInfos];
	
	NSUInteger maxNumLogFiles = self.maximumNumberOfLogFiles;
	
	// Do we consider the first file?
	// We are only supposed to be deleting archived files.
	// In most cases, the first file is likely the log file that is currently being written to.
	// So in most cases, we do not want to consider this file for deletion.
	
	NSUInteger count = [sortedLogFileInfos count];
	BOOL excludeFirstFile = NO;
	
	if (count > 0)
	{
		DDLogFileInfo *logFileInfo = [sortedLogFileInfos objectAtIndex:0];
		
		if (!logFileInfo.isArchived)
		{
			excludeFirstFile = YES;
		}
	}
	
	NSArray *sortedArchivedLogFileInfos;
	if (excludeFirstFile)
	{
		count--;
		sortedArchivedLogFileInfos = [sortedLogFileInfos subarrayWithRange:NSMakeRange(1, count)];
	}
	else
	{
		sortedArchivedLogFileInfos = sortedLogFileInfos;
	}
	
	NSUInteger i;
	for (i = 0; i < count; i++)
	{
		if (i >= maxNumLogFiles)
		{
			DDLogFileInfo *logFileInfo = [sortedArchivedLogFileInfos objectAtIndex:i];
			
			NSLogInfo(@"DDLogFileManagerDefault: Deleting file: %@", logFileInfo.fileName);
			
			[[NSFileManager defaultManager] removeItemAtPath:logFileInfo.filePath error:nil];
		}
	}
}
#pragma mark - 
#pragma mark FileRolling
-(void)didRollAndArchiveLogFile:(NSString *)logFilePath
{
    // Adam Sowa: I consider this code a bug.
    // It truncates the just archived file to zero size.
/*
    NSFileHandle *file;
    
    file = [NSFileHandle fileHandleForUpdatingAtPath:logFilePath];
    
    if (file == nil)
        NSLogInfo(@"Failed to open file");
    
    [file truncateFileAtOffset: 0];
    
    [file closeFile];
*/
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Log Files
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Returns the path to the default logs directory.
 * If the logs directory doesn't exist, this method automatically creates it.
 **/
+ (NSString *)defaultLogsDirectory
{
#if TARGET_OS_IPHONE
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *baseDir = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
#else
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
	
	NSString *appName = [[NSProcessInfo processInfo] processName];
	
	NSString *baseDir = [basePath stringByAppendingPathComponent:appName];
#endif
	
	return [baseDir stringByAppendingPathComponent:@"Logs"];
}

- (NSString *)logsDirectory
{
	// We could do this check once, during initalization, and not bother again.
	// But this way the code continues to work if the directory gets deleted while the code is running.
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:_logsDirectory])
	{
		NSError *err = nil;
		if (![[NSFileManager defaultManager] createDirectoryAtPath:_logsDirectory
		                               withIntermediateDirectories:YES attributes:nil error:&err])
		{
			NSLogError(@"DDFileLogManagerDefault: Error creating logsDirectory: %@", err);
		}
	}
	
	return _logsDirectory;
}

- (BOOL)isLogFile:(NSString *)fileName
{
    return [fileName hasPrefix:@"log-"] && [fileName hasSuffix:@".txt"];
/*
	// A log file has a name like "log-<uuid>.txt", where <uuid> is a HEX-string of 6 characters.
	// 
	// For example: log-DFFE99.txt
	
	BOOL hasProperPrefix = [fileName hasPrefix:@"log-"];
	
	BOOL hasProperLength = [fileName length] >= 10;
	
	
	if (hasProperPrefix && hasProperLength)
	{
		NSCharacterSet *hexSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEF"];
		
		NSString *hex = [fileName substringWithRange:NSMakeRange(4, 6)];
		NSString *nohex = [hex stringByTrimmingCharactersInSet:hexSet];
		
		if ([nohex length] == 0)
		{
			return YES;
		}
	}
	
	return NO;*/
}

/**
 * Returns an array of NSString objects,
 * each of which is the filePath to an existing log file on disk.
 **/
- (NSArray *)unsortedLogFilePaths
{
	NSString *logsDirectory = [self logsDirectory];
	NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:logsDirectory error:nil];
	
	NSMutableArray *unsortedLogFilePaths = [NSMutableArray arrayWithCapacity:[fileNames count]];
	
	for (NSString *fileName in fileNames)
	{
		// Filter out any files that aren't log files. (Just for extra safety)
		
		if ([self isLogFile:fileName])
		{
			NSString *filePath = [logsDirectory stringByAppendingPathComponent:fileName];
			
			[unsortedLogFilePaths addObject:filePath];
		}
	}
	
	return unsortedLogFilePaths;
}

/**
 * Returns an array of NSString objects,
 * each of which is the fileName of an existing log file on disk.
 **/
- (NSArray *)unsortedLogFileNames
{
	NSArray *unsortedLogFilePaths = [self unsortedLogFilePaths];
	
	NSMutableArray *unsortedLogFileNames = [NSMutableArray arrayWithCapacity:[unsortedLogFilePaths count]];
	
	for (NSString *filePath in unsortedLogFilePaths)
	{
		[unsortedLogFileNames addObject:[filePath lastPathComponent]];
	}
	
	return unsortedLogFileNames;
}

/**
 * Returns an array of DDLogFileInfo objects,
 * each representing an existing log file on disk,
 * and containing important information about the log file such as it's modification date and size.
 **/
- (NSArray *)unsortedLogFileInfos
{
	NSArray *unsortedLogFilePaths = [self unsortedLogFilePaths];
	
	NSMutableArray *unsortedLogFileInfos = [NSMutableArray arrayWithCapacity:[unsortedLogFilePaths count]];
	
	for (NSString *filePath in unsortedLogFilePaths)
	{
		DDLogFileInfo *logFileInfo = [[DDLogFileInfo alloc] initWithFilePath:filePath];
		
		[unsortedLogFileInfos addObject:logFileInfo];
		[logFileInfo release];
	}
	
	return unsortedLogFileInfos;
}

/**
 * Just like the unsortedLogFilePaths method, but sorts the array.
 * The items in the array are sorted by modification date.
 * The first item in the array will be the most recently modified log file.
 **/
- (NSArray *)sortedLogFilePaths
{
	NSArray *sortedLogFileInfos = [self sortedLogFileInfos];
	
	NSMutableArray *sortedLogFilePaths = [NSMutableArray arrayWithCapacity:[sortedLogFileInfos count]];
	
	for (DDLogFileInfo *logFileInfo in sortedLogFileInfos)
	{
		[sortedLogFilePaths addObject:[logFileInfo filePath]];
	}
	
	return sortedLogFilePaths;
}

/**
 * Just like the unsortedLogFileNames method, but sorts the array.
 * The items in the array are sorted by modification date.
 * The first item in the array will be the most recently modified log file.
 **/
- (NSArray *)sortedLogFileNames
{
	NSArray *sortedLogFileInfos = [self sortedLogFileInfos];
	
	NSMutableArray *sortedLogFileNames = [NSMutableArray arrayWithCapacity:[sortedLogFileInfos count]];
	
	for (DDLogFileInfo *logFileInfo in sortedLogFileInfos)
	{
		[sortedLogFileNames addObject:[logFileInfo fileName]];
	}
	
	return sortedLogFileNames;
}

/**
 * Just like the unsortedLogFileInfos method, but sorts the array.
 * The items in the array are sorted by modification date.
 * The first item in the array will be the most recently modified log file.
 **/
- (NSArray *)sortedLogFileInfos
{
	return [[self unsortedLogFileInfos] sortedArrayUsingSelector:@selector(reverseCompareByCreationDate:)];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Creation
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Generates a short UUID suitable for use in the log file's name.
 * The result will have six characters, all in the hexadecimal set [0123456789ABCDEF].
 **/
- (NSString *)generateShortUUID
{
	CFUUIDRef uuid = CFUUIDCreate(NULL);
	
	CFStringRef fullStr = CFUUIDCreateString(NULL, uuid);
	CFStringRef shortStr = CFStringCreateWithSubstring(NULL, fullStr, CFRangeMake(0, 6));
	
	CFRelease(fullStr);
	CFRelease(uuid);
	
	return [NSMakeCollectable(shortStr) autorelease];
}

/**
 * Generates a new unique log file path, and creates the corresponding log file.
 **/
- (NSString *)createNewLogFile
{
	// Generate a random log file name, and create the file (if there isn't a collision)
	
	NSString *logsDirectory = [self logsDirectory];
    NSString *dateString = nil;
    NSString *uniqueSuffix = @"";
    int sequenceNumber = 1;
    {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH-mm"];
        NSDate *currentDate = [NSDate date];
        dateString = [formatter stringFromDate:currentDate];
    }
	do
	{
		NSString *fileName = [NSString stringWithFormat:@"log-%@%@.txt", dateString, uniqueSuffix];
		
		NSString *filePath = [logsDirectory stringByAppendingPathComponent:fileName];
		
		if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
		{
			NSLogVerbose(@"DDLogFileManagerDefault: Creating new log file: %@", fileName);
			
			[[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
			
			// Since we just created a new log file, we may need to delete some old log files
			[self deleteOldLogFiles];
			
			return filePath;
		}
        else
        {
            uniqueSuffix = [NSString stringWithFormat:@"-%d", ++sequenceNumber];
        }
		
	} while(YES);
}

@end
