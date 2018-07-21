//
//  UploadToQliqStorService.h
//  qliq
//
//  Created by Adam Sowa on 14/04/17.
//
//

#import <Foundation/Foundation.h>
#import "FaxContact.h"

@class MediaFileUpload;

@interface QliqStorUploadParams : NSObject
@property (nonatomic, strong) NSString *uploadUuid;
@property (nonatomic, strong) NSString *qliqStorQliqId;
@property (nonatomic, strong) NSString *qliqStorDeviceUuid;
// FAX uploads
@property (nonatomic, strong) NSString *faxNumber;
@property (nonatomic, strong) NSString *faxVoiceNumber;
@property (nonatomic, strong) NSString *faxOrganization;
@property (nonatomic, strong) NSString *faxContactName;
@property (nonatomic, strong) NSString *faxSubject;
@property (nonatomic, strong) NSString *faxBody;

- (id) initWithFaxContact:(FaxContact *)contact;

@end

typedef BOOL (^IsCancelledBlock)();

@interface UploadToQliqStorService : NSObject

- (void) uploadFile:(NSString *)filePath displayFileName:(NSString *)displayFileName thumbnail:(NSString *)thumbnail to:(QliqStorUploadParams *)uploadParams publicKey:(NSString *)publicKey withCompletion:(CompletionBlock)completionBlock withIsCancelled:(IsCancelledBlock)isCancelledBlock;

- (void) reuploadFile:(MediaFileUpload *)upload publicKey:(NSString *)publicKey withCompletion:(CompletionBlock)completionBlock withIsCancelled:(IsCancelledBlock)isCancelledBlock;

+ (void) processChangeNotification:(NSString *)subject payload:(NSString *)payload;

//- (void) addObserver:(id)observer selector:(SEL)aSelector;

@end
