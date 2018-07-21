//
//  Presence.m
//  qliq
//
//  Created by Aleksey Garbarev on 16.11.12.
//
//

#import "Presence.h"
#import "QliqUserDBService.h"
#import "UserSession.h"

@implementation Presence

@synthesize forwardingUser, message, presenceType, allowEditMessage;

- (id) initWithType:(NSString *) _presenceType{
    self = [super init];
    if (self) {
        self.presenceType = _presenceType;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if (self) {
        
        self.forwardingUser =  [aDecoder decodeObjectForKey:@"forwardingUser"];
        self.message  = [aDecoder decodeObjectForKey:@"message"];
        if ([aDecoder containsValueForKey:@"presenceType"])
            self.presenceType =[aDecoder decodeObjectForKey:@"presenceType"];
        if ([aDecoder containsValueForKey:@"allowEditMessage"])
            self.allowEditMessage = [aDecoder decodeBoolForKey:@"allowEditMessage"];
    }
    return self;
    
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.presenceType forKey:@"presenceType"];
    [aCoder encodeObject:self.message forKey:@"message"];
    [aCoder encodeObject:self.forwardingUser forKey:@"forwardingUser"];
    [aCoder encodeBool:self.allowEditMessage forKey:@"allowEditMessage"];
}

- (id)copyWithZone:(NSZone *)zone{
    Presence * copied = [[Presence alloc] init];
    copied.forwardingUser = self.forwardingUser;
    copied.message = [self.message mutableCopy]; /* Strange but with simple 'copy' result have same address pointer */
    copied.presenceType = [self.presenceType mutableCopy];
    copied.allowEditMessage = self.allowEditMessage;
    
    return copied;
}

- (BOOL)isEqual:(id)object{
    
    if ([object isKindOfClass:[Presence class]]){
        BOOL isEqual = YES;
        Presence * anotherPresence = (Presence *) object;
        isEqual &= (!self.forwardingUser && !anotherPresence.forwardingUser) || [anotherPresence.forwardingUser isEqual:self.forwardingUser];
        isEqual &= (!self.message && !anotherPresence.message) || [anotherPresence.message isEqual:self.message];
        isEqual &= [anotherPresence.presenceType isEqual:self.presenceType];
        isEqual &= self.allowEditMessage == anotherPresence.allowEditMessage;
        
        return isEqual;
    }else{
        return [super isEqual:object];
    }
    
}
- (void) setShouldAsk:(BOOL)asked{
    //update 'shoulAsk' for forvarding messages
    //Valerii Lider 30/10/17
    
    s_shouldAsk = asked;
}

+ (BOOL)shouldAskForwardingIfNeededForRecipient:(id<Recipient>)recipient {
    BOOL shouldAsk = NO;
    
    if (![recipient isKindOfClass:[QliqUser class]])
        return NO;
    
    QliqUser *user = [[QliqUserDBService sharedService] getUserWithId:recipient.recipientQliqId];
    QliqUser *forward = [[QliqUserDBService sharedService] getUserWithId:user.forwardingQliqId];
    
    if (user.presenceStatus == AwayPresenceStatus && forward &&
        ![forward.qliqId isEqualToString:[UserSessionService currentUserSession].user.qliqId] && s_shouldAsk) {
        shouldAsk = YES;
    }
    
    return shouldAsk;
}

+ (void) askForwardingIfNeededForRecipient:(id<Recipient>) recipient completeBlock:(void(^)(id<Recipient> selectedRecipient))completeBlock {
    
    QliqUser *user = [[QliqUserDBService sharedService] getUserWithId:recipient.recipientQliqId];
    QliqUser *forward = [[QliqUserDBService sharedService] getUserWithId:user.forwardingQliqId];
    
    if ([self shouldAskForwardingIfNeededForRecipient:recipient])
    {
        NSString * alertText = [NSString stringWithFormat:NSLocalizedString(@"1154-TextThe{Recipient title} has set message forwarding to {Recipient title}, would you like to send a message to {Recipient title}?", nil), [recipient recipientTitle], [forward recipientTitle],[forward recipientTitle]];
        
        UIAlertView_Blocks * alertView = [[UIAlertView_Blocks alloc] initWithTitle:nil
                                                                           message:alertText
                                                                          delegate:nil
                                                                 cancelButtonTitle:NSLocalizedString(@"2-ButtonNO", nil)
                                                                 otherButtonTitles:NSLocalizedString(@"3-ButtonYES", nil), nil];
        [alertView showWithDissmissBlock:^(NSInteger buttonIndex) {
            if (buttonIndex != alertView.cancelButtonIndex){
                if (completeBlock) completeBlock(forward);
                
            }else{
                if (completeBlock) completeBlock(recipient);
            }
        }];
        alertView = nil;
    }else{
        if (completeBlock) completeBlock(recipient);
    }
}

@end
