//
//  QliqPushChargesRequest.h
//  qliq
//
//  Created by Paul Bar on 1/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqAppToAppMessage.h"

@interface QliqPullChargesRequestMessage : QliqAppToAppMessage

@property (nonatomic, retain) NSDictionary *dataDict;

@end
