//
//  User.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 11/30/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface User : NSObject{
	NSString *userName;
	NSString *role;
    NSString *name;
	NSString *specialty;
	BOOL useGroupName;
	NSString *groupName;
	NSString *facilityName;
	NSString *facilityNpi;
}
@property (nonatomic, retain) NSString *userName;
@property (nonatomic, retain) NSString *role;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *specialty;
@property (nonatomic, retain) NSString *groupName;
@property (nonatomic, readwrite) BOOL useGroupName;
@property (nonatomic, retain) NSString *facilityName;
@property (nonatomic, retain) NSString *facilityNpi;


//Static methods.
+ (User *) getUser:(NSString *)username;
+ (NSInteger) getRoleTypeId:(NSString *)role;

@end
