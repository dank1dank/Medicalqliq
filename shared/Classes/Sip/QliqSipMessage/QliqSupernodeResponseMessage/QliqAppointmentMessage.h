//
//  QliqAppointmentMessage.h
//  qliq
//
//  Created by Paul Bar on 1/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqSupernodeResponseMessage.h"

@interface QliqAppointmentMessage : QliqSupernodeResponseMessage

@property (nonatomic, retain) NSDictionary *dataDict;

@end
