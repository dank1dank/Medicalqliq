//
//  QliqAvatar.m
//  qliq
//
//  Created by Valerii Lider on 2/11/15.
//
//

#import "QliqAvatar.h"

#import <AVFoundation/AVFoundation.h>

#import "QliqGroup.h"
#import "Contact.h"
#import "QliqUser.h"
#import "ContactList.h"
#import "Invitation.h"
#import "ChatMessage.h"
#import "OnCallGroup.h"
#import "Recipient.h"
#import "Recipients.h"

#import "Presence.h"
#import "PresenceSettings.h"

#import "FhirResources.h"
/**
 Extension
 */
#import "NSString+Filesize.h"
#import "AlertController.h"
/**
 Services
 */
#import "UserSessionService.h"
#import "ContactAvatarService.h"
#import "QliqListService.h"
#import "QliqUserDBService.h"
#import "MediaFileService.h"
#import "MessageAttachment.h"


/**
 Key
 */
#define kKeySectionTitle    @"SectionTitle"
#define kKeyRecipients      @"Contacts"


/**
 Color
 */
#define kPresenceStatusColorAway    RGBa(245.f, 128.f, 37.f, 1.f)
#define kPresenceStatusColorDnd     RGBa(247.f, 0, 0, 1.f)
#define kPresenceStatusColorOnline  RGBa(29.f, 204.f, 0, 1.f);
#define kPresenceStatusColorOffline RGBa(171.f, 171.f, 171.f, 1.f)
#define kPresenceStatusColorPagerOnly  RGBa(0.f, 0.f, 68.0, 1.f);

#define kPresenceStatusColorShadowAway    RGBa(163.f, 105.f, 11.f, 1.f)
#define kPresenceStatusColorShadowDnd     RGBa(174.f, 22.f, 16.f, 1.f)
#define kPresenceStatusColorShadowOnline  RGBa(80.f, 124.f, 39.f, 1.f);
#define kPresenceStatusColorShadowOffline RGBa(122.f, 122.f, 122.f, 1.f)
#define kPresenceStatusColorShadowPagerOnly  RGBa(0.f, 0.f, 68.0, 1.f)


@implementation QliqAvatar

+ (QliqAvatar *)sharedInstance
{
    static QliqAvatar *instance = nil;
    if (instance == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            instance = [[QliqAvatar alloc]init];
        });
    }
    return instance;
}

#pragma mark - Public -

- (RecipientType)returnRecipientType:(id)recipient {
    RecipientType type = RecipientTypeUnknown;
    
    if ([recipient isKindOfClass:[QliqUser class]]) {
        type = RecipientTypeQliqUser;
    }
    else if ([recipient isKindOfClass:[Contact class]]) {
        type = RecipientTypeContact;
    }
    else if ([recipient isKindOfClass:[OnCallGroup class]]) {
        type = RecipientTypeOnCallGroup;
    }
    else if ([recipient isKindOfClass:[QliqGroup class]]) {
        type = RecipientTypeQliqGroup;
    }
    else if ([recipient isKindOfClass:[ContactList class]]) {
        type = RecipientTypePersonalGroup;
    }
    else if ([recipient isKindOfClass:[FhirPatient class]]) {
        type = RecipientTypeFhirPatient;
    }
    else {
        DDLogSupport(@"Get Unknown Type");
    }
    
    return type;
}

//For quickly copyPast
/*
 RecipientType type = [[QliqAvatar sharedInstance]returnRecipientType:<#(id)#>];
 switch (type) {
 case RecipientTypeOnCallGroup: {
 
 break;
 }
 case RecipientTypeQliqGroup: {
 
 break;
 }
 case RecipientTypePersonalGroup: {
 
 break;
 }
 case RecipientTypeQliqUser: {
 
 break;
 }
 case RecipientTypeContact: {
 
 break;
 }
 default: {
 break;
 }
 } 
 */

- (CGSize)getWidthForLabel:(UILabel*)label
{
    CGSize size = CGSizeZero;
    
    UILabel *localLabel = [[ UILabel alloc ] init];
    localLabel.frame = CGRectMake(0, 0, CGFLOAT_MAX, label.bounds.size.height);
    localLabel.text = label.text;
    localLabel.font = label.font;
    localLabel.numberOfLines = NSIntegerMax;
    localLabel.lineBreakMode = NSLineBreakByWordWrapping;
    localLabel.opaque = NO;
    [localLabel sizeToFit];
    
    size = localLabel.frame.size;
    
    return  size;
}


#pragma mark - Diferent -

#pragma mark Contacts

- (NSArray*)reloadContactswithInvitations:(NSArray*)globalContacts andWithSearchString:(NSString*)filter
{
    NSMutableArray *content = [NSMutableArray new];
    
    filter = filter ? filter : @"";
    
    NSArray *contacts   = globalContacts;
    
    //    contacts = [contacts sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES],
    //                                                       [NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES]]];
    
    [contacts enumerateObjectsUsingBlock:^(Invitation *invitation, NSUInteger idx, BOOL *stop) {
        
        id contact = invitation.contact;
        
        if (invitation.contact.contactType == ContactTypeQliqUser)
        {
            QliqUser * user = [[QliqUserDBService sharedService] getUserForContact:invitation.contact];
            if (user)
                contact = user;
        }
        
        BOOL contactIsQliqUser = [contact isKindOfClass:[QliqUser class]];
        
        NSString *firstName     = ((Contact*)contact).firstName     ? ((Contact*)contact).firstName     : @"";
        NSString *lastName      = ((Contact*)contact).lastName      ? ((Contact*)contact).lastName      : @"";
        NSString *profession    = contactIsQliqUser     ? (((QliqUser*)contact).profession ? ((QliqUser*)contact).profession : @"") : @"";
        
        if ([filter isEqualToString:@""])
        {
            [content addObject:invitation];
        }
        else
        {
            if (NSNotFound != [[NSString stringWithFormat:@"%@ %@ %@", firstName,  lastName,   profession] rangeOfString:filter options:
                               NSCaseInsensitiveSearch].location ||
                NSNotFound != [[NSString stringWithFormat:@"%@ %@ %@", lastName,   firstName,  profession] rangeOfString:filter options:NSCaseInsensitiveSearch].location ||
                NSNotFound != [[NSString stringWithFormat:@"%@ %@ %@", profession, lastName,   firstName]  rangeOfString:filter options:NSCaseInsensitiveSearch].location ||
                NSNotFound != [[NSString stringWithFormat:@"%@ %@ %@", profession, firstName,  lastName]   rangeOfString:filter options:NSCaseInsensitiveSearch].location ||
                NSNotFound != [[NSString stringWithFormat:@"%@ %@ %@", firstName,  profession, lastName]   rangeOfString:filter options:NSCaseInsensitiveSearch].location ||
                NSNotFound != [[NSString stringWithFormat:@"%@ %@ %@", lastName,   profession, firstName]  rangeOfString:filter options:NSCaseInsensitiveSearch].location)
            {
                [content addObject:invitation];
            }
        }
    }];
    
    return content;
}

- (NSArray*)reloadContactswithContacts:(NSArray*)globalContacts andWithSearchString:(NSString*)filter
{
    NSMutableArray *content = [NSMutableArray new];
    
    filter = filter ? filter : @"";
    
    NSArray *contacts   = globalContacts;
    
    contacts = [contacts sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES],
                                                       [NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES]]];
    
    [contacts enumerateObjectsUsingBlock:^(QliqUser *contact, NSUInteger idx, BOOL *stop) {
        
        BOOL contactIsQliqUser = [contact isKindOfClass:[QliqUser class]];
        
        NSString *firstName     = contact.firstName     ? contact.firstName     : @"";
        NSString *lastName      = contact.lastName      ? contact.lastName      : @"";
        NSString *profession    = contactIsQliqUser     ? (contact.profession ? contact.profession : @"") : @"";
        
        
        if ([filter isEqualToString:@""])
        {
            [content addObject:contact];
        }
        else
        {
            if (NSNotFound != [[NSString stringWithFormat:@"%@ %@ %@", firstName,  lastName,   profession] rangeOfString:filter options:
                               NSCaseInsensitiveSearch].location ||
                NSNotFound != [[NSString stringWithFormat:@"%@ %@ %@", lastName,   firstName,  profession] rangeOfString:filter options:NSCaseInsensitiveSearch].location ||
                NSNotFound != [[NSString stringWithFormat:@"%@ %@ %@", profession, lastName,   firstName]  rangeOfString:filter options:NSCaseInsensitiveSearch].location ||
                NSNotFound != [[NSString stringWithFormat:@"%@ %@ %@", profession, firstName,  lastName]   rangeOfString:filter options:NSCaseInsensitiveSearch].location ||
                NSNotFound != [[NSString stringWithFormat:@"%@ %@ %@", firstName,  profession, lastName]   rangeOfString:filter options:NSCaseInsensitiveSearch].location ||
                NSNotFound != [[NSString stringWithFormat:@"%@ %@ %@", lastName,   profession, firstName]  rangeOfString:filter options:NSCaseInsensitiveSearch].location)
            {
                [content addObject:contact];
            }
        }
    }];
    
    //    NSSortDescriptor *sortDeskriptorBySecurityTitle = [NSSortDescriptor sortDescriptorWithKey:kKeySectionTitle ascending:YES];
    //    content = [[content sortedArrayUsingDescriptors:@[sortDeskriptorBySecurityTitle]] mutableCopy];
    
    return content;
}

#pragma mark * ChatMessage

- (MessageAttachmentType)getMessageAttachmentType:(ChatMessage*)message
{
    MessageAttachmentType type = MessageAttachmentTypeNone;
    
    if (message.hasAttachment && message.attachments.count != 0)
    {
        MessageAttachment *attachment = [message.attachments firstObject];
        MediaFileService *sharedService = [MediaFileService getInstance];
        
        //Documents
        if ([sharedService isDocumentFileMime:attachment.mediaFile.mimeType FileName:attachment.mediaFile.encryptedPath])
            type = MessageAttachmentTypeDoc;
        
        //Audio
        else if ([sharedService isAudioFileMime:attachment.mediaFile.mimeType FileName:attachment.mediaFile.encryptedPath])
            type = MessageAttachmentTypeAudio;
        
        //Image
        else if ([sharedService isImageFileMime:attachment.mediaFile.mimeType FileName:attachment.mediaFile.encryptedPath])
            type = MessageAttachmentTypeImage;
        
        //Video
        else if ([sharedService isVideoFileMime:attachment.mediaFile.mimeType FileName:attachment.mediaFile.encryptedPath])
            type = MessageAttachmentTypeNone;
        
        //Anknown
        else
            type = MessageAttachmentTypeNone;
    }
    
    return type;
}

#pragma mark * Verify

- (id)contactIsQliqUser:(id)enterContact
{
    id contact = enterContact;
    
    if ([enterContact isKindOfClass:[Contact class]])
    {
        if (((Contact*)contact).contactType == ContactTypeQliqUser)
        {
            QliqUserDBService *userDBService = [[QliqUserDBService alloc] init];
            QliqUser *qliqUser = [userDBService getUserMinInfoWithContactId:((Contact*)contact).contactId];
            if (qliqUser) {
                contact = qliqUser;
            }
            
        }
    }
    
    return contact;
}
    
#pragma mark - Avatar -
///TODO: need to refactor
- (UIImage *)getAvatarForItem:(id)itemInput withTitle:(NSString *)title  {
    UIImage *avatarImage = nil;
    
    if (itemInput == nil && title) {
        NSString *firsLetter = [self getFirstLetter:title];
        avatarImage = [self getDefaultAvatarFromFirstLetters:@[firsLetter]];

        return  avatarImage;
    }
    
    //Chek if recients have only one recipient
    id item = [self getItemFromRecipients:itemInput];
    
    RecipientType type = [self returnRecipientType:item];
    switch (type) {
        case RecipientTypeOnCallGroup: {
            
            OnCallGroup *onCallGroup = item;
            
            NSString *firsLetter = [self getFirstLetter:onCallGroup.name];
            avatarImage = [self getDefaultAvatarFromFirstLetters:@[firsLetter]];
            
            break;
        }
        case RecipientTypeQliqGroup: {
            
            QliqGroup *qliqGroup = item;
            
//            NSArray *recipients = [[QliqGroupDBService sharedService] getUsersOfGroup:qliqGroup withLimit:4];
          
//            if (recipients.count > 0) {
//                NSArray *firstLetters = [self getFirstLettersForRecipients:recipients];
//                avatarImage = [self getDefaultAvatarFromFirstLetters:firstLetters];
//            }
//            else {
                NSString *firsLetter = [self getFirstLetter:qliqGroup.name];
                avatarImage = [self getDefaultAvatarFromFirstLetters:@[firsLetter]];
//            }
            
            
            break;
        }
        case RecipientTypePersonalGroup: {
            
            ContactList *personalGroup = item;
            
            NSArray *recipients = [[QliqListService sharedService] getContactsAndUsersOfList:personalGroup withLimit:4];
            if (recipients.count > 0) {
                NSArray *firstLetters = [self getFirstLettersForRecipients:recipients];
                avatarImage = [self getDefaultAvatarFromFirstLetters:firstLetters];
            }
            else {
                NSString *firsLetter = [self getFirstLetter:personalGroup.name];
                avatarImage = [self getDefaultAvatarFromFirstLetters:@[firsLetter]];
            }
            
            break;
        }
        case RecipientTypeQliqUser:
        case RecipientTypeContact: {
            
            QliqUser *user = item;
            
            avatarImage = [[ContactAvatarService sharedService] getAvatarForContact:user];
            
            if (avatarImage == nil) {
                NSArray *firstLetters = [self getFirstLettersForRecipients:@[user]];
                avatarImage = [self getDefaultAvatarFromFirstLetters:firstLetters];
            }
            
            break;
        }
        case RecipientTypeFhirPatient:
        {
            FhirPatient *patient = item;
            
//            avatarImage = [[ContactAvatarService sharedService] getAvatarForContact:patient];
                if (patient.photoData) {
                avatarImage = [UIImage imageWithData:patient.photoData];
            }
            
            if (avatarImage == nil) {
                NSArray *firstLetters = [self getFirstLettersForRecipients:@[patient]];
                avatarImage = [self getDefaultAvatarFromFirstLetters:firstLetters];
            }

            break;
        }
        default: {
            if ([item isKindOfClass:[NSArray class]]) {
                
                NSArray *recipients = item;
                
                if (recipients.count > 0) {
                    NSArray *firstLetters = [self getFirstLettersForRecipients:recipients];
                    avatarImage = [self getDefaultAvatarFromFirstLetters:firstLetters];
                }
            }
            else if ([item isKindOfClass:[Recipients class]]){

                Recipients *recipientsObject = item;
                
                NSArray *recipients = [recipientsObject allRecipients];
                if (recipients.count > 0) {
                    NSArray *firstLetters = [self getFirstLettersForRecipients:recipients];
                    avatarImage = [self getDefaultAvatarFromFirstLetters:firstLetters];
                }
                else {
                    NSString *firsLetter = [self getFirstLetter:recipientsObject.name];
                    avatarImage = [self getDefaultAvatarFromFirstLetters:@[firsLetter]];
                }
            }
            
            break;
        }
    }
    
    if (!avatarImage) {
        avatarImage = [UIImage imageNamed:@"avatar_default_blue"];
    }
    
    return avatarImage;
}

#pragma mark * Helpers

- (NSString *)getFirstLetter:(NSString *)name {
    NSString *firstLetter = @"?";
    
    if (name && name.length >= 1) {
        firstLetter = [[name substringToIndex:1] uppercaseString];
    }
    return firstLetter;
}

- (NSArray *)getFirstLettersForRecipients:(NSArray *)recipments
{
    NSArray *array = nil;
    
    if (recipments && recipments.count > 0)
    {
        NSMutableArray *firstLettersArray = [NSMutableArray new];
        
        for (id item in recipments)
        {
            if (firstLettersArray.count >= 4)
                break;
            
            NSString *name = @"";
            
            if ([item isKindOfClass:[Contact class]]) {
                name = [(Contact *)item nameDescription];
            }
            else if ([item isKindOfClass:[QliqUser class]]) {
                name = [(QliqUser *)item nameDescription];
            }
            else if([item isKindOfClass:[FhirPatient class]])
            {
                FhirPatient *patient = item;
                name = patient.fullName;
            }
            
            name = [self getFirstLetter:name];
            
            [firstLettersArray addObject:name];
        }
        
        array = [NSArray arrayWithArray:firstLettersArray];
    }
    
    return array;
}

#pragma mark * GetAvatar

- (id)getItemFromRecipients:(id)item {
    id itemType = item;
    
    
    NSArray *recipients = [NSArray new];
    
    if ([item isKindOfClass:[NSArray class]]) {
        recipients = item;
    }
    else if ([item isKindOfClass:[Recipients class]]){
        recipients = [(Recipients *)item allRecipients];
    }

    if (recipients.count == 1) {
        itemType = [recipients firstObject];
    }
    
    return itemType;
}

- (UIImage *)getDefaultAvatarFromFirstLetters:(NSArray *)firstLetters {
    UIImage *defaultAvatarImage = nil;
    
    if (firstLetters.count > 0) {
        NSString *fileName = @"avatar_";
        
        for (NSString *string in firstLetters) {
            NSAssert([string isKindOfClass:[NSString class]], @"Array should have all string type %@", firstLetters);
            
            fileName = [fileName stringByAppendingString:string];
        }
        
        NSString *pathToFile = [self pathToFile:fileName];
        
        if ([self fileExist:pathToFile]) {
            defaultAvatarImage = [self getImageFromPath:pathToFile];
        }
        else {
            defaultAvatarImage = [self createAvatarForFirstLetters:firstLetters];
            [self saveAvatar:defaultAvatarImage toPath:pathToFile];
        }
    }
    
    return defaultAvatarImage;
}

- (UIImage *)getAvatarForRecipients:(NSArray *)recipients {
    UIImage *recipientsAvatarImage = nil;
    
    if (recipients.count > 0) {
        
        NSString *fileName = @"chat_avatar_";
        
        NSArray *firstLetters = [self getFirstLettersForRecipients:recipients];
        
        for (NSString *string in firstLetters) {
            NSAssert([string isKindOfClass:[NSString class]], @"Array should have all string type %@", firstLetters);
            
            fileName = [fileName stringByAppendingString:string];
        }
        
        NSString *pathToFile = [self pathToFile:fileName];
        
        if ([self fileExist:pathToFile]) {
            recipientsAvatarImage = [self getImageFromPath:pathToFile];
        }
        else {
            recipientsAvatarImage = [self createAvatarForRecipients:recipients];
            [self saveAvatar:recipientsAvatarImage toPath:pathToFile];
        }
    }
    
    return recipientsAvatarImage;
}

#pragma mark * Avatar FileManager

- (NSString*)pathToFile:(NSString *)fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *basePath = [paths count] > 0 ? [paths objectAtIndex:0] : nil;
    NSString *path = [basePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", fileName]];
    
    return path;
}

- (BOOL)fileExist:(NSString*)path
{
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path];
    return fileExists;
}

- (UIImage *)getImageFromPath:(NSString *)path
{
    UIImage *image = nil;
    NSData *binaryImageData = [NSData dataWithContentsOfFile:path];
    
    if (binaryImageData)
        image = [UIImage imageWithData:binaryImageData];
    
    return image;
}

- (void)saveAvatar:(UIImage *)avatar toPath:(NSString *)path
{
    NSData *binaryImageData = UIImagePNGRepresentation(avatar);
    [binaryImageData writeToFile:path atomically:YES];
}

- (long)fileSize:(NSString*)pathToFile
{
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:pathToFile error:nil];
    NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
    long long fileSize = [fileSizeNumber longLongValue];
    
    return fileSize;
}

#pragma mark * Create Avatar

///TODO: need to refactor
- (UIImage*)createAvatarForFirstLetters:(NSArray *)firstLetters {
    UIImage *avatarImage = nil;
    
    UIView *renderView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, 60.f, 60.f)];
    renderView.backgroundColor = [UIColor whiteColor];
    renderView.clipsToBounds = YES;
    
    switch (firstLetters.count) {
        case 1: {
            avatarImage = [self makeAvatarWithLetter:firstLetters[0]];
            break;
        }
        case 2: {
            //First Letter
            {
                UIView *firstView = [[UIView alloc] initWithFrame:CGRectMake(-1.f, 0.f, 30.f, 60.f)];
                firstView.center = CGPointMake(firstView.center.x, renderView.frame.size.height/2.f);
                firstView.clipsToBounds = YES;
                [renderView addSubview:firstView];
                
                UIImageView *firstImage = [[UIImageView alloc] initWithImage:[self makeAvatarWithLetter:firstLetters[0] ]];
                firstImage.frame = CGRectMake(0, 0.f, 60.f, 60.f);
                firstImage.center = CGPointMake(firstView.frame.size.width/2, firstView.center.y);
                firstImage.contentMode = UIViewContentModeScaleToFill;
                [firstView addSubview:firstImage];
            }
            
            //Second Letter
            {
                UIView *lastView = [[UIView alloc] initWithFrame:CGRectMake(renderView.frame.size.width/2 + 1.f, 0.f, 30.f, 60.f)];
                lastView.center = CGPointMake(lastView.center.x , renderView.frame.size.height/2.f);
                lastView.clipsToBounds = YES;
                [renderView addSubview:lastView];
                
                UIImageView *lastImage = [[UIImageView alloc] initWithImage:[self makeAvatarWithLetter:firstLetters[1] ]];
                lastImage.frame = CGRectMake(0.f, 0.f, 60.f, 60.f);
                lastImage.center = CGPointMake(lastView.frame.size.width/2, lastView.center.y);
                lastImage.contentMode = UIViewContentModeScaleToFill;
                [lastView addSubview:lastImage];
            }
            
            avatarImage = [self makeImage:renderView];
            
            break;
        }
        case 3: // In case 3 avatar
        {
            //First letter
            {
                UIImageView *firstImage = [[UIImageView alloc] initWithImage:[self makeAvatarWithLetter:firstLetters[0] ]];
                firstImage.frame = CGRectMake(0.f, 0.f, 30.f, 30.f);
                firstImage.center = CGPointMake(-1.f+15.f, -1.f+15.f);
                firstImage.contentMode = UIViewContentModeScaleToFill;
                [renderView addSubview:firstImage];
            }
            
            //Second letter
            {
                UIImageView *secondImage = [[UIImageView alloc] initWithImage:[self makeAvatarWithLetter:firstLetters[1] ]];
                secondImage.frame = CGRectMake(0.f, 0.f, 30.f, 30.f);
                secondImage.center = CGPointMake(renderView.frame.size.width+1.f-15.f, -1.f+15.f);
                secondImage.contentMode = UIViewContentModeScaleToFill;
                [renderView addSubview:secondImage];
            }
            
            //Third letter
            {
                UIView *thirdView = [[UIView alloc] initWithFrame:CGRectMake(0.f, renderView.frame.size.height/2+1.f, 60.f, 30.f)];
                thirdView.center = CGPointMake(renderView.frame.size.width/2.f, thirdView.center.y);
                thirdView.clipsToBounds = YES;
                [renderView addSubview:thirdView];
                
                UIImageView *thirdImage = [[UIImageView alloc] initWithImage:[self makeAvatarWithLetter:firstLetters[2] ]];
                thirdImage.frame = CGRectMake(0.f, 0.f, 60.f, 60.f);
                thirdImage.center = CGPointMake(thirdView.frame.size.width/2.f, thirdView.frame.size.height/2.f);
                thirdImage.contentMode = UIViewContentModeScaleToFill;
                [thirdView addSubview:thirdImage];
            }
            
            avatarImage = [self makeImage:renderView];
            
            break;
        }
        case 4: // In case 4 avatar
        {
            //First Letter
            {
                UIImageView *firstImage = [[UIImageView alloc] initWithImage:[self makeAvatarWithLetter:firstLetters[0] ]];
                firstImage.frame = CGRectMake(0.f, 0.f, 30.f, 30.f);
                firstImage.center = CGPointMake(- 1.f+15.f, - 1.f+15.f);
                firstImage.contentMode = UIViewContentModeScaleToFill;
                [renderView addSubview:firstImage];
            }
            //Second Letter
            {
                UIImageView *secondImage = [[UIImageView alloc] initWithImage:[self makeAvatarWithLetter:firstLetters[1] ]];
                secondImage.frame = CGRectMake(0.f, 0.f, 30.f, 30.f);
                secondImage.center = CGPointMake(renderView.frame.size.width+1.f-15.f, -1.f+15.f);
                secondImage.contentMode = UIViewContentModeScaleToFill;
                [renderView addSubview:secondImage];
            }
            //Third Letter
            {
                UIImageView *thirdImage = [[UIImageView alloc] initWithImage:[self makeAvatarWithLetter:firstLetters[2] ]];
                thirdImage.frame = CGRectMake(0.f, 0.f, 30.f, 30.f);
                thirdImage.center = CGPointMake(-1.f+15.f, renderView.frame.size.height+1.f-15.f);
                thirdImage.contentMode = UIViewContentModeScaleToFill;
                [renderView addSubview:thirdImage];
            }
            //Forth Letter
            {
                UIImageView *lastImage = [[UIImageView alloc] initWithImage:[self makeAvatarWithLetter:firstLetters[3] ]];
                lastImage.frame = CGRectMake(0.f, 0.f, 30.f, 30.f);
                lastImage.center = CGPointMake(renderView.frame.size.width+1.f-15.f, renderView.frame.size.height+1.f-15.f);
                lastImage.contentMode = UIViewContentModeScaleToFill;
                [renderView addSubview:lastImage];
            }
            
            avatarImage = [self makeImage:renderView];
            
            break;
        }
        default: {
            avatarImage = [self makeAvatarWithLetter:@"?"];
            break;
        }
    }
    
    return avatarImage;
}

- (UIImage*)createAvatarForRecipients:(NSArray *)recipients {
    UIImage *avatarImage = nil;
    
    UIView *renderView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, 60.f, 60.f)];
    renderView.backgroundColor = [UIColor whiteColor];
    renderView.clipsToBounds = YES;
    
    NSMutableArray *recipientsCopy = [recipients mutableCopy];
    NSArray *firsLetters = [self getFirstLettersForRecipients:recipientsCopy];
    
    if (recipientsCopy.count == 1) {
        avatarImage = [[ContactAvatarService sharedService] getAvatarForContact:recipientsCopy[1]];
        return avatarImage;
    }
    
    
    if ([recipientsCopy containsObject:[UserSessionService currentUserSession].user]) {
        [recipientsCopy removeObject:[UserSessionService currentUserSession].user];
    }
    
    for (NSInteger index = 0; index < recipientsCopy.count; index++) {
        
        if (index >= 4) {
            break;
        }
        
        avatarImage = [[ContactAvatarService sharedService] getAvatarForContact:recipientsCopy[index]];
        
        CGRect frameFirstView = CGRectMake(0.f, 0.f, 0.f, 0.f);
        CGRect frameFirstImage = CGRectMake(0.f, 0.f, 0.f, 0.f);
        NSInteger xCenterImage = 0.f;
        NSInteger yCenterImage = 0.f;
        
        UIView *firstView = [[UIView alloc] initWithFrame:frameFirstView];
        
        if (index % 2 == 0) {
            
            if (index == 0) {
                
                if (recipientsCopy.count == 2) {
                    
                    frameFirstView = CGRectMake(-1.f, 0.f, 30.f, 60.f);
                    [firstView setFrame:frameFirstView];
                    firstView.center = CGPointMake(firstView.center.x, renderView.frame.size.height/2.f);
                    frameFirstImage = frameFirstView;
                    xCenterImage = firstView.center.x;
                    yCenterImage =  firstView.center.y;
                }
                else {
                   
                    frameFirstView = CGRectMake(0.f, 0.f, 30.f, 30.f);
                    firstView.center = CGPointMake(renderView.frame.size.width+1.f-15.f, renderView.frame.size.height+1.f-15.f);
                    frameFirstImage = CGRectMake(0.f, 0.f, 30.f, 30.f);
                    xCenterImage = - 1.f+15.f;
                    yCenterImage =  - 1.f+15.f;
                }
            }
            else {
                
                if (index + 1 == recipientsCopy.count) {
                    
                    frameFirstView = CGRectMake(0.f, renderView.frame.size.height/2+1.f, 60.f, 30.f);
                    [firstView setFrame:frameFirstView];
                    firstView.center = CGPointMake(renderView.frame.size.width/2.f, firstView.center.y);
                    frameFirstImage = frameFirstView;
                    xCenterImage = firstView.center.x;
                    yCenterImage = firstView.center.y;
                }
                else {
                    frameFirstView = CGRectMake(0.f, 0.f, 30.f, 30.f);
                    firstView.center = CGPointMake(-1.f+15.f, renderView.frame.size.height+1.f-15.f);
                    frameFirstImage = CGRectMake(0.f, 0.f, 30.f, 30.f);
                    xCenterImage = -1.f+15.f;
                    yCenterImage =  renderView.frame.size.height+1.f-15.f;
                }
            }
        }
        else {
           
            if (index == 1) {
                
                if (index + 1 == recipientsCopy.count) {
                    
                    frameFirstView = CGRectMake(renderView.frame.size.width/2 + 1.f, 0.f, 30.f, 60.f);
                    [firstView setFrame:frameFirstView];
                    firstView.center = CGPointMake(firstView.center.x , renderView.frame.size.height/2.f);
                    frameFirstImage = frameFirstView;
                    xCenterImage = firstView.center.x;
                    yCenterImage =  firstView.center.y;
                }
                else {
                    frameFirstView = CGRectMake(0.f, 0.f, 30.f, 30.f);
                    firstView.center = CGPointMake(renderView.frame.size.width+1.f-15.f, -1.f+15.f);
                    frameFirstImage = CGRectMake(0.f, 0.f, 30.f, 30.f);
                    xCenterImage = renderView.frame.size.width+1.f-15.f;
                    yCenterImage =  -1.f+15.f;
                }
            }
            else {
                
                frameFirstView = CGRectMake(0.f, 0.f, 30.f, 30.f);
                firstView.center = CGPointMake(renderView.frame.size.width+1.f-15.f, renderView.frame.size.height+1.f-15.f);
                frameFirstImage = CGRectMake(0.f, 0.f, 30.f, 30.f);
                xCenterImage = renderView.frame.size.width+1.f-15.f;
                yCenterImage =  renderView.frame.size.height+1.f-15.f;
            }
        }
        
        [firstView setFrame:frameFirstView];;
        
        firstView.clipsToBounds = YES;
        [renderView addSubview:firstView];
        
        UIImageView *firstImage = nil;
        
        avatarImage = [[ContactAvatarService sharedService] getAvatarForContact:recipientsCopy[index]];
        
        if (avatarImage) {
            firstImage = [[UIImageView alloc] initWithImage:avatarImage];
        }
        else {
            firstImage = [[UIImageView alloc] initWithImage:[self makeAvatarWithLetter:firsLetters[index]]];
        }
        
        [firstImage setFrame:frameFirstImage];
        firstImage.center = CGPointMake(xCenterImage, yCenterImage);
        firstImage.contentMode = UIViewContentModeScaleToFill;
        [renderView addSubview:firstImage];
    }
    
    avatarImage = [self makeImage:renderView];
    
    return avatarImage;
}

- (UIImage*)makeAvatarWithLetter:(NSString *)name
{
    UIView *renderView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, 60.f, 60.f)];
    renderView.backgroundColor  = [UIColor whiteColor];
    renderView.clipsToBounds    = YES;
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, 80.f, 80.f)];
    view.backgroundColor = kColorAvatarBackground;
    
    NSString *firstLetter = [self getFirstLetter:name];
    
    UILabel *letterLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.f, 0.f, 60.f, 60.f)];
    letterLabel.textAlignment   = NSTextAlignmentCenter;
    letterLabel.font            = [UIFont fontWithName:letterLabel.font.fontName size:40.f];
    letterLabel.textColor       = kColorAvatarTittle;
    letterLabel.text            = firstLetter;
    
    [view addSubview:letterLabel];
    [renderView addSubview:view];
    
    return [self makeImage:renderView];
}

- (UIImage *)makeImage:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage * viewImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return viewImage;
}

#pragma mark - Check Image/Video Quately -

- (void)chooseVideoQualityInView:(UIView*)view withCompletitionBlock:(void(^)(VideoQuality quality))completeBlock
{
    NSString * high     = [NSString stringWithFormat:NSLocalizedString(@"39-ButtonHighQuality", nil)];
    NSString * optimal  = [NSString stringWithFormat:NSLocalizedString(@"40-ButtonOptimalQuality", nil)];
    
    [AlertController showActionSheetAlertWithTitle:NSLocalizedString(@"1167-TextChooseVideoQuality", nil)
                                           message:nil
                                  withTitleButtons:@[high, optimal]
                                 cancelButtonTitle:NSLocalizedString(@"4-ButtonCancel", nil)
                                        completion:^(NSUInteger buttonIndex) {
                                            if (buttonIndex != 2) {
                                                if (completeBlock)
                                                    completeBlock(buttonIndex);
                                            }
                                        }];
}

- (void)chooseQualityInView:(UIView *)view forImage:(UIImage *)image attachment:(BOOL)isAttachment withCompletitionBlock:(void(^)(ImageQuality quality))completeBlock {
    
    NSUInteger estimatedSmall, estimatedMedium, estimatedLarge, estimatedActual;
    
    estimatedActual = [self estimatedFileSizeOfImage:image andQuality:ChoosedQualityOriginal attachment:isAttachment];
    estimatedSmall  = [self estimatedFileSizeOfImage:image andQuality:ChoosedQualityLow      attachment:isAttachment];
    estimatedMedium = [self estimatedFileSizeOfImage:image andQuality:ChoosedQualityMedium   attachment:isAttachment];
    estimatedLarge  = [self estimatedFileSizeOfImage:image andQuality:ChoosedQualityHight    attachment:isAttachment];

    NSString * originalTitle = [NSString stringWithFormat:@"%@ (%@)", NSLocalizedString(@"2016-TitleActualSize", nil),[NSString fileSizeFromBytes:estimatedActual]];

    NSString * mediumTitle =   [NSString stringWithFormat:@"%@ (%@)", NSLocalizedString(@"2017-TitleMedium", nil),    [NSString fileSizeFromBytes:estimatedMedium]];

    NSString * largeTitle =    [NSString stringWithFormat:@"%@ (%@)", NSLocalizedString(@"2018-TitleLarge", nil),     [NSString fileSizeFromBytes:estimatedLarge]];

    NSString * smallTitle =    [NSString stringWithFormat:@"%@ (%@)", NSLocalizedString(@"2019-TitleSmall", nil),     [NSString fileSizeFromBytes:estimatedSmall]];
    
    UIActionSheet_Blocks * actionSheet = [[UIActionSheet_Blocks alloc] initWithTitle:NSLocalizedString(@"1168-TextChooseImageQuality", nil)
                                                                   cancelButtonTitle:NSLocalizedString(@"4-ButtonCancel", nil)
                                                                   otherButtonTitles:[NSArray arrayWithObjects:smallTitle, mediumTitle, largeTitle, originalTitle, nil]];
    [actionSheet showInView:view block:^(UIActionSheetAction action,NSUInteger buttonIndex) {
        
        if (action == UIActionSheetActionWillDissmiss && buttonIndex != actionSheet.cancelButtonIndex)
            if (completeBlock) completeBlock(buttonIndex);
    }];
}

- (NSUInteger)estimatedFileSizeOfImage:(UIImage *) image andQuality:(ImageQuality)quality attachment:(BOOL)isAttachment {
//    NSInteger size = pow([self scaleForQuality:quality],2) * image.size.width * image.size.height * [self estimatedCompressionForImage:image andQuality:quality];

    NSData * imageData = nil;
    
    if (isAttachment) {
        UIImage *img = [[[MessageAttachment alloc] init] imageFromImage:image scaledTo:[self scaleForQuality:quality]];
        imageData = UIImagePNGRepresentation(img);
        
    } else {
        imageData = UIImageJPEGRepresentation(image, [self scaleForQuality:quality]);
    }
    
    return (CGFloat)imageData.length;
}

//- (CGFloat)estimatedCompressionForImage:(UIImage *) image andQuality:(ImageQuality)quality
//{
//    NSInteger bytesPerPixel = CGImageGetBitsPerPixel(image.CGImage)/8;
//
//    switch (quality)
//    {
//        case ChoosedQualityOriginal:return 0.34 * (bytesPerPixel);      break;
//        case ChoosedQualityHight:   return 0.369198 * (bytesPerPixel);  break;
//        case ChoosedQualityMedium:  return 0.387634 * (bytesPerPixel);  break;
//        case ChoosedQualityLow:     return 0.387888 * (bytesPerPixel);  break;
//
//    }
//}

- (CGFloat)scaleForQuality:(ImageQuality)quality
{
    switch (quality) {
        default:
        case ChoosedQualityOriginal:return 1.0f;    break;
        case ChoosedQualityHight:   return 0.5f;    break;
        case ChoosedQualityMedium:  return 0.25f;   break;
        case ChoosedQualityLow:     return 0.125f;  break;
    }
}

- (void)setVideoQuality:(VideoQuality)quality forImagePicker:(UIImagePickerController*)imagePicker
{
    if (quality == OptimalQuality) {
        [imagePicker setVideoQuality:UIImagePickerControllerQualityTypeLow];
    }
    else {
        [imagePicker setVideoQuality:UIImagePickerControllerQualityTypeMedium];
    }
}

#pragma mark - Presence Status -

- (UIColor *)colorShadowForPresenceStatus:(PresenceStatus)status
{
    UIColor *color = kPresenceStatusColorShadowOffline;
    
    switch (status)
    {
        case AwayPresenceStatus:            color = kPresenceStatusColorShadowAway;   break;
        case DoNotDisturbPresenceStatus:    color = kPresenceStatusColorShadowDnd;    break;
        case OnlinePresenceStatus:          color = kPresenceStatusColorShadowOnline  break;
        case PagerOnlyPresenceStatus:       color = kPresenceStatusColorShadowPagerOnly;    break;
        default: break;
    }
    
    return color;
}

- (UIColor *)colorForPresenceStatus:(PresenceStatus)status
{
    UIColor *color = kPresenceStatusColorOffline;
    
    switch (status)
    {
        case AwayPresenceStatus:            color = kPresenceStatusColorAway;   break;
        case DoNotDisturbPresenceStatus:    color = kPresenceStatusColorDnd;    break;
        case OnlinePresenceStatus:          color = kPresenceStatusColorOnline  break;
        case PagerOnlyPresenceStatus:       color = kPresenceStatusColorPagerOnly break;
        default: break;
    }
    
    return color;
}

- (NSString*)getPrecenseStatusMessage:(QliqUser*)user
{
    NSString *statusText = @"";
    switch (user.presenceStatus)
    {
        case AwayPresenceStatus: {
            statusText = [user.presenceMessage length] > 0 ? user.presenceMessage : QliqLocalizedString(@"2052-TitleAway#presenceType");
            break;
        }
        case DoNotDisturbPresenceStatus: {
            statusText = QliqLocalizedString(@"2051-TitleDnD#presenceType");
            break;
        }
        case OnlinePresenceStatus: {
            
            statusText = QliqLocalizedString(@"2050-TitleOnline#presenceType");
            break;
        }
        case OfflinePresenceStatus: {
            
            statusText = QliqLocalizedString(@"2353-TitleOffline#presenceType");
            break;
        }
        case PagerOnlyPresenceStatus: {
            
            statusText = QliqLocalizedString(@"2369-TitlePagerOnly#presenceType");
            break;
        }
        default: break;
    }
    
    return statusText;
}

- (NSString*)getSelfPresenceMessage
{
    PresenceSettings *presenceSettings = [UserSessionService currentUserSession].userSettings.presenceSettings;
    Presence *presence = [presenceSettings presenceForType:presenceSettings.currentPresenceType];
    
    NSString *statusText = @"Online";

    if ([presenceSettings.currentPresenceType isEqualToString: PresenceTypeAway]) {
        statusText = presence.message.length > 0 ? presence.message : @"Away";
    }
    else if ([presenceSettings.currentPresenceType isEqualToString:PresenceTypeDoNotDisturb]) {
        statusText = /*presence.message.length > 0 ? presence.message : */@"Do not Disturb";
    }
    else if ([presenceSettings.currentPresenceType isEqualToString:PresenceTypeOnline]) {
        statusText = @"Online";
    }
    
    return statusText;
}

#pragma mark - Video Converting -

- (BOOL)convertVideo:(NSURL *)videoUrl usingBlock:(void (^)(NSURL *, BOOL, RemoveBlock block))callbackBlock {
    dispatch_async_main(^{
        [SVProgressHUD showWithStatus:@"Processing Video..."];
    });
    
    AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    
    AVMutableComposition *mixComposition = [AVMutableComposition composition];
    AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                                   preferredTrackID:kCMPersistentTrackID_Invalid];
    AVAssetTrack *clipVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                                   ofTrack:clipVideoTrack
                                    atTime:kCMTimeZero
                                     error:nil];
    [compositionVideoTrack setPreferredTransform:clipVideoTrack.preferredTransform];
    
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *outputPath = [documentsDirectory stringByAppendingString:@"/converteredVideo.mp4"];
    
    NSURL *outputUrl = [NSURL fileURLWithPath:outputPath];
    
    [[NSFileManager defaultManager] removeItemAtURL:outputUrl error:nil];
    
    RemoveBlock removeBlock = ^{
        [[NSFileManager defaultManager] removeItemAtURL:outputUrl error:nil];
    };

    
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:videoAsset
                                                                           presetName:/*AVAssetExportPreset640x480*/AVAssetExportPreset960x540];
    exportSession.timeRange = CMTimeRangeMake(kCMTimeZero, mixComposition.duration);
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.outputURL = outputUrl;
    exportSession.shouldOptimizeForNetworkUse = YES;
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
        
        dispatch_async_main(^{
            if ([SVProgressHUD isVisible]) {
                [SVProgressHUD dismiss];
            }
            
            switch (exportSession.status) {
                case AVAssetExportSessionStatusCompleted: {
                    
                    callbackBlock(outputUrl, YES, removeBlock);
                    break;
                }
                case AVAssetExportSessionStatusFailed: {
                    
                    callbackBlock(nil, NO, removeBlock);
                    //Fail
                    break;
                }
                default: {
                    callbackBlock(nil, NO, removeBlock);
                    break;
                }
            }
        });
    }];
    
    return NO;
}


@end
