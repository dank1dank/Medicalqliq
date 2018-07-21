//
//  Patient.m
//  qliq
//
//  Created by Paul Bar on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Patient.h"
#import "FMResultSet.h"
#import "NSObject+AutoDescription.h"

@implementation Patient

@synthesize guid;
@synthesize firstName;
@synthesize middleName;
@synthesize lastName;
@synthesize dateOfBirth;
@synthesize race;
@synthesize gender;
@synthesize phone;
@synthesize email;
@synthesize insurance;


-(void) dealloc
{
    [self.guid release];
    [self.firstName release];
    [self.middleName release];
    [self.lastName release];
    [self.dateOfBirth release];
    [self.race release];
    [self.gender release];
    [self.phone release];
    [self.email release];
    [self.insurance release];
    [super dealloc];
}

+(Patient*) patientWithResultSet:(FMResultSet *)resultSet
{
    Patient *patient = [[Patient alloc] init];
    
    patient.guid = [resultSet stringForColumn:@"guid"];
    patient.firstName = [resultSet stringForColumn:@"first_name"];
    patient.middleName = [resultSet stringForColumn:@"middle_name"];
    patient.lastName = [resultSet stringForColumn:@"last_name"];
    patient.dateOfBirth = [resultSet dateForColumn:@"date_of_birth"];;
    patient.race = [resultSet stringForColumn:@"race"];
    patient.gender = [resultSet stringForColumn:@"gender"];
    patient.phone = [resultSet stringForColumn:@"phone"];
    patient.email = [resultSet stringForColumn:@"email"];
    patient.insurance = [resultSet stringForColumn:@"insurance"];

    return [patient autorelease];
}

-(NSString*) description
{
    return [self autoDescription];
}

@end
