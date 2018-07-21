//
//  ReportIncidentService.h
//  qliq
//
//  Created by Aleksey Garbarev on 11/8/12.
//
//

#import "SendFeedbackService.h"

@interface ReportIncidentService : SendFeedbackService

- (id) initWithDefaultFilesAndDatabase:(BOOL)includeDatabase andLogDatabase:(BOOL)includeLogDatabase andMessage:(NSString *)message andSubject:(NSString *)subject isNotifyUser:(BOOL)notifyUser;

- (id) initWithMessage:(NSString *)message andSubject:(NSString *)subject andFilePaths:(NSArray *) filePaths isNotifyUser:(BOOL)notifyUser;

- (void)callServiceWithCompletition:(CompletionBlock)completitionBlock;

+ (NSString *) compressFilesToTempFile:(NSArray *) filePaths;
@end
