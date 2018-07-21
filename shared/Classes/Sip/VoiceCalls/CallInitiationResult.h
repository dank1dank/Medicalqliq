//
//  CallInitiationResult.h
//  qliq
//
//  Created by Paul Bar on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CallInitiationResult : NSObject

@property (nonatomic, assign) int call_id;
@property (nonatomic, retain) NSString *error;

@end
