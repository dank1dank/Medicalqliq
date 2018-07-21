//
//  Encounter.h
//  qliq
//
//  Created by Paul Bar on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMResultSet;

@interface Encounter : NSObject

@property (nonatomic, retain) NSNumber *encounterId;
@property (nonatomic, retain) NSNumber *patietnVisitId;
@property (nonatomic, retain) NSDate *dateOfService;
@property (nonatomic, retain) NSNumber *status;
@property (nonatomic, retain) NSString *data;

+(Encounter*) encounterWithResultSet:(FMResultSet*)result_set;


@end
