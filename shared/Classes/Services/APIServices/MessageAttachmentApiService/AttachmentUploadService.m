//
//  UploadAttachmentService.m
//  qliq
//
//  Created by Aleksey Garbarev on 28.11.12.
//
//

#import "AttachmentUploadService.h"
#import "QliqJsonSchemaHeader.h"
#import "MediaFile.h"

@implementation AttachmentUploadService{
    NSString * recipientId;
    MessageAttachment * attachment;
}


- (id) initWithAttachment:(MessageAttachment *) _attachment recipientId:(NSString *) _recipientId{
    self = [super init];
    if (self) {
        attachment = _attachment;
        recipientId = _recipientId;
    }
    return self;
}

- (QliqAPIServiceType)type{
    return QliqAPIServiceTypeUpload;
}

- (WebServerType) webServerType {
    return FileWebServerType;
}

- (Schema)requestSchema{
    return PutFileRequestSchema;
}

- (Schema)responseSchema{
    return PutFileResponseSchema;
}

- (NSString *) serviceName{
    return @"services/put_file";
}

- (NSString *)filePath{
    return attachment.mediaFile.encryptedPath;
}

- (id<NSCopying>)progressHandlerKey{
    return [NSString stringWithFormat:@"%ld",(long)attachment.attachmentId];
}

- (NSDictionary *)requestJson{
    UserSession *currentSession = [UserSessionService currentUserSession];
    NSString *username = currentSession.sipAccountSettings.username;
    NSString *password = currentSession.sipAccountSettings.password;
    
	NSDictionary *contentDict = [NSDictionary dictionaryWithObjectsAndKeys:
								 password, PASSWORD,
								 username, USERNAME,
								 recipientId, RECIPIENT_QLIQ_ID,
                                 nil];
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  contentDict, DATA,
							  nil];
	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									 dataDict, MESSAGE,
									 nil];
    return jsonDict;
}


- (void)callServiceWithCompletition:(CompletionBlock)completitionBlock{
    
    if (attachment.status != AttachmentStatusToBeUploaded){
        DDLogWarn(@"Attachment uploading cancelled because wrong status: %d", attachment.status);
        if (completitionBlock) completitionBlock(CompletitionStatusCancel,attachment,nil);
        return;
    }
    
    attachment.status = AttachmentStatusUploading;
    [attachment save];
    
    /* intercept completion to set right attachment status */
    CompletionBlock metaCompletion = ^(CompletitionStatus status, id result, NSError * error){
      
        if (status == CompletitionStatusError){
            attachment.status = AttachmentStatusUploadFailed;
            [attachment save];
        }
        if (status == CompletitionStatusCancel){
            attachment.status = AttachmentStatusDeclined;
            [attachment save];
        }
        
        if (completitionBlock) completitionBlock(status, result, error);
    };
    
    [super callServiceWithCompletition:metaCompletion];
}

- (void)handleResponseMessageData:(NSDictionary *)dataDict withCompletition:(CompletionBlock)completitionBlock{
    
    if (dataDict && attachment.status == AttachmentStatusUploading){
        attachment.url = [dataDict objectForKey:SAVED_FILE_NAME];
        attachment.status = AttachmentStatusUploaded;
        [attachment save];
        if (completitionBlock) completitionBlock(CompletitionStatusSuccess, attachment, nil);
        
		DDLogSupport(@"Uploaded file for url: %@", attachment.url);
    }
}


@end
