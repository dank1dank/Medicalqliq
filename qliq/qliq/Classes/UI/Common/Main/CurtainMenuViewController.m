//
//  CurtainMenuViewController.m
//  qliq
//
//  Created by Valerii Lider on 25/12/15.
//
//

#import "CurtainMenuViewController.h"

#import "UserSessionService.h"
#import "QliqConnectModule.h"

#import "MainSettingsViewController.h"
#import "SettingsPresenceViewController.h"
#import "ProfileViewController.h"
#import "InviteContactsViewController.h"
#import "SendToNonQliqUserViewController.h"
#import "SelectContactsViewController.h"
#import "QliqSignViewController.h"
#import "Login.h"

#import "FaxViewController.h"
#import "SelectPDFViewController.h"
#import "QliqSignHelper.h"
#import "MediaFile.h"
#import "QliqSignHelper.h"
#import "QliqSignViewController.h"
#import "AlertController.h"


#import "UIDevice-Hardware.h"

#define kCurtainMenuDefaultCellReuseId @"CurtainMenuDefaultCellReuseId"

typedef NS_ENUM(NSInteger, CurtainMenuItem) {
    CurtainMenuItemChangePresence,
    CurtainMenuItemInviteContacts,
    CurtainMenuItemTextNonQliqUser,
    CurtainMenuItemOnCallSchedules,
    CurtainMenuItemSnapAndSign,
    CurtainMenuItemSnapAndFax,
//    CurtainMenuItemProfile,
    CurtainMenuItemSettings,
    CurtainMenuItemLogout,
    CurtainMenuItemCount,
    CurtainMenuItemViewPatient
};

@interface CurtainMenuViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *profileView;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *presenceStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@property (strong, nonatomic) QSPagesViewController *pagesViewController;
@property (strong ,nonatomic) QSPDFPreviewController *pdfPreviewController;
@property (strong, nonatomic) QliqSignHelper *qliqSignHelper;
@property (strong, nonatomic) QSImagePickerController *imagePicker;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *avatarImageViewWidthConstraint;

@end

@implementation CurtainMenuViewController

- (void)dealloc {
    
    self.profileView = nil;
    self.versionLabel = nil;
    self.avatarImageView = nil;
    self.presenceStatusLabel = nil;
    self.nameLabel = nil;
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView = nil;
    self.avatarImageViewWidthConstraint = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.tableFooterView = [[ UIView alloc ] initWithFrame:CGRectZero];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(configureProfileView)
                                                 name:PresenceChangeStatusNotification
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(checkAvatar:)
                                                 name:@"UserHasChangeAvatar"
                                               object: nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self configureProfileView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private

- (PresenceStatus)getPresenceStatus:(NSString *)type
{
    PresenceStatus presenceStatus = OfflinePresenceStatus;
    
    if ([type isEqualToString: PresenceTypeAway])
        presenceStatus = AwayPresenceStatus;
    else if ([type isEqualToString:PresenceTypeDoNotDisturb] || [type isEqualToString: @"do not disturb"])
        presenceStatus = DoNotDisturbPresenceStatus;
    else if ([type isEqualToString:PresenceTypeOnline])
        presenceStatus = OnlinePresenceStatus;
    
    return presenceStatus;
}

- (void)configureProfileView {
    QliqUser *user = [UserSessionService currentUserSession].user;
    
    //set version
    self.versionLabel.text = [NSString stringWithFormat:@"v%@", [QliqHelper currentVersion]];
    
    //set avatar
    self.avatarImageView.image = [[QliqAvatar sharedInstance] getAvatarForItem:user withTitle:nil];
    self.avatarImageView.layer.masksToBounds = YES;
    self.avatarImageView.layer.cornerRadius = self.avatarImageViewWidthConstraint.constant/2;
    
    UITapGestureRecognizer *tapAvatarGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openUserProfile:)];
    [self.avatarImageView setUserInteractionEnabled:YES];
    [self.avatarImageView addGestureRecognizer:tapAvatarGestureRecognizer];
    
    //set presence
    NSString *presenceType = [[[QliqAvatar sharedInstance] getSelfPresenceMessage] lowercaseString];
    PresenceStatus *presenceStatus = [self getPresenceStatus:presenceType];
    UIColor *presenceColor = [[QliqAvatar sharedInstance] colorForPresenceStatus:presenceStatus];
    
    self.presenceStatusLabel.text = [presenceType capitalizedString];
    self.presenceStatusLabel.textColor = presenceColor;
    
    //set name
    self.nameLabel.text = [[user nameDescription] stringByAppendingString:@"  >"];
    UITapGestureRecognizer *tapNameGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openUserProfile:)];
    [self.nameLabel setUserInteractionEnabled:YES];
    [self.nameLabel addGestureRecognizer:tapNameGestureRecognizer];
}

- (void)checkAvatar:(NSNotification *)notification {
    
    Contact *contact = [[notification userInfo] objectForKey:@"contact"];
    if ([[UserSessionService currentUserSession].user.qliqId isEqualToString:contact.qliqId]) {
        dispatch_async_main(^{
            [self configureProfileView];
        });
    }
}

- (void)didSelectInvite {
    
    NSString *deviceType = NSStringFromUIDeviceFamily([UIDevice currentDevice].deviceFamily);
    NSString *fromiPhoneContacts = QliqFormatLocalizedString1(@"1032-TextFrom{DeviceName}Contacts", deviceType);
    NSString *byEmailOrPhone = NSLocalizedString(@"1033-TextInviteBy", nil);
    
    [AlertController showAlertWithTitle:QliqLocalizedString(@"1029-TextInviteColleagues")
                                message:nil
                       withTitleButtons:@[fromiPhoneContacts,byEmailOrPhone]
                      cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                             completion:^(NSUInteger buttonIndex) {
                                 switch (buttonIndex) {
                                     case 0: {
                                         SelectContactsViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([SelectContactsViewController class])];
                                         controller.typeController = STForInviting;
                                         [self.navigationController pushViewController:controller animated:YES];
                                     }
                                         break;
                                     case 1:{
                                         InviteContactsViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([InviteContactsViewController class])];
                                         [self.navigationController pushViewController:controller animated:YES];
                                     }
                                     case 2:{
                                         [self dismissViewControllerAnimated:YES completion:nil];
                                     }
                                     default:
                                         break;
                                 }
                             }];
}

- (void)openUserProfile:(UITapGestureRecognizer*)tapGestureRecognizer
{
    NSArray *controllers = [self.navigationController viewControllers];
    if (![controllers.lastObject isKindOfClass:[ProfileViewController class]]) {
        ProfileViewController *controller = [kSettingsStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ProfileViewController class])];
        [self.navigationController pushViewController:controller animated:YES];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kShowCurtainViewNotification object:[NSNumber numberWithBool:NO]];
    }
}

#pragma mark - UITableViewDelegate/DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return CurtainMenuItemCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *reuseIdentifire = kCurtainMenuDefaultCellReuseId;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifire];
    cell.textLabel.numberOfLines = 1;
    
    CurtainMenuItem type = indexPath.row;
    switch (type) {
        case CurtainMenuItemChangePresence: {
            cell.textLabel.text = QliqLocalizedString(@"2099-TitleChangePresence");
            break;
        }
        case CurtainMenuItemInviteContacts: {
            cell.textLabel.text = QliqLocalizedString(@"2100-TitleInviteContacts");
            break;
        }
        case CurtainMenuItemTextNonQliqUser: {
            cell.textLabel.text = QliqLocalizedString(@"2101-TitleTextNon-QliqUser");
            break;
        }
        case CurtainMenuItemOnCallSchedules: {
            cell.textLabel.text = QliqLocalizedString(@"2102-TitleOnCallSchedules");
            break;
        }
        case CurtainMenuItemSnapAndSign: {
            cell.textLabel.text = QliqLocalizedString(@"2420-TitleSnapAndSign");
            break;
        }
        case CurtainMenuItemSnapAndFax: {
            cell.textLabel.text = QliqLocalizedString(@"24201-TitleSnapAndFax");
            break;
        }

            /*
        case CurtainMenuItemProfile: {
            cell.textLabel.text =  QliqLocalizedString(@"2103-TitleProfile");
            break;
        }
             */
        case CurtainMenuItemSettings: {
            cell.textLabel.text = QliqLocalizedString(@"2104-TitleSettings");
            break;
        }
        case CurtainMenuItemLogout: {
            cell.textLabel.text = QliqLocalizedString(@"2105-TitleLogout");
            break;
        }
        default:
            cell.textLabel.text = @"";
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CurtainMenuItem type = indexPath.row;
    switch (type) {
        case CurtainMenuItemChangePresence: {
            
            SettingsPresenceViewController *viewController = [kSettingsStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([SettingsPresenceViewController class])];
            
            [self.navigationController pushViewController:viewController animated:YES];
            viewController = nil;

            break;
        }
        case CurtainMenuItemInviteContacts: {
            
            SecuritySettings *sSettings = [UserSessionService currentUserSession].userSettings.securitySettings;
            if (!sSettings.personalContacts) {
                
                [AlertController showAlertWithTitle:nil
                                            message:QliqLocalizedString(@"1071-TextFeaureDisabled")
                                        buttonTitle:nil
                                  cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                         completion:nil];

                return;
            }
            
            [self didSelectInvite];
            break;
        }
        case CurtainMenuItemTextNonQliqUser: {
            SecuritySettings *sSettings = [UserSessionService currentUserSession].userSettings.securitySettings;
            if (!sSettings.personalContacts) {
                
                [AlertController showAlertWithTitle:nil
                                            message:QliqLocalizedString(@"1071-TextFeaureDisabled")
                                        buttonTitle:nil
                                  cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                         completion:nil];
                return;
            }
            
            SendToNonQliqUserViewController *viewController = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([SendToNonQliqUserViewController class])];
            
            [self.navigationController pushViewController:viewController animated:YES];
            viewController = nil;
            break;
        }
        case CurtainMenuItemOnCallSchedules: {
            
            BOOL isOnCallGroupsAllowed = [UserSessionService currentUserSession].userSettings.userFeatureInfo.isOnCallGroupsAllowed;
            if (isOnCallGroupsAllowed) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kShowOnCallGroupsNotification object:nil];
            } else {
                [AlertController showAlertWithTitle:nil
                                            message:QliqLocalizedString(@"1220-TextOnCallGroupsNotAllowed")
                                        buttonTitle:nil
                                  cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                         completion:nil];
            }
            break;
        }
        case CurtainMenuItemSnapAndSign: {
            
            QliqSignViewController *qliqSignViewController = [kMainStoryboard instantiateViewControllerWithIdentifier:@"QliqSignViewController"];
            [self.navigationController pushViewController:qliqSignViewController animated:YES];
            qliqSignViewController = nil;
            
            break;
        }
        case CurtainMenuItemSnapAndFax: {
            
            BOOL isFaxIntegrated = [UserSessionService currentUserSession].userSettings.userFeatureInfo.isFAXIntegated;

            if (isFaxIntegrated) {
                
                FaxViewController *faxViewController = [kMainStoryboard instantiateViewControllerWithIdentifier:@"FaxViewController"];
                [self.navigationController pushViewController:faxViewController animated:YES];
                faxViewController = nil;
            } else {
                
                DDLogSupport(@"\n\nFAX Integration Not Activated...\n\n");
                
                [AlertController showAlertWithTitle:nil
                                            message:QliqLocalizedString(@"3059-TextFAXNotActivate")
                                        buttonTitle:nil
                                  cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                         completion:nil];
            }
            
            break;
        }
            /*
        case CurtainMenuItemProfile: {
            
            ProfileViewController *controller = [kSettingsStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ProfileViewController class])];
            [self.navigationController pushViewController:controller animated:YES];
            controller = nil;
            break;
        }
             */
        case CurtainMenuItemSettings: {
            
            MainSettingsViewController *controller = [kSettingsStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([MainSettingsViewController class])];
            [self.navigationController pushViewController:controller animated:YES];
            controller = nil;
            
            break;
        }
        case CurtainMenuItemLogout: {
            
            [AlertController showAlertWithTitle:QliqLocalizedString(@"1072-TextWarning")
                                        message:QliqLocalizedString(@"1073-TextAskDoYouWantLogout")
                               withTitleButtons:@[QliqLocalizedString(@"3-ButtonYES")]
                              cancelButtonTitle:QliqLocalizedString(@"2-ButtonNO")
                                     completion:^(NSUInteger buttonIndex) {
                                         if (buttonIndex == 0) {
                                             [[Login sharedService] startLogoutWithCompletition:nil];
                                         }
                                     }];
            break;
        }
        default:
            break;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kShowCurtainViewNotification object:[NSNumber numberWithBool:NO]];
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end
