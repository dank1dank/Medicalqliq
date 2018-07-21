//
//  QliqAvatar.h
//  qliq
//
//  Created by Valerii Lider on 2/11/15.
//
//

#import <Foundation/Foundation.h>
#import "UserSession.h"

typedef NS_ENUM(NSInteger, MessageAttachmentType) {
    MessageAttachmentTypeNone,
    MessageAttachmentTypeImage,
    MessageAttachmentTypeVideo,
    MessageAttachmentTypeDoc,
    MessageAttachmentTypeAudio
};

typedef NS_ENUM(NSInteger, ImageQuality) {
    ChoosedQualityOriginal  = 3,
    ChoosedQualityHight     = 2,
    ChoosedQualityMedium    = 1,
    ChoosedQualityLow       = 0
};

typedef NS_ENUM(NSInteger, VideoQuality) {
    OptimalQuality  = 1,
    HighQuality     = 0
};

typedef NS_ENUM (NSInteger, RecipientType) {
    RecipientTypeUnknown = 0,
    RecipientTypeContact = 1,
    RecipientTypeQliqUser = 2,
    RecipientTypeQliqGroup = 3,
    RecipientTypeOnCallGroup = 4,
    RecipientTypePersonalGroup = 5,
    RecipientTypeFhirPatient = 6
};

typedef void (^RemoveBlock)(void);

@class ChatMessage, MediaFile;

@interface QliqAvatar : NSObject

@property (nonatomic, strong) MediaFile* mediaFile;

+ (QliqAvatar *)sharedInstance;

//Helpers
- (RecipientType)returnRecipientType:(id)recipient;
- (id)contactIsQliqUser:(id)enterContact;
- (CGSize)getWidthForLabel:(UILabel*)label;

//Quality
- (void)chooseVideoQualityInView:(UIView*)view withCompletitionBlock:(void(^)(VideoQuality quality))completeBlock;
- (void)chooseQualityInView:(UIView *)view forImage:(UIImage *)image attachment:(BOOL)isAttachment withCompletitionBlock:(void(^)(ImageQuality quality))completeBlock;
- (void)setVideoQuality:(VideoQuality)quality forImagePicker:(UIImagePickerController*)imagePicker;
- (CGFloat)scaleForQuality:(ImageQuality)quality;
- (NSUInteger)estimatedFileSizeOfImage:(UIImage *) image andQuality:(ImageQuality)quality attachment:(BOOL)isAttachment;

//ChatMessage
- (MessageAttachmentType)getMessageAttachmentType:(ChatMessage*)message;

//Contacts
- (NSArray*)reloadContactswithContacts:(NSArray*)globalContacts andWithSearchString:(NSString*)filter;
- (NSArray*)reloadContactswithInvitations:(NSArray*)globalContacts andWithSearchString:(NSString*)filter;


//Presence
- (UIColor *)colorForPresenceStatus:(PresenceStatus)status;
- (UIColor *)colorShadowForPresenceStatus:(PresenceStatus)status;
- (NSString*)getPrecenseStatusMessage:(QliqUser*)user;
- (NSString*)getSelfPresenceMessage;


//Avatars
/**
 Main method for getting avatar for All types in qliq Program
 */
- (UIImage *)getAvatarForItem:(id)item withTitle:(NSString *)title;
- (UIImage *)getDefaultAvatarFromFirstLetters:(NSArray *)firstLetters;
- (UIImage*)makeAvatarWithLetter:(NSString *)name;


- (BOOL)convertVideo:(NSURL *)videoUrl usingBlock:(void (^)(NSURL *convertedVideoUrl, BOOL completed, RemoveBlock block ))callbackBlock;

@end
