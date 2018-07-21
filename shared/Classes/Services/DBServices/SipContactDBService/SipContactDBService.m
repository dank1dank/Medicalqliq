//
//  SipContactDBService.m
//  qliq
//
//  Created by Adam Sowa on 12/7/12.
//
//

#import "UserSessionService.h"
#import "SipContactDBService.h"
#import "SipContact.h"

#import "QliqJsonSchemaHeader.h"
#import "Crypto.h"

#import "NSString+Base64.h"

NSString *DEFAULT_GROUP_KEY_PASSWORD = @"groupchat";

@implementation SipContactDBService

+ (SipContactDBService *)sharedService {
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[SipContactDBService alloc] init];
    });
    
    return shared;
}

#pragma mark - Public


- (SipContact *)sipContactForQliqId:(NSString *)qliqId {
    return [self objectWithId:qliqId andClass:[SipContact class]];
}

- (SipContact *) sipContactForSipUri:(NSString *) sipUri{
    
    NSString * queue = @"SELECT * FROM sip_contact WHERE sip_uri = ? LIMIT 1";
    NSArray * decoders = [self decodersFromSQLQuery:queue withArgs:@[sipUri]];
    
    SipContact * result = nil;
    
    if (decoders.count > 0){
        result = [self objectOfClass:[SipContact class] fromDecoder:decoders[0]];
    }
    
    return result;
}

- (BOOL) saveSipContactFromMPResponseDict:(NSDictionary *) responseData{
    
    __block BOOL success = NO;
    
    NSString * encryptedPrivateKey = [responseData objectForKey:PRIVATE_KEY];
    NSString * clearTextPassword = [[UserSessionService currentUserSession].sipAccountSettings.password base64DecodedString];
    
    SipContact * mpSipContact = [[SipContact alloc] init];
    mpSipContact.qliqId = [responseData objectForKey:QLIQ_ID];
    mpSipContact.publicKey = [responseData objectForKey:PUBLIC_KEY];
    mpSipContact.sipUri = [responseData objectForKey:SIP_URI];
    mpSipContact.privateKey = [Crypto privateKeyRepassword:encryptedPrivateKey oldPassword:clearTextPassword newPassword:DEFAULT_GROUP_KEY_PASSWORD];
    mpSipContact.sipContactType = SipContactTypeMultiPartyChat;
        
    [self save:mpSipContact completion:^(BOOL wasInserted, id objectId, NSError *error) {
        success = (error == nil);
        if (!success)
            DDLogError(@"Error saving contact: %@",[error localizedDescription]);
    }];
    
    return success;
}

- (BOOL) saveGroupKeyPairForQliqId:(NSString *)qliqId privateKey:(NSString *)aPrivateKey publicKey:(NSString *)aPublicKey
{
    __block BOOL success = NO;
    SipContact *sipContact = [self sipContactForQliqId:qliqId];
    if (sipContact) {
        sipContact.publicKey = aPublicKey;
        sipContact.privateKey = aPrivateKey;
//        sipContact.privateKey = [Crypto privateKeyRepassword:aPrivateKey oldPassword:base64Password newPassword:DEFAULT_GROUP_KEY_PASSWORD];
        sipContact.sipContactType = SipContactTypeGroup;
        
        [self save:sipContact completion:^(BOOL wasInserted, id objectId, NSError *error) {
            success = (error == nil);
            if (!success)
                DDLogError(@"Error saving contact: %@",[error localizedDescription]);
        }];
    } else {
        DDLogError(@"Cannot load existing sip contact for group: %@", qliqId);
    }
    return success;
}

@end
