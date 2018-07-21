//
//  QliqAppToAppMessage.h
//  qliq
//
//  Created by Paul Bar on 1/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqSipMessage.h"

@interface QliqAppToAppMessage : QliqSipMessage

+(QliqAppToAppMessage*)qliqAppToAppMessageWithDictionary:(NSDictionary*)dict;

@end
