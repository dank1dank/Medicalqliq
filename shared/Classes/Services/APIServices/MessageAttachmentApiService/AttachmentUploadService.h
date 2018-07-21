//
//  UploadAttachmentService.h
//  qliq
//
//  Created by Aleksey Garbarev on 28.11.12.
//
//

#import "QliqAPIService.h"

#import "MessageAttachment.h"


@interface AttachmentUploadService : QliqAPIService

- (id) initWithAttachment:(MessageAttachment *) attachment recipientId:(NSString *) recipientId;

@end
