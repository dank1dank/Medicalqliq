//
//  UploadToEmrService.h
//  qliq
//
//  Created by Adam Sowa on 24/01/17.
//
//

#import <Foundation/Foundation.h>

@class FhirPatient;

@interface EmrUploadParams : NSObject
@property (nonatomic, strong) NSString *qliqStorQliqId;
@property (nonatomic, strong) NSString *qliqStorDeviceUuid;
@property (nonatomic, strong) NSString *emrTargetType;
@property (nonatomic, strong) NSString *emrTargetUuid;
@property (nonatomic, strong) NSString *emrTargetHl7Id;
@property (nonatomic, strong) NSString *emrTargetName;
@property (nonatomic, strong) NSString *uploadUuid;
@end

@interface EmrUploadConversationMessageList : NSObject
@property (nonatomic, strong) NSString *conversationUuid;
@property (nonatomic, strong) NSArray *messageUuids;
@end

@interface EmrUploadFile : NSObject
@property (nonatomic, strong) NSString *mime;
@property (nonatomic, strong) NSString *encryptedKey;
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSString *encryptionMethod;
@property (nonatomic, assign) unsigned long size;
@property (nonatomic, strong) NSString *checksum;
@property (nonatomic, strong) NSString *filePath; // Local, for client only
@end

typedef BOOL (^IsCancelledBlock)();

@interface UploadToEmrService : NSObject

+ (EmrUploadParams *) uploadParamsForPatient:(FhirPatient *)patient;

/// isCancelledBlock is optional (can be nil) and should return true if response processing should be cancelled (ie. UI view is already gone)

- (void) uploadConversation:(NSString *)conversationUuid to:(EmrUploadParams *)uploadParams publicKey:(NSString *)publicKey withCompletition:(CompletionBlock)completitionBlock withIsCancelled:(IsCancelledBlock)isCancelledBlock;

- (void) uploadFile:(NSString *)filePath displayFileName:(NSString *)displayFileName thumbnail:(NSString *)thumbnail to:(EmrUploadParams *)uploadParams publicKey:(NSString *)publicKey withCompletition:(CompletionBlock)completitionBlock withIsCancelled:(IsCancelledBlock)isCancelledBlock;

@end
