//
//  QliqGroup.h
//  qliq
//
//  Created by Ravi Ada on 06/05/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Recipient.h"
#import "ContactGroup.h"
#import "SipContact.h"
#import "DBCoder.h"

@class FMResultSet;

@interface QliqGroup : NSObject <ContactGroup, NSCoding, Recipient, DBCoding>

@property (nonatomic, strong) NSString *qliqId;
@property (nonatomic, strong) NSString *parentQliqId;
@property (nonatomic, strong) NSString *contactId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *acronym;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *state;
@property (nonatomic, strong) NSString *zip;
@property (nonatomic, strong) NSString *phone;
@property (nonatomic, strong) NSString *fax;
@property (nonatomic, strong) NSString *npi;
@property (nonatomic, strong) NSString *taxonomyCode;
@property (nonatomic, strong) NSString *accessType;
@property (nonatomic, assign) BOOL openMembership;
@property (nonatomic, assign) BOOL belongs;
@property (nonatomic, assign) BOOL canMessage;
@property (nonatomic, assign) BOOL canBroadcast;
@property (nonatomic, assign) BOOL locked;
@property (nonatomic, assign) BOOL isDeleted;

- (SipContactType)sipContactType;

+ (QliqGroup *)groupWithResultSet:(FMResultSet *)resultSet;

- (BOOL)hasPagerUsers;
- (NSUInteger)countOfParticipants;

@end
