//
//  ContactBase.h
//  qliqConnect
//
//  Created by Paul Bar on 12/6/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DBCoder.h"

typedef enum : NSInteger {
    ContactTypeUnknown = -1,
    ContactTypeQliqUser = 0,
    ContactTypeReferringProvider = 1,
    ContactTypeIPhoneContact = 99,
    ContactTypeQliqDuplicate = -99
} ContactType;

// All database enums should be initialized otherwise we are at compiler mercy
typedef enum : NSInteger {
    ContactStatusDefault = 0,
    ContactStatusInvited = 1,
    ContactStatusNew     = 2,
    ContactStatusInvitationInProcess = 3,
    ContactStatusDeleted = 4
} ContactStatus;

@interface Contact : NSObject <NSCoding, DBCoding>

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
@property (nonatomic, strong) UIImage *avatar;
@property (nonatomic, strong) NSString *avatarFilePath;
@property (nonatomic) ContactType contactType;
@property (nonatomic) ContactStatus contactStatus;

- (NSString *) searchDescription;

- (NSString *) nameDescription;
- (NSString *) simpleName;
- (NSString *) displayName;

//sorting
-(NSComparisonResult) firstNameAck:(Contact *)contact;
-(NSComparisonResult) lastNameAck:(Contact *)contact;


// Exposed DBCoder internals for QliqUser class
- (id)initContactWithDBCoder:(DBCoder *)decoder;

@end




