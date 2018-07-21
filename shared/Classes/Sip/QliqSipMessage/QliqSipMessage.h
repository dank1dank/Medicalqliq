//
//  QliqSipMessage.h
//  qliq
//
//  Created by Paul Bar on 1/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QliqSipMessage : NSObject

+(QliqSipMessage*) messageWithNotification:(NSNotification*)notification;

-(id) initWithDictionary:(NSDictionary*)dict;

@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSString *command;
@property (nonatomic, retain) NSString *subject;
@property (nonatomic, retain) NSString *fromQliqId;
@property (nonatomic, retain) NSString *toQliqId;
@property (nonatomic, retain) id data;
@property (nonatomic, retain) NSMutableDictionary *extraHeaders;

@end
