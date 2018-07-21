//
//  SendMessageToNonQliqUserService.h
//  qliq
//
//  Created by Adam Sowa on 31/12/15.
//
//

#import <Foundation/Foundation.h>
#import "QliqAPIService.h"

@interface ModifyConversationStatusService : QliqAPIService

- (id)initWithConversationUuid:(NSString *)conversationUuid withMuted:(BOOL)muted;

@end
