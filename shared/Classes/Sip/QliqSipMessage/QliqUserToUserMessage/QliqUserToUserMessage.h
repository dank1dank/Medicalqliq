//
//  QliqUserToUserMessage.h
//  qliq
//
//  Created by Paul Bar on 1/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqSipMessage.h"

@interface QliqUserToUserMessage : QliqSipMessage

+(QliqUserToUserMessage*) qliqUserToUserMessageWithDictionary:(NSDictionary*)dict;

@end
