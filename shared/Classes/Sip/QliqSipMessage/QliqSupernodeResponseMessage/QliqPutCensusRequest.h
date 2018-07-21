//
//  QliqPutCensusRequest.h
//  qliq
//
//  Created by Paul Bar on 1/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqSupernodeResponseMessage.h"

@interface QliqPutCensusRequest : QliqSupernodeResponseMessage

@property (nonatomic, retain) NSDictionary *dataDict;

@end
