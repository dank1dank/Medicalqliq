 //
//  QliqAPIService.m
//  qliq
//
//  Created by Aleksey Garbarev on 11/8/12.
//
//

#import "QliqAPIService.h"

#import "QliqJsonSchemaHeader.h"
#import "KeychainService.h"
#import "JSONKit.h"
#import "RestClient.h"

#define NotImplmenetedException [NSException raise:@"Called superclass method" format:@"Method %@ should be called only in subclasses",NSStringFromSelector(_cmd)]

@implementation QliqAPIService
{
    ProgressHandler * serviceProgressHandler;
}

+ (id)sharedService {
    static id instance;
    if (!instance) {
        @synchronized(self){
            instance = [[self alloc] init];
        }
    }
    return instance;
}

- (Schema)requestSchema {
    return SchemeUnavailable;
}

- (Schema)responseSchema {
    return SchemeUnavailable;
}

- (NSString *)serviceName {
    NotImplmenetedException;
    return nil;
}

- (NSString *)requestJson {
    NotImplmenetedException;
    return nil;
}

- (void)handleResponseMessageData:(NSDictionary *)dataDict withCompletition:(CompletionBlock)completitionBlock {
    NotImplmenetedException;
}

- (void)handleError:(NSError *)error
{
    // Implement in a subclass
}

- (QliqAPIServiceType)type {
    return QliqAPIServiceTypePost;
}

- (WebServerType) webServerType {
    return RegularWebServerType;
}

- (id<NSCopying>)progressHandlerKey {
    return nil;
}

- (unsigned long long)expectedBytesToDownload {
    return 0;
}

- (NSString *)filePath {
    return nil;
}

- (NSError *)errorFromDictionary:(NSDictionary *)errorDict {
    
    NSDictionary * userInfo = @{
        NSLocalizedDescriptionKey : errorDict[ERROR_MSG],
        @"received_error_dictionary" : errorDict // don't change this string, used by QliqConnect
    };
    
    NSInteger errorCode = [errorDict[ERROR_CODE] intValue];
    
    return [NSError errorWithDomain:errorCurrentDomain code:errorCode userInfo:userInfo];
}

- (void) handleResponseMessage:(NSDictionary *) messageDict  withCompletition:(CompletionBlock) completitionBlock{
    NSDictionary *dataDict = [messageDict objectForKey:DATA];
    if (dataDict){
        [self handleResponseMessageData:dataDict withCompletition:completitionBlock];
    }else{
        NSDictionary *errorDict = [messageDict objectForKey:ERROR];
        NSError * error = [self errorFromDictionary:errorDict];
        if (completitionBlock && errorDict) completitionBlock(CompletitionStatusError, errorDict, error);
    }
}

- (void)handleResponseString:(NSString *)responseString withCompletition:(CompletionBlock)completitionBlock {

    //validate response
    if ([JSONSchemaValidator validate:responseString embeddedSchema:[self responseSchema]]) {
        
        NSError *error = nil;
        NSData *jsonData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
        JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
        NSMutableDictionary * message = [[jsonKitDecoder objectWithData:jsonData error:&error] objectForKey:MESSAGE];
        
        //if parsed message
        if (!error) {
            [self handleResponseMessage:message withCompletition:completitionBlock];
        }
        else {
            if (completitionBlock) {
                completitionBlock(CompletitionStatusError, nil, error);
            }
        }
    }
    else {
        NSError * error = [[NSError alloc] initWithDomain:errorCurrentDomain code:ErrorCodeInvalidResponse userInfo:userInfoWithDescription(@"Response scheme validation error")];
        if (completitionBlock)
            completitionBlock(CompletitionStatusError, nil, error);
    }
}

/* ProgressHandlers allow users to cancel upload/download progress at anytime. 
 * For this reason we pass completion block, to call it when cancellation */
- (ProgressHandler *) setupProgressHandlerForOperation:(MKNetworkOperation *) networkOperation completeBlock:(CompletionBlock)completeBlock{
    
    /* Create progress handler for service */
    ProgressHandler * progressHandler = nil;
    id <NSCopying> key = [self progressHandlerKey];
    if (key){
        progressHandler = [[ProgressHandler alloc] init];
        [appDelegate.network.progressHandlers setProgressHandler:progressHandler forKey:key];
        
        BOOL isUploading = ([self type] == QliqAPIServiceTypeUpload);
       
        void(^runBlock)(double progress, ProgressState runState);
        
        runBlock = ^(double progress, ProgressState runState){
            if ([progressHandler shouldCancelProgress]){
                if (completeBlock) completeBlock(CompletitionStatusCancel, self, nil);
                [networkOperation cancel];
            }else{
                [progressHandler setState:runState];
                [progressHandler setProgress:progress];
            }
        };
        
        ProgressHandler* ph = progressHandler;
        progressHandler.onCancel = ^{
            runBlock(ph.currentProgress, ProgressStateCancelled);
        };
        
        if (isUploading) { /* Shedule uploading tracking */
            [networkOperation onUploadProgressChanged:^(double progress) {
                runBlock(progress, ProgressStateUploading);
            }];
        }
        else { /* Shedule downloading tracking */
            unsigned long long exeptedBytes = [self expectedBytesToDownload];
            if (exeptedBytes == 0){
                [networkOperation onDownloadProgressChanged:^(double progress) {
                    runBlock(progress, ProgressStateDownloading);
                }];
            }else{
                [networkOperation onDownloadSizeChanged:^(unsigned long long downloadedDataLen) {
                    runBlock(downloadedDataLen / (float) exeptedBytes, ProgressStateDownloading);
                }];
            }
        }
    }
    return progressHandler;
}

- (void) callServiceWithCompletition:(CompletionBlock) completitionBlock{
    
    /* intercept completion to signal progress handler about error */
    CompletionBlock metaCompletion = ^(CompletitionStatus status, id result, NSError * error) {
        
        /* Call complete block */
        if (completitionBlock)
            completitionBlock(status, result, error);
        
        /* Notify progress handler that operation ended */
        id<NSCopying> key = [self progressHandlerKey];
        if (key && serviceProgressHandler)
        {
            switch (status) {
                case CompletitionStatusError:
                    [serviceProgressHandler setState:ProgressStateError];
                    break;
                case CompletitionStatusCancel:
                    [serviceProgressHandler setState:ProgressStateCancelled];
                    break;
                case CompletitionStatusSuccess:
                    [serviceProgressHandler setState:ProgressStateComplete];
                    break;
            }
            [appDelegate.network.progressHandlers removeProgressHandlerForKey:key];
        }
    };
    
    NSMutableDictionary * jsonDict = [[self requestJson] mutableCopy];
    if ([JSONSchemaValidator validate:[jsonDict JSONString] embeddedSchema:[self requestSchema]]){
        
        RestClient *restClient = [RestClient clientForCurrentUser];
        
        QliqAPIServiceType type = [self type];
        NSString * path = [self filePath];
        // I don't know why we have this condition so I kept it to avoid breaking code
        // but only changed so it doesn't break my PUT requests - Adam Sowa
        if (type != QliqAPIServiceTypePut && (!path || path.length == 0)) {
            type = QliqAPIServiceTypePost;
        }
        
        PostBlock onRequestComplete = ^(NSString * responseString){
            [self handleResponseString:responseString withCompletition:metaCompletion];
        };
        MKNKErrorBlock onError = ^(NSError* error){
            [self handleError:error];
            metaCompletion(CompletitionStatusError, nil, error);
        };
        MKNetworkOperation * networkOperation = nil;
        switch (type) {
            case QliqAPIServiceTypePost:
                networkOperation = [restClient postDataToServer:[self webServerType] path:[self serviceName] jsonToPost:jsonDict onCompletion:onRequestComplete onError:onError];
                break;
            case QliqAPIServiceTypePut:
                networkOperation = [restClient sendDataToServer:[self webServerType] path:[self serviceName] jsonToPost:jsonDict doPut:YES onCompletion:onRequestComplete onError:onError];
                break;
            case QliqAPIServiceTypeUpload:
                networkOperation = [restClient uploader:[self webServerType] path:[self serviceName] jsonToPost:jsonDict filePath:path fileName:[path lastPathComponent] onCompletion:onRequestComplete onError:onError];
                break;
            case QliqAPIServiceTypeDownload:
                networkOperation = [restClient downloader:[self webServerType] path:[self serviceName] jsonToPost:jsonDict toFile:path onCompletion:onRequestComplete onError:onError];
                break;
        }
        serviceProgressHandler = [self setupProgressHandlerForOperation:networkOperation completeBlock:metaCompletion];
        
    } else {
        NSError * error = [[NSError alloc] initWithDomain:errorCurrentDomain code:ErrorCodeInvalidRequest userInfo:userInfoWithDescription(@"Requst scheme validation error")];
        metaCompletion(CompletitionStatusError, nil, error);
    }
}


@end
