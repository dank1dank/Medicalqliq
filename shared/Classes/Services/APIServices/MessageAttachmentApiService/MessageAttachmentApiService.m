//
//  MessageAttachmentApiService.m
//  qliq
//
//  Created by Paul Bar on 4/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MessageAttachmentApiService.h"
#import "ChatMessage.h"
#import "MessageAttachment.h"
#import "QliqConnectModule.h"

#import "AttachmentUploadService.h"
#import "AttachmentDownloadService.h"

@interface MessageAttachmentApiService()

@end

@implementation MessageAttachmentApiService

- (void) uploadAllAttachmentsForMessage:(ChatMessage *)message completition:(CompletionBlock) completition{

    if([[message attachments] count] == 0){
        if (completition) completition(CompletitionStatusSuccess, nil, nil);
        return;
    }
    
    NSInteger sheduledCount = [[message attachments] count];
    __block NSInteger completeCount = 0;
    for(MessageAttachment* attachment in [message attachments]){
                
        if (attachment.status == AttachmentStatusUploadFailed) attachment.status = AttachmentStatusToBeUploaded; //Reupload if was failed
        
        if ([attachment isUploadedToServer]){
            sheduledCount--;
        }else{
            [self uploadAttachment:attachment forUser:message.toQliqId completition:^(CompletitionStatus status, id result, NSError *error) {
                @synchronized(self){
                    if (completeCount++ >= sheduledCount) return;

                    if (status == CompletitionStatusError || status == CompletitionStatusCancel)
                        completeCount = sheduledCount; //Break all next attachments. i.e. make current uploading latest

                    //performs when last attachment uploaded
                    if (completeCount == sheduledCount){
                        if (completition) completition(status, message, error);
                    }
                }
            }];
        }
    }
    
    if (sheduledCount == 0){
        DDLogInfo(@"All attachments uploaded. Skipped attachments: %lu",(unsigned long)[[message attachments] count]);
        if (completition) completition(CompletitionStatusSuccess, message, nil);
    }
    
}


- (void) uploadAttachment:(MessageAttachment *)attachment forUser:(NSString *)qliqId completition:(CompletionBlock) completition{

    AttachmentUploadService * uploadService = [[AttachmentUploadService alloc] initWithAttachment:attachment recipientId:qliqId];
    [uploadService callServiceWithCompletition:completition];
}


- (void) downloadAttachment:(MessageAttachment*)attachment completion:(CompletionBlock)completition
{
    AttachmentDownloadService * downloadService = [[AttachmentDownloadService alloc] initWithAttachment:attachment];
    [downloadService callServiceWithCompletition:completition];
}






@end
