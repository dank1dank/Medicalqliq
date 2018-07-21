//
//  CallStateChangeInfo.h
//  qliq
//
//  Created by Paul Bar on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CallStateChangeInfo : NSObject

@property(nonatomic, retain) NSNumber *lastReasonCode;
@property(nonatomic, retain) NSNumber *call_id;
@property(nonatomic, retain) NSNumber *state;

@end
