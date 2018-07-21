//
//  ContactsDBObjects.m
//  qliqConnect
//
//  Created by Paul Bar on 12/7/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import "ContactsDBObjects.h"
//#import "ReferringPhysician.h"
#import "DBUtil.h"
#import "QliqUser.h"
#import "QliqUserDBService.h"
#import "UserSession.h"
#import "UserSessionService.h"

#import "SipContactDBService.h"
#import "SipContact.h"

@interface ContactDBObject()

-(id) initWithResultSet:(FMResultSet*)resultSet;

@end

@implementation ContactDBObject

-(id) initWithResultSet:(FMResultSet *)resultSet
{
    return [super init];
}

-(void) dealloc
{
    [super dealloc];
}

@end
