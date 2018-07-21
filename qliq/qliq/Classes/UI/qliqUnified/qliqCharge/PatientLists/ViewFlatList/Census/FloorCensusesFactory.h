//
//  FloorCensusesFactory.h
//  qliq
//
//  Created by Paul Bar on 3/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CensusFactoryProtocol.h"

@class Floor;
@class QliqUser;
@class CareteamService;
@class PatientVisitService;
@class EncounterService;

@interface FloorCensusesFactory : NSObject <CensusFactoryProtocol>

@property(nonatomic, retain) Floor *floor;
@property (nonatomic, retain) CareteamService* careteamService;
@property (nonatomic, retain) PatientVisitService *patientVisitService;
@property (nonatomic, retain) EncounterService *encounterService;

@end
