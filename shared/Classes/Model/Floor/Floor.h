//
//  Floor.h
//  qliq
//
//  Created by Paul Bar on 3/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMResultSet;

@interface Floor : NSObject

@property (nonatomic, retain) NSNumber *floorId;
@property (nonatomic, retain) NSNumber *facilityNpi;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSNumber *displayOrder;
@property (nonatomic, retain) NSString *floorDescription;

+(Floor*) floorWithResultSet:(FMResultSet*)rs;

@end
