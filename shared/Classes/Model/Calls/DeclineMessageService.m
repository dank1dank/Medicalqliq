//
//  DeclineMessageService.m
//  qliq
//
//  Created by Paul Bar on 2/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DeclineMessageService.h"
#import "DeclineMessage.h"

@implementation DeclineMessageService

-(NSArray*) getDeclineMessages
{
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"declineMessages" ofType:@"plist"];
    NSDictionary *plistContent = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    NSArray *messageStrings = [plistContent objectForKey:@"declineMessages"];
    NSMutableArray *mutableRez = [[NSMutableArray alloc] initWithCapacity:[messageStrings count]];
    for(NSString *message in messageStrings)
    {
        DeclineMessage *declineMessage = [[DeclineMessage alloc] init];
        declineMessage.messageText = message;
        [mutableRez addObject:declineMessage];
        [declineMessage release];
    }
    NSArray *rez = [NSArray arrayWithArray:mutableRez];
    [mutableRez release];
    return rez;
}

@end
