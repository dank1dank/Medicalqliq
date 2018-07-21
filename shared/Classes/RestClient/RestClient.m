	//
//  RestClient.m
//  qliq
//
//  Created by Ravi Ada on 4/29/12.
//  Copyright (c) 2012 Dobeyond inc. All rights reserved.
//

#import "RestClient.h"

#import "UserSession.h"
#import "UserSessionService.h"
#import "JSONKit.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "KeychainService.h"
#import "QxPlatfromIOS.h"
#import "QliqJsonSchemaHeader.h"

#define plistServerNameKey @"ProductionServerUrl"
#define plistTestServerNameKey @"TestServerUrl"
#define plistServerProtocolKey @"ProductionServerProtocol"
#define plistTestServerProtocolKey @"TestServerProtocol"
#define AUTHORIZATION_HEADER @"Authorization"

@implementation LoggedNetworkOperation

- (void) operationSucceeded
{
    int jsonError = 0;
    id resp = [self responseJSON];
    if ([resp isKindOfClass:[NSDictionary class]]) {
        NSDictionary *jsonDict = (NSDictionary *)resp;
        NSDictionary *messageDict = [jsonDict objectForKey:MESSAGE];
        if (messageDict) {
            NSDictionary *errorDict = [messageDict objectForKey:ERROR];
            if (errorDict) {
                jsonError = [[errorDict objectForKey:ERROR_CODE] intValue];
            }
        }
    }
    NSString *path = [self.url substringFromIndex:self.protocolAndHostNameLength];
    NSTimeInterval seconds = [[NSDate date] timeIntervalSinceDate:self.startDate];
    [QxPlatfromIOS maybeUpdateWebResponseWithId:self.requestId duration:(int)seconds responseCode:(int)self.HTTPStatusCode jsonError:jsonError response:[self responseString]];
    DDLogSupport(@"Web response id: %d path: %@, http status: %d, json error code: %d", self.requestId, path, (int)self.HTTPStatusCode, jsonError);
    [super operationSucceeded];
}

- (void) operationFailedWithError:(NSError*) error
{
    NSString *path = [self.url substringFromIndex:self.protocolAndHostNameLength];
    NSString *responseStr = nil;
    int responseCode = (int)self.HTTPStatusCode;
    if (responseCode == 0) {
        // Network error
        NSString *errorStr = [error localizedDescription];
        responseCode = (int)error.code;
        responseStr = [NSString stringWithFormat:@"NSError: %@", errorStr];
        DDLogSupport(@"Web response (failed) id: %d path: %@, error code: %d, description: %@", self.requestId, path, responseCode, errorStr);
    } else {
        responseStr = [self responseString];
        DDLogSupport(@"Web response (failed) id: %d path: %@, http status: %d", self.requestId, path, responseCode);
    }
    NSTimeInterval seconds = [[NSDate date] timeIntervalSinceDate:self.startDate];
    [QxPlatfromIOS maybeUpdateWebResponseWithId:self.requestId duration:(int)seconds responseCode:responseCode jsonError:0 response:responseStr];
    [super operationFailedWithError:error];
}

@end

@interface RestClient(Private)

- (NSString*) mimeTypeOfFileAtPath:(NSString*)filePath;
+ (BOOL) hasTestServerSuffix:(NSString *)un;
- (MKNetworkOperation *) operationWithServerType:(WebServerType)serverType
                                            path:(NSString *)serviceName
                                      jsonToPost:(NSDictionary *)jsonDict
                                           doPut:(BOOL)put;
- (MKNetworkOperation*) loggedOperationWithURLString:(NSString*) urlString
                                              params:(NSDictionary*) body
                                          httpMethod:(NSString*) method;

@end

@implementation RestClient

static NSMutableDictionary *usersClients;

NSString *RestClientReachabilityChangedNotification = @"RestClientReachabilityChangedNotification";
NSString *RestClientCertificateForAnotherDomainDetectedNotification = @"RestClientCertificateForAnotherDomainDetectedNotification";

- (void)reachabilityDidChanged:(NetworkStatus)networkStatus {
    NSDictionary * userInfo = @{@"networkStatus" : [NSNumber numberWithInt:networkStatus] };
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:RestClientReachabilityChangedNotification object:self userInfo:userInfo];
    });
}

+ (NSString *) currentUserName
{
    NSString *currentUserName = nil;
    currentUserName = [UserSessionService currentUserSession].user.email;
    if(currentUserName == nil)
    {
        //if we are logging in, we dont have user object initialized. But we can use sip account settings to get logging user's id
        currentUserName = [UserSessionService currentUserSession].sipAccountSettings.username;
        if([currentUserName length]==0)
            currentUserName = [[KeychainService sharedService] getUsername];
    }
    return currentUserName;
}

+ (RestClient *)clientForCurrentUser
{
    RestClient *rez = nil;
    NSString *currentUserName = [self currentUserName];
    
    if (currentUserName != nil)
    {
        rez = [usersClients valueForKey:currentUserName];
        if (!rez){
            NSString *hostName = [RestClient serverUrlForUsername:currentUserName];
            rez = [[RestClient alloc] initWithHostName:hostName useSsl:[RestClient sslForUsername:currentUserName]];
            
            if (!usersClients){
                usersClients = [[NSMutableDictionary alloc] init];
            }
            @synchronized(self){
                [usersClients setValue:rez forKey:currentUserName];
            }
        }
    }
    
    return rez;
}

+ (void) setApiKey:(NSString *)apiKey
{
    NSString *currentUserName = [self currentUserName];
    if (currentUserName != nil) {
        RestClient *existing = [usersClients valueForKey:currentUserName];
        if (existing) {
            if (apiKey.length > 0) {
                [existing setCustomHeader:AUTHORIZATION_HEADER value:[@"Basic " stringByAppendingString:apiKey]];
            } else {
                [existing removeCustomHeader:AUTHORIZATION_HEADER];
            }
        }
    }
}

-(id) initWithHostName:(NSString *)hostName useSsl:(BOOL)_useSsl
{
	
	NSMutableDictionary *customHeaders = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								   @"qliq 2.0.0",@"User-Agent",
								   nil];
    
    NSString *apiKey = [[KeychainService sharedService] getApiKey];
    if (apiKey.length > 0) {
        // If there is API key we use it always, including for login request but that is fine
        // because webserve ignores it for login so we don't risk using a wrong one
        [customHeaders setValue:[@"Basic " stringByAppendingString:apiKey] forKey:AUTHORIZATION_HEADER];
    }
    
    self = [super initWithHostName:hostName customHeaderFields:customHeaders];
    if(self)
    {
        useSsl = _useSsl;
        //Add reachability handling
        __unsafe_unretained RestClient * weakSelfRef = self;
        self.reachabilityChangedHandler = ^(NetworkStatus ns){
            [weakSelfRef reachabilityDidChanged:ns];
        };
        [self registerOperationSubclass:[LoggedNetworkOperation class]];
    }
    return self;
}

- (MKNetworkOperation *)uploader:(WebServerType)serverType
                            path:(NSString *)serviceName
                      jsonToPost:(NSMutableDictionary *)jsonDict
                        filePath:(NSString *)filePath
                        fileName:(NSString *)fileName
                    onCompletion:(FileUploadBlock)completionBlock
                         onError:(MKNKErrorBlock)errorBlock
{
	
   MKNetworkOperation *op = [self operationWithServerType:serverType
                                                      path:serviceName
                                                jsonToPost:@{@"json": [jsonDict JSONString]}
                                                     doPut:NO];
    NSString *mimieType = [self mimeTypeOfFileAtPath:filePath];
	[op addFile:filePath forKey:@"uploaded_file" fileName:fileName mimeType:mimieType];
	// setFreezable uploads your images after connection is restored!
	[op setFreezable:YES];

    //[op setPostDataEncoding:MKNKPostDataEncodingTypeJSON];
	[op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        
        NSString *jsonString = [completedOperation responseString];
		DDLogVerbose(@"JSON:%@",jsonString);
		completionBlock(jsonString);
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        
        errorBlock(error);
    }];
	
	[self enqueueOperation:op];
	
	
	return op;
	
}

/**
 Downloads file by absolute URL to filePath with special RCDownloadMode
 RCDownloadMode sets behaviour in case that we already have file
    RCDownloadModeRewrite - just rewrites existing file
    RCDownloadModeRewriteOnlyDifferent - rewrites only if filesize and expecting contentSize are different
    RCDownloadModeNotRewrite - not rewrites file 
 */

- (MKNetworkOperation*) downloader:(NSString *) urlString
                            toFile:(NSString *) filePath
                      downloadMode:(RCDownloadMode) _mode
                      onCompletion:(FileDownloadBlock) completionBlock
                           onError:(MKNKErrorBlock) errorBlock
{
    
    if (_mode == RCDownloadModeNotRewrite && [[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        NSString * errorString = [NSString stringWithFormat:@"File at path %@ already exist",filePath];
        NSError * error = [[NSError alloc] initWithDomain:@"com.qliq.restclient" code:1 userInfo:userInfoWithDescription(errorString)];
        if (errorBlock) errorBlock(error);
        return nil;
    }
    
    NSString *currentUserName = nil;
    currentUserName = [UserSessionService currentUserSession].user.email;
    NSString *serverUrl = [RestClient serverUrlForUsername:currentUserName];
    NSString *absoluteAvatarUrl = [NSString stringWithFormat:@"http://%@%@",serverUrl,urlString];
    MKNetworkOperation * operation = [self loggedOperationWithURLString:absoluteAvatarUrl params:nil httpMethod:@"GET"];
    
    NSError *error = nil;
    NSString *folderPath = [filePath stringByDeletingLastPathComponent];
    if (![[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:&error]) {
        DDLogError(@"\nDirectory for filePath:\n <%@>\n wasn't created", folderPath);
        if (error) {
            DDLogError(@"\nDirectory for filePath:\n <%@>\n wasn't created with error:\n%@", folderPath, [error localizedDescription]);
        }
    }
    
    [operation addDownloadStream:[NSOutputStream outputStreamToFileAtPath:filePath append:NO]];//This output stream not rewrites file until not called [... open]
    //That means to not rewrite file we must cancel operation before [... open] called.
    //In our case is setResponseHandler block
    __unsafe_unretained MKNetworkOperation * weak_operation_ref = operation;
    [operation setResponseHandler:^(NSURLResponse *response) {
        
        //if size of downloading file same as already exist then cancel downloading
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath] && _mode == RCDownloadModeRewriteOnlyDifferent){
            
            unsigned long long contentLength = [response expectedContentLength];
            unsigned long long fileLength = [[[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] valueForKey:NSFileSize] unsignedLongLongValue];
            
            if (contentLength == fileLength){
                [weak_operation_ref cancel];
            }
        }
    }];
    
    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        
        completionBlock([completedOperation responseString]);
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        
        errorBlock(error);
    }];
    
    [self enqueueOperation:operation];
    
    return operation;
}

-(MKNetworkOperation*) downloader:(WebServerType)serverType
                             path:(NSString*) serviceName
					   jsonToPost:(NSMutableDictionary*) jsonDict
						   toFile:(NSString*) filePath
					 onCompletion:(FileDownloadBlock) completionBlock
						  onError:(MKNKErrorBlock) errorBlock
{
	MKNetworkOperation *op = [self operationWithServerType:serverType
                                                      path:serviceName
                                                jsonToPost:jsonDict
                                                     doPut:NO];
    
    [op addDownloadStream:[NSOutputStream outputStreamToFileAtPath:filePath
															append:NO]];
    
    [op setPostDataEncoding:MKNKPostDataEncodingTypeJSON];
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        
        NSString *jsonString = [completedOperation responseString];
		DDLogInfo(@"JSON:%@",jsonString);
		completionBlock(jsonString);
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        
        errorBlock(error);
    }];
	
    [self enqueueOperation:op];
    return op;

}

- (MKNetworkOperation *) operationWithServerType:(WebServerType)serverType
                                            path:(NSString *)path
                                      jsonToPost:(NSDictionary *)body
                                           doPut:(BOOL)put
{
    NSString *method = put ? @"PUT" : @"POST";
    NSString *hostName;
    
    if (serverType == FileWebServerType) {
        hostName = [[KeychainService sharedService] getFileServerUrl];
        if (hostName.length == 0) {
            hostName = [self readonlyHostName];
        } else if ([hostName hasPrefix:@"http"]) {
            // Webserver sends the file_server_info with protocol prefix
            // but to be compatible with old operationWithPath we remove the protocol here
            NSInteger prefixLen = 7; // http://
            if ([hostName characterAtIndex:4] == 's') {
                prefixLen += 1;
            }
            hostName = [hostName substringFromIndex:prefixLen];
        }
    } else if (serverType == RegularWebServerType) {
        hostName = [self readonlyHostName];
    } else {
        DDLogError(@"Unexpected serverType: %d", serverType);
        return nil;
    }
    
    if (hostName.length == 0) {
        DDLogError(@"Hostname is nil, use operationWithURLString: method to create absolute URL operations");
        return nil;
    }
    
    // Below code is copied 'as is' from MKNetworkEngine operationWithPath
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@://%@", useSsl ? @"https" : @"http", hostName];
    
    if(self.portNumber != 0)
        [urlString appendFormat:@":%d", self.portNumber];
    
    if(self.apiPath)
        [urlString appendFormat:@"/%@", self.apiPath];
    
    if(![path isEqualToString:@"/"]) { // fetch for root?
        
        if(path.length > 0 && [path characterAtIndex:0] == '/') // if user passes /, don't prefix a slash
            [urlString appendFormat:@"%@", path];
        else if (path != nil)
            [urlString appendFormat:@"/%@", path];
    }
    
    
    return [self loggedOperationWithURLString:urlString params:body httpMethod:method];
}

- (MKNetworkOperation*) loggedOperationWithURLString:(NSString*) urlString
                                              params:(NSDictionary*) body
                                          httpMethod:(NSString*) method
{
    int requestId = [QxPlatfromIOS maybeLogWebRequestMethod:method url:urlString json:body];
    NSInteger protocolAndHostNameLength = 7 + (useSsl ? 1 : 0) + self.readonlyHostName.length;
    NSString *path = [urlString substringFromIndex:protocolAndHostNameLength];
    DDLogSupport(@"Web request id: %d path: %@", requestId, path);
    NSDate *startDate = [NSDate date];
    LoggedNetworkOperation *op = (LoggedNetworkOperation *) [self operationWithURLString:urlString params:body httpMethod:method];
    op.requestId = requestId;
    op.startDate = startDate;
    op.protocolAndHostNameLength = protocolAndHostNameLength;
    return op;
}

- (MKNetworkOperation *)sendDataToServer:(WebServerType)serverType
                                    path:(NSString *)serviceName
                              jsonToPost:(NSDictionary *)jsonDict
                                   doPut:(BOOL)put
                            onCompletion:(PostBlock)completionBlock
                                 onError:(MKNKErrorBlock)errorBlock
{
    MKNetworkOperation *op = nil;
    if ([serviceName hasPrefix:@"http://"] || [serviceName hasPrefix:@"https://"]) {
        op = [self loggedOperationWithURLString:serviceName params:jsonDict httpMethod:@"POST"];
    } else {
        op = [self operationWithServerType:serverType
                                      path:serviceName
                                jsonToPost:jsonDict
                                     doPut:put];
    }
    
    [op setPostDataEncoding:MKNKPostDataEncodingTypeJSON];
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        
        //DDLogSupport(@"RestClient completed POST request for %@", serviceName);
        NSString *jsonString = [completedOperation responseString];
        if (jsonString == nil) {
            return;
        }
        completionBlock(jsonString);
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        
        //DDLogError(@"RestClient error doing POST request for %@: %@", serviceName, error);
        errorBlock(error);
        
        if (error.code == -1202) {
            NSString *certDomain = completedOperation.serverCertSubject;
            NSString *expectedHostname = self.readonlyHostName;
            
            DDLogError(@"Got HTTPS certificate error when connecting to host: %@, cert domain: %@", expectedHostname, certDomain);
            if (certDomain.length > 0) {
                // Fix for wildcard certs like *.qliqsoft.com
                certDomain = [certDomain stringByReplacingOccurrencesOfString:@"*." withString:@""];
                
                if ([expectedHostname rangeOfString:certDomain].location == NSNotFound) {
                    DDLogError(@"Looks like the certificate is for another domain, sending notification");
                    
                    NSDictionary * userInfo = @{@"domain" : certDomain};
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:RestClientCertificateForAnotherDomainDetectedNotification object:self userInfo:userInfo];
                    });
                }
            }
        }
    }];
    
    [self enqueueOperation:op];
    
    return op;
}

-(MKNetworkOperation*) postDataToServer:(WebServerType)serverType
                                   path:(NSString *) serviceName
							 jsonToPost:(NSDictionary*) jsonDict
						   onCompletion:(PostBlock) completionBlock
								onError:(MKNKErrorBlock) errorBlock
{
    return [self sendDataToServer:serverType path:serviceName jsonToPost:jsonDict doPut:NO onCompletion:completionBlock onError:errorBlock];
}

+ (NSString *) serverUrlForUsername:(NSString*)un
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"qliqApiConfiguration" ofType:@"plist"];
    NSDictionary *plistContent = [NSDictionary dictionaryWithContentsOfFile:path];
    if ([self hasTestServerSuffix:un])
    {
        return [plistContent objectForKey:plistTestServerNameKey];
    }
    else
    {
        return [plistContent objectForKey:plistServerNameKey];
    }
}

+ (BOOL) sslForUsername:(NSString*)un
{
    NSString *protocol = nil;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"qliqApiConfiguration" ofType:@"plist"];
    NSDictionary *plistContent = [NSDictionary dictionaryWithContentsOfFile:path];
    if ([self hasTestServerSuffix:un])
    {
        protocol = [plistContent objectForKey:plistTestServerProtocolKey];
    }
    else
    {
        protocol = [plistContent objectForKey:plistServerProtocolKey];
    }
    
    return [@"https" isEqualToString:protocol];
}

@end

#pragma mark - RestClient Private -

@implementation RestClient(Private)

+ (BOOL)hasTestServerSuffix:(NSString *)un {
    return ([un hasSuffix:@".demo"]||[un hasSuffix:@".dev"]||[un hasSuffix:@".test"]||[un hasSuffix:@".test.com"]
            ||[un hasPrefix:@"testqliq"]
            ||[un containsString:@"subuser1111"]);
}

- (NSString *)mimeTypeOfFileAtPath:(NSString *)filePath {
    NSString *rez = nil;

    CFStringRef fileExtension = (__bridge_retained CFStringRef)[filePath pathExtension];
    CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);
    
    CFStringRef mimeType = UTTypeCopyPreferredTagWithClass (fileUTI, kUTTagClassMIMEType);

    if (mimeType == nil) {
        rez = @"application/octet-stream";
    }
    else {
        rez = (__bridge_transfer NSString *)mimeType;
    }
    
    CFRelease(fileUTI);
    CFRelease(fileExtension);
    
    return rez;
}

@end
