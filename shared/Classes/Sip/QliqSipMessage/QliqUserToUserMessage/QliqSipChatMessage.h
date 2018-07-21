//
//  QliqSipChatMessage.h
//  qliq
//
//  Created by Paul Bar on 1/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqUserToUserMessage.h"

@interface QliqSipChatMessage : QliqUserToUserMessage

@property (nonatomic, retain) NSString *messageText;

@end
