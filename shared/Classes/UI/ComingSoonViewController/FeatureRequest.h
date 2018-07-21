//
//  FeatiureRate.h
//  qliq
//
//  Created by Paul Bar on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Feature;

@interface FeatureRequest : NSObject

@property(nonatomic, readonly) Feature* feature;
@property(nonatomic, readonly) NSString* requestType; 

-(id) initWithFeature:(Feature*)feature andRequestType:(NSString*)rate;

@end
