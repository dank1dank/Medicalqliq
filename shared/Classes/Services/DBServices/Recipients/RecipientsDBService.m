//
//  DBRecipientsService.m
//  qliq
//
//  Created by Aleksey Garbarev on 12/3/12.
//
//

#import "RecipientsDBService.h"
#import "QliqJsonSchemaHeader.h"
#import "QliqGroup.h"
#import "SipContactDBService.h"
#import "SipContact.h"
#import "QliqUserDBService.h"
#import "Multiparty.h"
#import "JSONKit.h"

@implementation RecipientsDBService

- (Recipients *) recipientsWithQliqId:(NSString *) qliqId{
    
    Recipients * recipients = nil;
    
    if (!qliqId){
        DDLogError(@"qliqId can't be nil while fetching recipients");
        return nil;
    }
    
    NSString * query = @"SELECT * FROM recipients WHERE recipients_qliq_id = ?;";
    NSArray * decoders = [self decodersFromSQLQuery:query withArgs:@[qliqId]];
    
    if (decoders.count > 0)
        recipients = [self objectOfClass:[Recipients class] fromDecoder:decoders[0]];
    
    return recipients;
}

- (BOOL) saveRecipientsFromMPResponseDict:(NSDictionary *) responseData{
    
    NSArray *participants = [responseData objectForKey:PARTICIPANTS];
    
    
    NSString * qliq_id = [responseData objectForKey:QLIQ_ID];
    Recipients * recipients = [self recipientsWithQliqId:qliq_id];
    
    if (!recipients){
        recipients = [[Recipients alloc] init];
    }else{
        
        /* Remove previous recipients to replace with new */
        [self deleteObject:recipients mode:DBModeToMany | DBModeToOne completion:^(NSError *error) {
            if (error)
                DDLogError(@"%@",[error localizedDescription]);
            else
                DDLogSupport(@"Removed");
        }];
        
        [recipients removeAllRecipients];
    }
    
    recipients.qliqId = qliq_id;
    recipients.name   = [responseData objectForKey:NAME];
    
    [participants enumerateObjectsUsingBlock:^(NSDictionary * partipant, NSUInteger idx, BOOL *stop) {
        
        NSString * recipient_id = [partipant objectForKey:@"qliq_id"];
        
        id<Recipient> recipient = [self objectWithId:recipient_id andClass:[QliqUser class]];
        if (!recipient) {
            recipient = [self objectWithId:recipient_id andClass:[QliqGroup class]];
            
            if (!recipient) {
                DDLogError(@"Can't find recipient for qliq_id: %@", recipient_id);
                
                // TODO:
                // This is a workaround for a bug with Recipients concept.
                // If we have MP with (yet) unknown contacts we need to save them in DB anyway
                QliqUser *fakeUser = [[QliqUser alloc] init];
                fakeUser.qliqId = recipient_id;
                fakeUser.firstName = @"unknown contact";
                [[QliqUserDBService sharedService] saveUser:fakeUser];
                recipient = fakeUser;
            }
        }
        
        if (recipient){
            [recipients addRecipient:recipient];
        }
    }];
    
    // Since Care Channels introduction we store ourself too as long as we are part of MP
    NSString *myQliqId = [UserSessionService currentUserSession].user.qliqId;
    id<Recipient> myRecipient = [self objectWithId:myQliqId andClass:[QliqUser class]];
    if (![recipients containsRecipient:myRecipient]) {
        [recipients addRecipient:myRecipient];
    }
    
    __block BOOL success = NO;
    
    [self save:recipients completion:^(BOOL wasInserted, id objectId, NSError *error) {
        success = (error == nil);
    }];
    
    if (success) {
        // Save multiparty also, in the future we want to get rid of recipients and use multiparty like on desktop and android
        Multiparty *mp = [Multiparty parseJson:[responseData JSONString]];
        if (mp) {
            [MultipartyDao insertOrUpdate:mp];
        }
    }
    
    return success;
}

- (void)removeSelfUserFromRecipients:(Recipients *)recipients {
    
    if (!recipients){
        DDLogError(@"ERROR: NIL recipients");
    }
    else
    {
        NSArray *participants = [recipients allRecipients];
        
        /* Remove previous recipients to replace with new */
        [self deleteObject:recipients mode:DBModeToMany | DBModeToOne completion:^(NSError *error) {
            if (error)
                DDLogError(@"%@",[error localizedDescription]);
            else
                DDLogSupport(@"Removed");
        }];
        
        [recipients removeAllRecipients];
        
        [participants enumerateObjectsUsingBlock:^(QliqUser* participant, NSUInteger idx, BOOL *stop) {
            if (![participant.qliqId isEqualToString:[UserSessionService currentUserSession].user.qliqId]){
                [recipients addRecipient:participant];
            }
        }];
        
        __block BOOL success = NO;
        
        [self save:recipients completion:^(BOOL wasInserted, id objectId, NSError *error) {
            success = (error == nil);
            
            if (error) {
                DDLogError(@"ERROR: %@", [error localizedDescription]);
            }
        }];
        
//        if (success) {
//            // Save multiparty also, in the future we want to get rid of recipients and use multiparty like on desktop and android
//            Multiparty *mp = [MultipartyDao selectOneWithQliqId:qliqId];
//            
            //TODO: Need to implement updating of Multiparty
//            if (mp) {
//                [MultipartyDao insertOrUpdate:mp];
//            }
//        }
    }
}

@end
