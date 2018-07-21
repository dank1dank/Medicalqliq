//
//  Patient.h
//  qliq
//
//  Created by Paul Bar on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMResultSet;

@interface Patient : NSObject

@property (nonatomic, retain) NSString *guid;
@property (nonatomic, retain) NSString *firstName;
@property (nonatomic, retain) NSString *middleName;
@property (nonatomic, retain) NSString *lastName;
@property (nonatomic, retain) NSDate *dateOfBirth;
@property (nonatomic, retain) NSString *race;
@property (nonatomic, retain) NSString *gender;
@property (nonatomic, retain) NSString *phone;
@property (nonatomic, retain) NSString *email;
@property (nonatomic, retain) NSString *insurance;


+(Patient*) patientWithResultSet:(FMResultSet*)resultSet;

@end
