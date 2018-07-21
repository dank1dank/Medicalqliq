//
//  SipContactDBService.h
//  qliq
//
//  Created by Adam on 12/7/12.
//
//

#import "QliqDBService.h"

@class SipContact;

extern NSString *DEFAULT_GROUP_KEY_PASSWORD;

@interface SipContactDBService : QliqDBService

+ (SipContactDBService *)sharedService;

- (SipContact *)sipContactForQliqId:(NSString *)qliqId;
- (SipContact *)sipContactForSipUri:(NSString *)sipUri;

- (BOOL)saveSipContactFromMPResponseDict:(NSDictionary *)dictionary;
- (BOOL)saveGroupKeyPairForQliqId:(NSString *)qliqId privateKey:(NSString *)aPrivateKey publicKey:(NSString *)aPublicKey;

@end
