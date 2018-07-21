//
//  QliqAPIService.h
//  qliq
//
//  Created by Aleksey Garbarev on 11/8/12.
//
//

#import <Foundation/Foundation.h>
#import "JSONSchemaValidator.h"
#import "RestClient.h"

typedef enum {
    QliqAPIServiceTypePost,
    QliqAPIServiceTypeUpload,
    QliqAPIServiceTypeDownload,
    QliqAPIServiceTypePut
} QliqAPIServiceType;

enum {
    ErrorCodeInvalidRequest         = 99,
    ErrorCodeInvalidResponse,
    ErrorCodeInvalidCredentials     = 100,
    ErrorCodeClientHasOldVersion    = 101,
    ErrorCodeServerSideProblems     = 102,
    ErrorCodeStaleData              = 103, //if it is not qliq user
    ErrorCodeNotContact             = 104, //if it is not a contact, but qliq user
    ErrorCodeNotMemberOfGroup       = 105,
    ErrorCodePublicKeyNotSet        = 106,
    ErrorCodeAccessDenied           = 107,
    ErrorCodeRequestTimout          = -1001,
    ErrorCodeCantConnect            = -1004,
    ErrorCodeCantDetermineContactType = -1005, // cannot tell if that is user, group or mp
    
    ErrorCodeSSLFailed              = -1200
};

#define isNetworkErrorCode(code) code < -1000 && code > -1100

#define isSSLErrorCode(code) code == ErrorCodeSSLFailed

@interface QliqAPIService : NSOperation

- (void)callServiceWithCompletition:(CompletionBlock)completitionBlock;

- (void)handleResponseString:(NSString *)responseString withCompletition:(CompletionBlock)completitionBlock;
- (void)handleResponseMessage:(NSDictionary *)messageDict  withCompletition:(CompletionBlock)completitionBlock;

- (NSError *)errorFromDictionary:(NSDictionary *)errorDict;

/* Empty methods to override: */

- (QliqAPIServiceType)type;
- (WebServerType) webServerType;

/* Override to support progress handler creation for operation */
- (id <NSCopying>)progressHandlerKey;  /* Search for progresshandler in appDelegate.network.progressHandlers with this key */
- (unsigned long long)expectedBytesToDownload;

/*  Used for uploader or downloader depends on type. If returns nil, use QliqAPIServiceTypePost type */
- (NSString *)filePath;

- (Schema)requestSchema;
- (Schema)responseSchema;

- (NSString *)serviceName;
- (NSDictionary *)requestJson;

- (void)handleResponseMessageData:(NSDictionary *)dataDict withCompletition:(CompletionBlock)completitionBlock;
- (void)handleError:(NSError *)error;

@end
