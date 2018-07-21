//
//  ReportIncidentService.m
//  qliq
//
//  Created by Aleksey Garbarev on 11/8/12.
//
//

#import "ReportIncidentService.h"
#import "SSZipArchive.h"
#import "DBUtil.h"
#import "QxPlatfromIOS.h"

@interface ReportIncidentService()

@property (nonatomic, strong) NSString *zipPath;
@property (nonatomic, strong) NSArray *filesToZip;
@property (nonatomic, assign) BOOL zipDefaultFiles;
@property (nonatomic, assign) BOOL zipDatabase;
@property (nonatomic, assign) BOOL zipLogDatabase;

@end

@implementation ReportIncidentService

@synthesize zipPath, filesToZip, zipDefaultFiles, zipDatabase, zipLogDatabase;

+ (NSString *) compressFilesToTempFile:(NSArray *) filePaths
{
    NSString *zipPath = nil;
    if ([filePaths count] > 0) {
        zipPath = [NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"ios-%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"zip"]];
        [[NSFileManager defaultManager] removeItemAtPath:zipPath error:nil];
        NSLog(@"compressedFilePath: %@", zipPath);
        [SSZipArchive createZipFileAtPath:zipPath withFilesAtPaths:filePaths];
    }
    return zipPath;
}

- (id) initWithDefaultFilesAndDatabase:(BOOL)includeDatabase andLogDatabase:(BOOL)includeLogDatabase andMessage:(NSString *)message andSubject:(NSString *)subject isNotifyUser:(BOOL)notifyUser
{
    self = [super initWithMessage:message andSubject:subject notifyUser:notifyUser];
    if (self) {
        self.zipDefaultFiles = YES;
        self.zipDatabase = includeDatabase;
        self.zipLogDatabase = includeLogDatabase;
    }
    return self;
}

- (id) initWithMessage:(NSString *)message andSubject:(NSString *)subject andFilePaths:(NSArray *) filePaths isNotifyUser:(BOOL)notifyUser {
    self = [super initWithMessage:message andSubject:subject notifyUser:notifyUser];
    if (self) {
        self.zipDefaultFiles = NO;
        self.filesToZip = [filePaths copy];
    }
    return self;
}

- (NSString *) serviceName{
    return @"services/report_incident";
}

- (NSString *)filePath{
    return self.zipPath;
}

- (QliqAPIServiceType)type{
    return QliqAPIServiceTypeUpload;
}

- (Schema)requestSchema{
    return ReportIncidentRequestSchema;
}

- (Schema)responseSchema{
    return ReportIncidentResponseSchema;
}

- (void) callServiceWithCompletition:(CompletionBlock)completitionBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *tempFiles = [[NSMutableArray alloc] init];
    
        if (zipDefaultFiles) {
            NSMutableArray *filePaths = [[NSMutableArray alloc] initWithArray:[appDelegate logFilesPaths]];
            [filePaths addObject:[appDelegate stackTraceFilepath]];
            self.filesToZip = filePaths;
        
            if (zipDatabase || zipLogDatabase) {
                BOOL addKeyFile = NO;
                NSString *dbKey = [[DBUtil sharedInstance] dbKey];
                
                if (zipDatabase) {
                    BOOL addOriginalDatabase = YES;
                    
                    if ([dbKey length] > 0) {
                        NSString *tempDbFileName = [[DBUtil sharedInstance] exportPlainText];
                        if (tempDbFileName) {
                            addOriginalDatabase = NO;
                            [filePaths addObject:tempDbFileName];
                            [tempFiles addObject:tempDbFileName];
                        } else {
                            addKeyFile = YES;
                        }
                    }
                    
                    if (addOriginalDatabase) {
                        NSString *dbPath = [[DBUtil sharedInstance] dbPath];
                        [filePaths addObject:dbPath];
                        [filePaths addObject:[dbPath stringByAppendingString:@"-shm"]];
                        [filePaths addObject:[dbPath stringByAppendingString:@"-wal"]];
                    }
                }

                if (zipLogDatabase) {
                    NSString *logDbPath = [[DBUtil sharedInstance] dbPath];
                    logDbPath = [logDbPath stringByDeletingLastPathComponent];
                    logDbPath = [logDbPath stringByAppendingPathComponent:@"log.db"];
                    if ([[NSFileManager defaultManager] fileExistsAtPath:logDbPath]) {
                        BOOL addOriginalLogDatabase = YES;
                        NSString *decryptedLogDbPath = [logDbPath stringByDeletingPathExtension];
                        decryptedLogDbPath = [decryptedLogDbPath stringByAppendingString:@"-plain.db"];
                        if ([dbKey length] > 0) {
                            BOOL ok = [QxPlatfromIOS decryptDatabase:logDbPath to:decryptedLogDbPath withKey:dbKey];
                            if (ok) {
                                addOriginalLogDatabase = NO;
                                [filePaths addObject:decryptedLogDbPath];
                                [tempFiles addObject:decryptedLogDbPath];
                            } else {
                                addKeyFile = YES;
                            }
                        }
                        
                        if (addOriginalLogDatabase) {
                            [filePaths addObject:logDbPath];
                            [filePaths addObject:[logDbPath stringByAppendingString:@"-shm"]];
                            [filePaths addObject:[logDbPath stringByAppendingString:@"-wal"]];
                        }
                    }
                }
                
                // Key is neeed when either database or log database decryption failed
                if (addKeyFile) {
                    NSString *tempDbKeyFileName = [NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"dbkey_%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"txt"]];
                    NSString *content = [NSString stringWithFormat:@"PRAGMA key = '%@'", dbKey];
                    [content writeToFile:tempDbKeyFileName atomically:NO encoding:NSStringEncodingConversionAllowLossy error:nil];
                    [filePaths addObject:tempDbKeyFileName];
                    [tempFiles addObject:tempDbKeyFileName];
                }
            }
        }
    
        if ([filesToZip count] > 0) {
            self.zipPath = [ReportIncidentService compressFilesToTempFile:filesToZip];
            
            for (NSString *file in tempFiles) {
                [[NSFileManager defaultManager] removeItemAtPath:file error:nil];
            }
        }
        
        // Clear the Crash Report too
        [appDelegate restoreAppCrashEventIfNeeded];
    
        [super callServiceWithCompletition:completitionBlock];
    });
}

- (void)handleResponseMessageData:(NSDictionary *)dataDict withCompletition:(CompletionBlock)completitionBlock{
    DDLogSupport(@"data: %@",dataDict);
    if ([zipPath length] > 0) {
        [[NSFileManager defaultManager] removeItemAtPath:zipPath error:nil];
        self.zipPath = nil;
    }
    NSString * incidentNumber = [dataDict objectForKey:@"incident_number"];
    if (completitionBlock) completitionBlock(CompletitionStatusSuccess, incidentNumber, nil);
   
}

@end
