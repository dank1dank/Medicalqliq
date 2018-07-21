//
//  QliqWebToClientMessage.h
//  qliq
//
//  Created by Paul Bar on 1/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqSipMessage.h"

@interface QliqWebToClientMessage : QliqSipMessage

+(QliqWebToClientMessage*) qliqWebToClientMessageWithDictionary:(NSDictionary*)dict;

@end
