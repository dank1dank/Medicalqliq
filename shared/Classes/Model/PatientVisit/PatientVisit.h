//
//  Observation.h
//  qliq
//
//  Created by Paul Bar on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMResultSet;

@interface PatientVisit : NSObject

@property (nonatomic, retain) NSNumber *visitId;
@property (nonatomic, retain) NSNumber *careteamId;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSString *patientGuid;
@property (nonatomic, retain) NSNumber *facilityNpi;
@property (nonatomic, retain) NSNumber *consult;
@property (nonatomic, retain) NSString *mrn;
@property (nonatomic, retain) NSNumber *floorId;
@property (nonatomic, retain) NSString *room;
@property (nonatomic, retain) NSDate *admitDate;
@property (nonatomic, retain) NSDate *dischargeDate;
@property (nonatomic, retain) NSDate *apptStartDate;
@property (nonatomic, retain) NSNumber *duration;
@property (nonatomic, retain) NSNumber *reminder;
@property (nonatomic, retain) NSString *reason;
@property (nonatomic, assign) BOOL active;
@property (nonatomic, retain) NSString *uuid;
@property (nonatomic, retain) NSString *rev;
@property (nonatomic, retain) NSString *autor;
@property (nonatomic, retain) NSNumber *seq;
@property (nonatomic, assign) BOOL isRevDirty;

+(PatientVisit*) patientVisitWithResultSet:(FMResultSet*)resultSet;

@end
