//
//  FhirEncounterUpdateService.m
//  qliq
//
//  Created by Adam Sowa on 20/07/16.
//
//

#import "FhirEncounterUpdateService.h"
#import "JSONKit.h"
#import "RestClient.h"

@interface FhirEncounterUpdateService()

@property (nonatomic, strong) NSString *encounterId;
@property (nonatomic, strong) NSString *json;

@end

@implementation FhirEncounterUpdateService

- (id) initWithId:(NSString *)encounterId andJson:(NSString *)json
{
    self = [super init];
    if (self) {
        self.encounterId = encounterId;
        self.json = json;
    }
    return self;
}

#pragma mark - Private

- (QliqAPIServiceType)type {
    return QliqAPIServiceTypePut;
}

- (NSString *)serviceName {
    return [@"fhir/encounters/" stringByAppendingString:self.encounterId];
}

- (NSDictionary *)requestJson {
    // QliqAPIService uses NSDictionary for request body so we need to parse string into dictionary
    // This is wasting a bit of CPU cycles but I don't want to rewrite other services for this one exception
    NSError *error = nil;
    NSData *jsonData = [self.json dataUsingEncoding:NSUTF8StringEncoding];
    JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
    return [jsonKitDecoder objectWithData:jsonData error:&error];
}

- (void)callServiceWithCompletition:(CompletionBlock)completitionBlock
{
    // Because we use FHIR web API, that is not compatible with regular Qliq web API
    // we need to reimplement the methods to callService and to handle response/error
    RestClient *restClient = [RestClient clientForCurrentUser];
    
    PostBlock onRequestComplete = ^(NSString * responseString){
        //[self handleResponseString:responseString withCompletition:completitionBlock];
        if (completitionBlock) {
            completitionBlock(CompletitionStatusSuccess, nil, nil);
        }
    };
    MKNKErrorBlock onError = ^(NSError* error){
        //[self handleError:error];
        if (completitionBlock) {
            completitionBlock(CompletitionStatusError, nil, error);
        }
    };
    
    [restClient sendDataToServer:[self webServerType] path:[self serviceName] jsonToPost:[self requestJson] doPut:YES onCompletion:onRequestComplete onError:onError];

}

@end
