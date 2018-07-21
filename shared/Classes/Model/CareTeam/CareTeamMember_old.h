//
//  CareTeamMember.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 12/4/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CareTeamMember_old : NSObject{
	NSString *memberId;
	NSString *memberType;
	NSString *prefix;
	NSString *name;
	NSString *suffix;
	NSString *initials;
	NSString *specialty;
	NSString *credentials;
	NSString *mobile;
	NSString *phone;
	NSString *fax;
	NSString *email;
	NSString *facilityName;
	NSString *groupName;
}
@property (nonatomic, retain) NSString *memberId;
@property (nonatomic, retain) NSString *memberType;
@property (nonatomic, retain) NSString *prefix;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *suffix;
@property (nonatomic, retain) NSString *initials;
@property (nonatomic, retain) NSString *specialty;
@property (nonatomic, retain) NSString *credentials;
@property (nonatomic, retain) NSString *mobile;
@property (nonatomic, retain) NSString *phone;
@property (nonatomic, retain) NSString *fax;
@property (nonatomic, retain) NSString *email;
@property (nonatomic, retain) NSString *facilityName;
@property (nonatomic, retain) NSString *groupName;

@end
