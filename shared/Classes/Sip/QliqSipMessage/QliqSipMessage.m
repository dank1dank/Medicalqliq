//
//  QliqSipMessage.m
//  qliq
//
//  Created by Paul Bar on 1/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqSipMessage.h"
#import "JSONSchemaValidator.h"
#import "JSONKit.h"
#import "QliqSip.h"
#import "JsonSchemas.h"
#import "QliqUserToUserMessage.h"

@implementation QliqSipMessage

+(QliqSipMessage*) messageWithNotification:(NSNotification *)notification
{
    NSString *jsonString = [[notification userInfo] objectForKey: @"Message"];
    NSString *fromQliqId = [[notification userInfo] objectForKey: @"FromQliqId"];
    NSString *toQliqId = [[notification userInfo] objectForKey: @"ToQliqId"];
    
	NSDictionary *extraHeaders = [[notification userInfo] objectForKey:@"ExtraHeaders"];
    
	BOOL validJson = [JSONSchemaValidator validate:jsonString embeddedSchema:MessageSchema];
	if (!validJson)
    {
		DDLogError(@"Invalid JSON message received: \"%@\"", jsonString);
		return nil;
	}
	QliqSipMessage *rez = nil;
	NSStringEncoding stringEncoding = NSUTF8StringEncoding;
	NSStringEncoding dataEncoding = stringEncoding; // NSUTF32BigEndianStringEncoding;	
	NSError *error=nil;
	
	NSData *jsonData = [jsonString dataUsingEncoding:dataEncoding];
	
	JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
	NSMutableDictionary *message = [[jsonKitDecoder objectWithData:jsonData error:&error] objectForKey:MESSAGE_MESSAGE];
    
    NSString *type = [message objectForKey:MESSAGE_MESSAGE_TYPE];
    
    if([type isEqualToString:CHAT_MESSAGE_MESSAGE_TYPE_PATTERN])
    {
        rez = [QliqUserToUserMessage qliqUserToUserMessageWithDictionary:message];
    }

    if (!rez)
        rez = [[[QliqSipMessage alloc] initWithDictionary:message] autorelease];
    
    rez.fromQliqId = fromQliqId;
    rez.toQliqId = toQliqId;
    rez.extraHeaders = (NSMutableDictionary*) extraHeaders;
    return rez;
}

@synthesize type;
@synthesize command;
@synthesize subject;
@synthesize fromQliqId;
@synthesize toQliqId;
@synthesize data;
@synthesize extraHeaders;

-(id) initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if(self)
    {
        self.type = [dict objectForKey:MESSAGE_MESSAGE_TYPE];
        self.command = [dict objectForKey:MESSAGE_MESSAGE_COMMAND];
        self.subject = [dict objectForKey:MESSAGE_MESSAGE_SUBJECT];
        self.data = [dict objectForKey:MESSAGE_MESSAGE_DATA];
    }
    return self;
}

-(void) dealloc
{
    [type release];
    [command release];
    [subject release];
    [fromQliqId release];
    [toQliqId release];
    [data release];
    [super dealloc];
}

@end
