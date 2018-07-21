//
//  CensusFactoryProtocol.h
//  qliq
//
//  Created by Paul Bar on 3/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QliqUser;

@protocol CensusFactoryProtocol <NSObject>

-(NSArray*) getCensuesOfUser:(QliqUser*)user forDate:(NSDate*)date withCensusType:(NSString*)censusType;

@end
