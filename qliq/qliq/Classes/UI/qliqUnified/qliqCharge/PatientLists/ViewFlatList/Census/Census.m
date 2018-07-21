//
//  Census.m
//  qliq
//
//  Created by Paul Bar on 3/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Census.h"

#import "Patient.h"
#import "PatientVisit.h"
#import "Encounter.h"
#import "Facility.h"
#import "NSObject+AutoDescription.h"
#import "QliqUser.h"

@implementation Census

@synthesize patient;
@synthesize facility;
@synthesize patientVisit;
@synthesize encounter;
@synthesize activeUser;
@synthesize admitUser;

-(void) dealloc
{
    [self.activeUser release];
    [self.admitUser release];
    [self.patient release];
    [self.facility release];
    [self.patientVisit release];
    [self.encounter release];
    [super dealloc];
}

-(NSString*) description
{
    return [self autoDescription];
}

@end
