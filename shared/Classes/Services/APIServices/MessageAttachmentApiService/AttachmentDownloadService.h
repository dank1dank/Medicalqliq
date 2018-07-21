//
//  AttachmentDownloadService.h
//  qliq
//
//  Created by Aleksey Garbarev on 28.11.12.
//
//

#import "QliqAPIService.h"
#import "MessageAttachment.h"

@interface AttachmentDownloadService : QliqAPIService

- (id) initWithAttachment:(MessageAttachment *) attachment;

@end
