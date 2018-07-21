//
//  DBRecipientsService.h
//  qliq
//
//  Created by Aleksey Garbarev on 12/3/12.
//
//

#import <Foundation/Foundation.h>
#import "QliqDBService.h"
#import "Recipients.h"
#import "QliqSipExtendedChatMessage.h"

@interface RecipientsDBService : QliqDBService

- (Recipients *)recipientsWithQliqId:(NSString *)qliqId;

- (BOOL)saveRecipientsFromMPResponseDict:(NSDictionary *)responseData;
- (void)removeSelfUserFromRecipients:(Recipients *)recipients;
@end
