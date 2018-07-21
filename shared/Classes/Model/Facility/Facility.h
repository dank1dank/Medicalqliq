//
//  Facility.h
//  qliq
//
//  Created by Paul Bar on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMResultSet;

@interface Facility : NSObject

+(Facility*)facilityWithResultSet:(FMResultSet*)resultSet;

@property (nonatomic, retain) NSNumber *npi;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSString *country;
@property (nonatomic, retain) NSString *state;
@property (nonatomic, retain) NSString *city;
@property (nonatomic, retain) NSString *zip;
@property (nonatomic, retain) NSString *address;
@property (nonatomic, retain) NSString *phone;

@end
