//
//  CareTeamMember.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 12/4/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "CareTeamMember_old.h"

@implementation CareTeamMember_old
@synthesize memberId,memberType,prefix,name,suffix,initials,specialty,credentials,mobile,phone,fax,email,groupName,facilityName;

- (void) dealloc {
	[memberId release];
	[memberType release];
	[groupName release];
	[facilityName release];
	[prefix release];
 	[name release];
	[suffix release];
    [initials release];
    [specialty release];
    [credentials release];
    [mobile release];
    [phone release];
    [fax release];
    [email release];
	
	[super dealloc];
}

@end
