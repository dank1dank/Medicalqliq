//
//  UpdateEscalatedCallnotifyInfoService.h
//  qliq
//
//  Created by Valeriy Lider on 7/15/14.
//
//

#import <Foundation/Foundation.h>

@interface UpdateEscalatedCallnotifyInfoService : NSObject

+ (UpdateEscalatedCallnotifyInfoService *) sharedService;

- (void)updateEscalatedCallnotifyInfoEscalationNumber:(NSString*)escalationNumber
                                     escalateWeekends:(BOOL)escalateWeekends
                                   escalateWeeknights:(BOOL)escalateWeeknights
                                     escalateWeekdays:(BOOL)escalateWeekdays
                                withCompletitionBlock:(CompletionBlock) completition;
@end
