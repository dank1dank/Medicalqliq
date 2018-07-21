//
//  GetAllOnCallGroupsService.h
//  qliq
//
//  Created by Adam on 10/08/15.
//
//

#import <Foundation/Foundation.h>

typedef enum: NSInteger {
    ViewRequestReason,
    ChangeNotificationRequestReason
} OnCallGroupRequestReason;

@interface GetOnCallGroupService : NSObject

- (void) get:(NSString *)qliqId reason:(OnCallGroupRequestReason)reason withCompletionBlock:(CompletionBlock) completion;

@end
