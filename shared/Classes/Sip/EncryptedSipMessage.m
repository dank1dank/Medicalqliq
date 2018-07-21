//
//  EncryptedSipMessage.m
//  qliq
//
//  Created by Adam on 12/3/12.
//
//

#import "EncryptedSipMessage.h"

@implementation EncryptedSipMessage

@synthesize messageId, fromQliqId, toQliqId, body, timestamp, mime, extraHeaders;

- (BOOL) isEmpty
{
    return [body length] == 0;
}

@end
