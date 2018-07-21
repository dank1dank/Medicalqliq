//
//  SendFeedbackService.h
//  qliq
//
//  Created by Aleksey Garbarev on 11/8/12.
//
//

#import <Foundation/Foundation.h>
#import "QliqAPIService.h"

@interface SendFeedbackService : QliqAPIService

- (id) initWithMessage:(NSString *)_message andSubject:(NSString *)_subject notifyUser:(BOOL)notifyUser;


@end
