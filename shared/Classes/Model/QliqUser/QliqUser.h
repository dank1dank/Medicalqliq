//
//  QliqUser.h
//  qliq
//
//
//  Created by Ravi Ada on 06/05/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Contact.h"
#import "FMDatabase.h"
#import "Recipient.h"
#import "DBCoder.h"
#import "SipContact.h"

typedef enum : NSInteger {
    OfflinePresenceStatus       = 0,
    OnlinePresenceStatus        = 1,
    AwayPresenceStatus          = 2,
    DoNotDisturbPresenceStatus  = 3,
    PagerOnlyPresenceStatus     = 4
} PresenceStatus;


extern NSString * QliqUserStateInvitationPending;
//extern NSString * QliqUserStateActivationPending;
//extern NSString * QliqUserStateLocked;
extern NSString * QliqUserStateActive;
extern NSString * QliqUserStateInactive;
extern NSString * QliqUserStateQliqStor;

@interface QliqUser : NSObject <Recipient, DBCoding>

@property (nonatomic, strong) NSString *profession;
@property (nonatomic, strong) NSString *credentials;
@property (nonatomic, strong) NSString *npi;
@property (nonatomic, strong) NSString *taxonomyCode;
@property (nonatomic, strong) NSString *specialty;
@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSString *presenceMessage;
@property (nonatomic, strong) NSString *forwardingQliqId;
@property (nonatomic, strong) NSString *organization;
@property (nonatomic, strong) Contact *contact;
@property (nonatomic) PresenceStatus presenceStatus;
@property (nonatomic, assign) BOOL     isPagerUser;
@property (nonatomic ,strong) NSString *pagerInfo;
/**
 Contact Property
 */
@property (nonatomic) NSInteger contactId;
@property (nonatomic, strong) NSString *qliqId;
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSString *groupName;
@property (nonatomic, strong) NSString *listName;
@property (nonatomic, strong) NSString *middleName;
@property (nonatomic, strong) NSString *mobile;
@property (nonatomic, strong) NSString *phone;
@property (nonatomic, strong) NSString *fax;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *state;
@property (nonatomic, strong) NSString *zip;
@property (nonatomic, strong) NSString *avatarFilePath;
@property (nonatomic, strong) UIImage *avatar;
@property (nonatomic) ContactType contactType;
@property (nonatomic) ContactStatus contactStatus;



+ (QliqUser *) userFromDict:(NSDictionary *)dict;

+ (PresenceStatus) presenceStatusFromString:(NSString *)status;
+ (NSString *) presenceStatusToString:(PresenceStatus) status;

- (NSString *) displayName;
- (NSMutableDictionary *) toDict;

- (BOOL)isActive;

- (BOOL)isEqualToQliqUser:(QliqUser *)other;
- (BOOL)isEqual:(id)object;
- (NSUInteger)hash;

- (void)mergeWith:(QliqUser *)contact;

// SipContact protocol
- (NSString *) privateKey;
- (SipContactType) sipContactType;

- (NSString *) searchDescription;

// Contact class properties exposed here to make code which was written
// when QliqUser was extending Contact still work without modifications
- (NSString *) nameDescription;
- (NSString *) simpleName;
- (NSComparisonResult) firstNameAck:(Contact *)contact;
- (NSComparisonResult) lastNameAck:(Contact *)contact;

@end
