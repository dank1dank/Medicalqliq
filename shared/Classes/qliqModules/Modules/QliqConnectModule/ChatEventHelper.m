//
//  ChatEventHelper.m
//  qliq
//
//  Created by Adam Sowa on 12/26/12.
//
//

#import "ChatEventHelper.h"
#import "JSONKit.h"
#import "ChatEventMessageSchema.h"
#import "UserSessionService.h"
#import "QliqUserDBService.h"
#import "Recipients.h"

static NSString *PARTICIPANTS_CHANGED_EVENT = @"participants-changed";

@interface ChatEventHelper ()
+ (NSString *) participantsChangedEventToString:(NSDictionary *)event;
+ (NSString *) qliqIdArrayToNameString:(NSArray *)array;
+ (NSString *) displayName:(QliqUser *)user;

@end

@implementation ChatEventHelper

+ (NSString *) eventToString:(NSString *)jsonString
{
    NSError *error = nil;
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
    NSMutableDictionary *event = [jsonKitDecoder objectWithData:jsonData error:&error];
    NSString *eventType = [event objectForKey:CHAT_EVENT_MESSAGE_EVENT_TYPE];

    NSString *ret = nil;
    if ([PARTICIPANTS_CHANGED_EVENT isEqualToString:eventType]) {
        ret = [self participantsChangedEventToString:event];
    }
    return ret;
}

+ (NSString *) participantsChangedEventToString:(NSDictionary *)event
{
    NSMutableString *ret = [NSMutableString string];
    NSString *originatorQliqId = [event objectForKey:CHAT_EVENT_MESSAGE_ORIGINATOR_QLIQ_ID];
    QliqUser *me = [UserSessionService currentUserSession].user;
    if ([me.qliqId isEqualToString:originatorQliqId]) {
        [ret appendString:@"You"];
    } else {
        QliqUser *u = [[QliqUserDBService sharedService] getUserWithId:originatorQliqId];
        if (u != nil) {
            [ret appendString:[self displayName:u]];
        } else {
            [ret appendFormat:@"Unknown (%@)", originatorQliqId];
        }
    }
    
    NSArray *addedArray = [event objectForKey:CHAT_EVENT_MESSAGE_ADDED];
    NSArray *removedArray = [event objectForKey:CHAT_EVENT_MESSAGE_REMOVED];
    if ([addedArray count] > 0) {
        [ret appendString:@" added "];
        [ret appendString:[self qliqIdArrayToNameString:addedArray]];
        if ([removedArray count] == 0) {
            [ret appendString:@" to the conversation."];
        }
    }

    if ([removedArray count] > 0) {
        if ([addedArray count] > 0) {
            [ret appendString:@" and"];
        }
        [ret appendString:@" removed "];
        [ret appendString:[self qliqIdArrayToNameString:removedArray]];
        [ret appendString:@" from the conversation."];
    }
    return ret;
}

+ (NSString *) qliqIdArrayToNameString:(NSArray *)array
{
    NSMutableString *ret = [NSMutableString string];
//    QliqUser *me = [UserSessionService currentUserSession].user;    
    int i = 0;
    for (NSString *qliqId in array) {
        if (i > 0) {
            [ret appendString:@", "];
        }

        //Removed 'you' text for task #2600 04/14/17
//        if ([me.qliqId isEqualToString:qliqId]) {
//            [ret appendString:@"you"];
//        } else {
            QliqUser *u = [[QliqUserDBService sharedService] getUserWithId:qliqId];
            if (u != nil) {
                [ret appendString:[self displayName:u]];
            } else {
                [ret appendFormat:@"Unknown (%@)", qliqId];
            }
        }        
        ++i;
//    }
    return ret;
}

+ (NSString *) displayName:(QliqUser *)user
{
    NSMutableString *ret = [NSMutableString string];
    [ret appendString:user.lastName ? user.lastName : @""];
    [ret appendString:@", "];
    [ret appendString:user.firstName ? user.firstName : @""];
    return ret;
}


+ (NSString *) participantsChangedEventFromRecipients:(Recipients *)oldRecipients  toRecipients:(Recipients *) newRecipients{

    // Determine added and removed participants for chat event (marker)
    NSMutableArray *addedParticipants = [NSMutableArray array];
    NSMutableArray *removedParticipants = [NSMutableArray array];
    for (id <Recipient> existingRecipient in [oldRecipients allRecipients]) {
        if (![newRecipients containsRecipient:existingRecipient]) {
            [removedParticipants addObject:existingRecipient.recipientQliqId];
        }
    }
    for (id <Recipient> newRecipient in [newRecipients allRecipients]) {
        if (![oldRecipients containsRecipient:newRecipient]) {
            [addedParticipants addObject:newRecipient.recipientQliqId];
        }
    }
    
    QliqUser *me = [UserSessionService currentUserSession].user;
    
    NSMutableDictionary * eventDict = [[NSMutableDictionary alloc] init];
    
    eventDict[CHAT_EVENT_MESSAGE_EVENT_TYPE] = PARTICIPANTS_CHANGED_EVENT;
    eventDict[CHAT_EVENT_MESSAGE_ORIGINATOR_QLIQ_ID] = me.qliqId;
    eventDict[CHAT_EVENT_MESSAGE_RECIPIENT_QLIQ_ID_BEFORE] = [oldRecipients isMultiparty] ? oldRecipients.qliqId : me.qliqId;
    eventDict[CHAT_EVENT_MESSAGE_RECIPIENT_QLIQ_ID_AFTER] = [newRecipients isMultiparty] ? newRecipients.qliqId : me.qliqId;
    
    if ([addedParticipants count] > 0)
        eventDict[CHAT_EVENT_MESSAGE_ADDED] = addedParticipants;

    if ([removedParticipants count] > 0)
        eventDict[CHAT_EVENT_MESSAGE_REMOVED] = removedParticipants;
    
    return [eventDict JSONString];
    
}


+ (NSDictionary *) eventDictFromString:(NSString *) jsonString{
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
    NSMutableDictionary *event = [jsonKitDecoder objectWithData:jsonData error:nil];
    
    return event;    
}



@end
