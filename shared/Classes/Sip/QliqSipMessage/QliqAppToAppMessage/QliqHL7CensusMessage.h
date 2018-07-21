//
//  QliqHL7CensusMessage.h
//  qliq
//
//  Created by Paul Bar on 1/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqAppToAppMessage.h"

@interface QliqHL7CensusMessage : QliqAppToAppMessage

@property (nonatomic, retain) NSArray *censuses;

@end
