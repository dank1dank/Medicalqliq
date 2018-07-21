//
//  FacilityCensusesFactory.h
//  qliq
//
//  Created by Paul Bar on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CensusFactoryProtocol.h"

@class Facility;

@interface FacilityCensusesFactory : NSObject<CensusFactoryProtocol>

@property (nonatomic, retain) Facility* facility;

@end
