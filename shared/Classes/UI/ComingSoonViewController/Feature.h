//
//  Feature.h
//  qliq
//
//  Created by Paul Bar on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Feature : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *description;

+(Feature*) featureWithDict:(NSDictionary*)dict;
+(Feature*) getFromPlistFeatureNamed:(NSString*)featureName;

-(id) initWithName:(NSString*)name andDescription:(NSString*)description;
-(void) saveAsRequested;
-(BOOL) isRequested;

@end
