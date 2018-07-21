//
//  MessageAttachmentApiService.h
//  qliq
//
//  Created by Paul Bar on 4/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ApiServiceBase.h"
#import "ChatMessage.h"
#import "QliqConnectModuleTypes.h"

@class MessageAttachment;

@interface MessageAttachmentApiService : NSObject

- (void) uploadAttachment:(MessageAttachment *)attachment forUser:(NSString *)qliqId completition:(CompletionBlock) completition;

- (void) uploadAllAttachmentsForMessage:(ChatMessage *)message completition:(CompletionBlock) completition;

- (void) downloadAttachment:(MessageAttachment*)attachment completion:(CompletionBlock)completition;

@end
