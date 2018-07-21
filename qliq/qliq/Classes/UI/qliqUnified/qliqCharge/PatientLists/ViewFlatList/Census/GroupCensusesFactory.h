//
//  GroupCensusesFactory.h
//  qliq
//
//  Created by Paul Bar on 3/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CensusFactoryProtocol.h"

@class Group;

@interface GroupCensusesFactory : NSObject <CensusFactoryProtocol>

@property (nonatomic, retain) Group *group;

@end
