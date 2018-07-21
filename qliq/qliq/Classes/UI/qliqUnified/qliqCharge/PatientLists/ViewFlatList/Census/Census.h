//
//  Census.h
//  qliq
//
//  Created by Paul Bar on 3/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Facility;
@class PatientVisit;
@class Encounter;
@class Patient;
@class QliqUser;

@interface Census : NSObject

@property (nonatomic, retain) QliqUser *admitUser;
@property (nonatomic, retain) QliqUser *activeUser;
@property (nonatomic, retain) Patient* patient;
@property (nonatomic, retain) Facility* facility;
@property (nonatomic, retain) PatientVisit* patientVisit;
@property (nonatomic, retain) Encounter *encounter;

@end
