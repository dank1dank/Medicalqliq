//
//  AttachmentDownloadService.m
//  qliq
//
//  Created by Aleksey Garbarev on 28.11.12.
//
//

#import "AttachmentDownloadService.h"
#import "QliqJsonSchemaHeader.h"
#import "MessageAttachmentDBService.h"
#import "JSONKit.h"
#import "MediaFile.h"

@implementation AttachmentDownloadService{
    MessageAttachment * attachment;
    NSString *downloadedFilePath;
}

- (id) initWithAttachment:(MessageAttachment *) _attachment{
    self = [super init];
    if (self) {
        attachment = _attachment;
        downloadedFilePath = [attachment.mediaFile generateFilePathForName:attachment.url];
    }
    return self;
}

- (QliqAPIServiceType)type{
    return QliqAPIServiceTypeDownload;
}

- (WebServerType) webServerType {
    return FileWebServerType;
}

- (Schema)requestSchema{
    return GetFileRequestSchema;
}

- (Schema)responseSchema{
    return SchemeUnavailable;
}

- (NSString *)filePath{
    return downloadedFilePath;
}

- (NSString *)serviceName{
    return @"services/get_file";
}

- (unsigned long long)expectedBytesToDownload{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    return [[formatter numberFromString:attachment.mediaFile.fileSizeString] unsignedLongValue];
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
								 attachment.url, FILE_NAME,
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
        
    attachment.status = AttachmentStatusDownloading;
    [attachment save];
    
    /* intercept completion to set right attachment status */
    CompletionBlock metaCompletion = ^(CompletitionStatus status, id result, NSError * error){
        
        
        NSArray *relatedAttachments = [[MessageAttachmentDBService sharedService] getAttachmentsForMediaFileId:attachment.mediaFile.mediafileId];
        
        for (MessageAttachment *_attachment in relatedAttachments) {
            
            if (status == CompletitionStatusSuccess) {
                _attachment.status = AttachmentStatusDownloaded;
                _attachment.mediaFile.encryptedPath = downloadedFilePath;
                [_attachment save];
            }else{
                _attachment.status = AttachmentStatusDownloadFailed;
                [_attachment save];
            }
        }
        
        if (completitionBlock) completitionBlock(status, result, error);
    };
    
    [super callServiceWithCompletition:metaCompletion];
}

/* If responseString is empty - it's ok, if contain error - handle error  */
- (void) handleResponseString:(NSString *) responseString withCompletition:(CompletionBlock) completitionBlock{
    
    /* Checking error dict */
    NSData *jsonData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
    JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
    NSMutableDictionary *message = [[jsonKitDecoder objectWithData:jsonData error:nil] objectForKey:MESSAGE];
	NSDictionary *errorDict = [message valueForKey:ERROR];
    
	if(!errorDict){
        if (completitionBlock) completitionBlock(CompletitionStatusSuccess, attachment, nil);
	}else{
        if (completitionBlock) completitionBlock(CompletitionStatusError, nil, [self errorFromDictionary:errorDict]);
	}
}

@end
