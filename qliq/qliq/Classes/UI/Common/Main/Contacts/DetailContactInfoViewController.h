//
//  DetailContactInfoViewController.h
//  qliq
//
//  Created by Valerii Lider on 10/21/14.
//
//

#import <UIKit/UIKit.h>
#import "FhirResources.h"

typedef NS_ENUM(NSInteger, DetailInfoContactType) {
    DetailInfoContactTypeContact = 0,
    DetailInfoContactTypeQliqUser,
    DetailInfoContactTypeConversation,
    DetailInfoContactTypeCareChannel,
    DetailInfoContactTypeInvitation,
    DetailInfoContactTypeQliqGroup,
    DetailInfoContactTypePersonalGroup,
    DetailInfoContactTypeFhirPatient,
    DetailInfoContactTypeOnCallMemberNotes,
    DetailInfoContactTypeOnCallDayNotes
};

@protocol DetailContactInfoDelegate <NSObject>

@optional

- (void)editDoneFromCareChannelInfo:(NSMutableArray *)careTeam withRoles:(NSDictionary *)participantsRoles withCompletion:(void (^)())completion;
- (void)editDoneFromConversationInfo:(NSMutableArray *)participants withSubject:(NSString *)subject withCompletion:(void (^)())completion;
@end


@interface DetailContactInfoViewController : UIViewController

@property (nonatomic, weak) id <DetailContactInfoDelegate> delegate;

@property (nonatomic, strong) id contact;

@property (nonatomic, assign) DetailInfoContactType contactType;

@property (nonatomic, strong) NSString *backButtonTitleString;

@end
