//
//  ChatEventHelper.h
//  qliq
//
//  Created by Adam Sowa on 12/26/12.
//
//

#import <Foundation/Foundation.h>

@class Recipients;

@interface ChatEventHelper : NSObject

+ (NSString *) eventToString:(NSString *)jsonStr;
+ (NSString *) formatParticipantsChangedEvent:(NSArray *)added :(NSArray *)removed UNAVAILABLE_ATTRIBUTE;

+ (NSString *) participantsChangedEventFromRecipients:(Recipients *)oldRecipients  toRecipients:(Recipients *) newRecipients;

+ (NSDictionary *) eventDictFromString:(NSString *) jsonString;
@end
