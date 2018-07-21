//
//  CensusesFactory.h
//  qliq
//
//  Created by Paul Bar on 3/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CensusFactoryProtocol.h"

@class QliqUser;
@class CareteamService;
@class PatientVisitService;
@class EncounterService;

@interface PlainListCensusesFactory : NSObject<CensusFactoryProtocol>

@property (nonatomic, retain) CareteamService* careteamService;
@property (nonatomic, retain) PatientVisitService *patientVisitService;
@property (nonatomic, retain) EncounterService *encounterService;

@end
