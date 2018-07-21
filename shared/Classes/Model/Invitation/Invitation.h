//
//  Invitation.h
//  qliq
//
//  Created by Ravi Ada on 06/05/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Contact.h"
@class FMResultSet;

typedef enum : NSInteger {
    InvitationOperationSent = 0,
    InvitationOperationReceived
} InvitationOperation;

typedef enum : NSInteger {
    InvitationStatusNew,
    InvitationStatusRead,
    InvitationStatusAccepted,
    InvitationStatusDeclined
} InvitationStatus;

@interface Invitation : NSObject

@property (nonatomic, retain) NSString *uuid;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, strong) Contact * contact;
@property (nonatomic, readwrite) NSTimeInterval invitedAt;
@property (nonatomic) InvitationStatus status;
@property (nonatomic) InvitationOperation operation;

+(Invitation*) invitationWithResultSet:(FMResultSet*)resultSet;

@end
