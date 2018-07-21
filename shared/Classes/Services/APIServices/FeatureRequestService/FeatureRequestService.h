//
//  FeatureRatingService.h
//  qliq
//
//  Created by Paul Bar on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ApiServiceBase.h"

@class FeatureRequest;

@protocol FeatureRequestServiceDelegate <NSObject>

-(void) featureRequestDidFailWithError:(NSString*)error;
-(void) featureRequestComplete;

@end

@interface FeatureRequestService : ApiServiceBase

@property (nonatomic, assign) id<FeatureRequestServiceDelegate> delegate;

-(void) requestFeature:(FeatureRequest*)request;

@end
