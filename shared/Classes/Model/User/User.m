//
//  User.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 11/30/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "User.h"
#import "DBHelperNurse.h"

@implementation User

@synthesize userName,role,name,specialty,groupName,useGroupName,facilityName,facilityNpi;

+ (User *) getUser:(NSString *)username
{
    return [DBHelperNurse getUser:username];
}
+ (NSInteger) getRoleTypeId:(NSString *)role
{
    return [DBHelperNurse getRoleTypeId:role];
	
}

- (void) dealloc {
 	[userName release];
 	[role release];
 	[name release];
 	[specialty release];
 	[groupName release];
 	[facilityName release];

	[super dealloc];
}

@end

