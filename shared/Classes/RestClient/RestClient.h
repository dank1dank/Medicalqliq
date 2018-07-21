//
//  RestClient.h
//  qliq
//
//  Created by Ravi Ada on 4/29/12.
//  Copyright (c) 2012 Dobeyond inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MKNetworkKit.h"

@interface LoggedNetworkOperation : MKNetworkOperation

@property (nonatomic, assign) int requestId;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, assign) NSInteger protocolAndHostNameLength;

@end

@interface RestClient : MKNetworkEngine
{
    BOOL useSsl;
}

typedef void (^FileUploadBlock)(NSString *responseDict);
typedef void (^FileDownloadBlock)(NSString *responseDict);
typedef void (^PostBlock)(NSString *responseDict);

extern NSString * RestClientReachabilityChangedNotification;
extern NSString * RestClientCertificateForAnotherDomainDetectedNotification;

/* RestClient download mode
 */
typedef enum {
    RCDownloadModeRewrite,
    RCDownloadModeRewriteOnlyDifferent,
    RCDownloadModeNotRewrite
} RCDownloadMode;

// Keep in sync with qx::WebClient::ServerType
typedef enum {
    RegularWebServerType = 0,
    FileWebServerType = 1
} WebServerType;

- (MKNetworkOperation *)uploader:(WebServerType)serverType
                            path:(NSString *)serviceName
                      jsonToPost:(NSMutableDictionary *)jsonDict
                        filePath:(NSString *)filePath
                        fileName:(NSString *)fileName
                    onCompletion:(FileUploadBlock)completionBlock
                         onError:(MKNKErrorBlock)errorBlock;

- (MKNetworkOperation *)downloader:(NSString *)urlString
                            toFile:(NSString *)filePath
                      downloadMode:(RCDownloadMode)_mode
                      onCompletion:(FileDownloadBlock)completionBlock
                           onError:(MKNKErrorBlock)errorBlock;

- (MKNetworkOperation *)downloader:(WebServerType)serverType
                              path:(NSString *)serviceName
                        jsonToPost:(NSMutableDictionary *)jsonDict
                            toFile:(NSString *)fileName
                      onCompletion:(FileDownloadBlock)completionBlock
                           onError:(MKNKErrorBlock)errorBlock;

- (MKNetworkOperation *)postDataToServer:(WebServerType)serverType
                                    path:(NSString *)serviceName
                              jsonToPost:(NSDictionary *)jsonDict
                            onCompletion:(PostBlock)completionBlock
                                 onError:(MKNKErrorBlock)errorBlock;

- (MKNetworkOperation *)sendDataToServer:(WebServerType)serverType
                                    path:(NSString *)serviceName
                              jsonToPost:(NSDictionary *)jsonDict
                                   doPut:(BOOL)put
                            onCompletion:(PostBlock)completionBlock
                                 onError:(MKNKErrorBlock)errorBlock;

+ (RestClient *)clientForCurrentUser;

+ (void) setApiKey:(NSString *)apiKey;

+ (NSString *)serverUrlForUsername:(NSString*)un;

+ (BOOL)sslForUsername:(NSString*)un;

- (id)initWithHostName:(NSString *)hostName useSsl:(BOOL)_useSsl;

@end
