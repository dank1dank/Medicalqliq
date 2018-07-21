//
//  FacilityService.h
//  qliq
//
//  Created by Paul Bar on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DBServiceBase.h"
#import "Facility.h"
#import "QliqUser.h"
@class Group;
@class Floor;

@interface FacilityService : DBServiceBase

-(BOOL) saveFacility:(Facility*)facility;
-(Facility*) getFacilityWithNpi:(NSNumber*)npi;
-(NSArray*) getFacilities;

-(BOOL) addUser:(QliqUser*)user toFacility:(Facility*)facility;
-(NSArray*) getFacilitiesOfUser:(QliqUser*)user;
-(NSArray*) getUsersOfFacility:(Facility*)facility;
-(BOOL) addGroup:(Group*)group toFacility:(Facility*)facility;
-(BOOL) addFloor:(Floor*)floor toFacility:(Facility*)facility;
-(Floor*) getFloor:(Floor *) name inFacility:(Facility*)facility;
-(NSArray*) getFloorsOfFacility:(Facility*)facility;

@end
