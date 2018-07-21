//
//  MainSettingsViewController.m
//  qliq
//
//  Created by Valeriy Lider on 14.11.14.
//
//

#import "MainSettingsViewController.h"
#import "MainSettingsHeaderView.h"
#import "MainSettingsTableViewCell.h"

#import "AppDelegate.h"

#import "ProfileViewController.h"
#import "SettingsPresenceViewController.h"
#import "SettingsSoundViewController.h"
#import "SettingsEscalatedViewController.h"
#import "SettingsSecurityViewController.h"
#import "SettingsSupportViewController.h"
#import "SettingsGeneralViewController.h"

#import "ImageCaptureController.h"

#import "QliqSip.h"

#import "LoginService.h"
#import "Login.h"
#import "KeychainService.h"
#import "AvatarUploadService.h"
#import "QliqConnectModule.h"
#import "QliqUserNotifications.h"

#import "AlertController.h"

typedef enum : NSInteger {
//  SettingsRowBatterySaving,
    SettingsRowNotificationEnable,
    SettingsRowPresence,
    SettingsRowSoundsAndAlets,
    SettingsRowEscalated,
    
    SettingsRowSecurity,
    SettingsRowSupport,
    SettingsRowGeneral,
    SettingsRowSyncAndLogout,
    SettingsRowCount
} SettingsRow;

@interface MainSettingsViewController ()
<
ImageCaptureControllerDelegate,
MainSettingsHeaderViewDelegate,
MainSettingsCellDelegate,
UITableViewDataSource,
UITableViewDelegate
>

@property (weak, nonatomic) IBOutlet UILabel *navigationLeftTitleLabel;


@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet MainSettingsHeaderView *contactHeaderView;

@property (strong, nonatomic) ImageCaptureController *imageCaptureController;

@property (nonatomic, assign) BOOL isAvatarUpdated;

@end

@implementation MainSettingsViewController


- (void)dealloc {
    self.navigationLeftTitleLabel = nil;
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView = nil;
    self.contactHeaderView = nil;
    self.imageCaptureController = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.isAvatarUpdated = YES;
    
    //NabigationBar
    self.navigationLeftTitleLabel.text = QliqLocalizedString(@"100-ButtonSettings");
    
    
    //Header View
    {
        self.contactHeaderView.delegate = self;
    }
    
    //ImageCaptureController
    {
        self.imageCaptureController = [[ImageCaptureController alloc] init];
        self.imageCaptureController.delegate = self;
    }
    
    //Version
    {
        NSString *currentBuildVersion    = [AppDelegate currentBuildVersion];
        NSString *availableVersion  = [appDelegate availableVersion];
        
        if (NSOrderedAscending == [currentBuildVersion compare:availableVersion options:NSNumericSearch] ? 1 : 0)
        {
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:QliqLocalizedString(@"1139-TextNewVersionAvaliable")
                                                                           message:QliqLocalizedString(@"1140-TextDownloadNewVersionFromAppStore")
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *laterAction = [UIAlertAction actionWithTitle:QliqLocalizedString(@"13-ButtonLater")
                                                                  style:UIAlertActionStyleCancel
                                                                handler:nil];
            
            UIAlertAction *downloadAction = [UIAlertAction actionWithTitle:QliqLocalizedString(@"14-ButtonDownloadNow")
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * _Nonnull action) {
                                                                    [appDelegate getNewVersion];
                                                                }];
            [alert addAction:downloadAction];
            [alert addAction:laterAction];
            [self presentViewController:alert animated:YES completion:nil];

        }
    }
    
    //TableView
    {
        self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    }
    
    //Notifications
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(enterForeground)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(checkAvatar:)
                                                     name:@"UserHasChangeAvatar"
                                                   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reShowUpdateActivity:)
                                                     name:SVProgressHUDDidDisappearNotification
                                                   object: nil];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO];
    [self.contactHeaderView fillWithContact:[UserSessionService currentUserSession].user];
    
    //For test
//    [self showSoundSettingsAlert];  
    
    //Alert
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        if ([defaults objectForKey:kShowSoundSettings])
        {
            if ([[defaults objectForKey:kShowSoundSettings] boolValue] == YES)
            {
                [defaults removeObjectForKey:kShowSoundSettings];
                [defaults synchronize];
                [self showSoundSettingsAlert];
            }
            else
            {
                [defaults setBool:YES forKey:kShowSoundSettings];
                [defaults synchronize];
            }
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Notifications -

- (void)enterForeground {
    [self.tableView reloadData];
}

- (void)checkAvatar:(NSNotification *)notification {
    
    Contact *contact = [[notification userInfo] objectForKey:@"contact"];
    if ([[UserSessionService currentUserSession].user.qliqId isEqualToString:contact.qliqId]) {
        dispatch_async_main(^{
            self.contactHeaderView.avatarView.image = [[QliqAvatar sharedInstance] getAvatarForItem:[UserSessionService currentUserSession].user withTitle:nil];
        });
    }
}

- (void)reShowUpdateActivity:(NSNotification *)notification {
    if (!self.isAvatarUpdated) {
        dispatch_async_main(^{
            [SVProgressHUD showProgress:-1 status:NSLocalizedString(@"1915-StatusUpdating", nil) maskType:SVProgressHUDMaskTypeGradient];
        });
    }
}

#pragma mark - Alerts -

- (void)showSoundSettingsAlert
{
    QliqAlertView *alertView = [[QliqAlertView alloc] initWithInverseColor:NO];
    [alertView setContainerViewWithImage:[UIImage imageNamed:@"AlertImageCustomizeNotifications"]
                               withTitle:NSLocalizedString(@"1141-TextCustomizeNotifications", nil)
                                withText:NSLocalizedString(@"1142-TextCustomizeNotificationDescription", nil)
                            withDelegate:nil
                        useMotionEffects:YES];
    [alertView setButtonTitles:[NSMutableArray arrayWithObjects:NSLocalizedString(@"13-ButtonLater", nil), NSLocalizedString(@"3-ButtonYES", nil), nil]];
    [alertView setOnButtonTouchUpInside:^(QliqAlertView *alertView, int buttonIndex) {
        
        if (buttonIndex != 0)
        {
            UserSettings * userSettings = [UserSessionService currentUserSession].userSettings;
            
            SettingsSoundViewController *soundsController = [kSettingsStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([SettingsSoundViewController class])];
            soundsController.soundSettings = userSettings.soundSettings;
            [self.navigationController pushViewController:soundsController animated:YES];
        }
    }];
    [alertView show];
}

#pragma mark - Private Methods

- (void)saveAvatar:(UIImage *)image {
    DDLogSupport(@"Save Avatar");
    self.isAvatarUpdated = NO;
    
    dispatch_async_main(^{
        [SVProgressHUD showProgress:-1 status:NSLocalizedString(@"1915-StatusUpdating", nil) maskType:SVProgressHUDMaskTypeGradient];
    });
    
    
    AvatarUploadService *setAvatarService = [[AvatarUploadService alloc] initWithAvatar:image forUser:[UserSessionService currentUserSession].user];
    
    [setAvatarService callServiceWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
        dispatch_async_main(^{
            
            DDLogError(@"%@", error);
            DDLogError(@"Localized Description: \n%@", [error localizedDescription]);
            
            if (error) {
                
                [AlertController showAlertWithTitle:QliqLocalizedString(@"1155-TextUnableToUpdateDueToServerError")
                                            message:QliqLocalizedString(@"1076-TextTryLater")
                                        buttonTitle:nil
                                  cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                         completion:nil];
                
            } else if (status == CompletitionStatusSuccess) {
                
                self.contactHeaderView.avatarView.image = [[QliqAvatar sharedInstance] getAvatarForItem:[UserSessionService currentUserSession].user withTitle:nil];
            }
            
            self.isAvatarUpdated = YES;
            [SVProgressHUD dismiss];
        });
    }];
}

- (BOOL)notificatioEnabled
{
    BOOL enabled = NO;
    
    if ([QliqStorage sharedInstance].deviceToken)
    {
            enabled = [[UIApplication sharedApplication] isRegisteredForRemoteNotifications];
    }
    else
    {
        [appDelegate setupAppNotifications];
        enabled = NO;
    }
    return enabled;
}

#pragma mark - Actions -

#pragma mark * IBActions

- (IBAction)onBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark * UISwitchActions

- (void)didChangeBatterySavingMode:(UISwitch *)cellSwitch
{
    UserSettings *userSettings = [UserSessionService currentUserSession].userSettings;
    userSettings.isBatterySavingModeEnabled = cellSwitch.on;
    [userSettings write];
}

- (void)didChangeNotificationMode:(UISwitch *)cellSwitch
{
    
    VoidBlock alertBlock = ^{
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                                 message:NSLocalizedString(@"1143-TextTurnOnNotifications", nil)
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"4-ButtonCancel", nil)
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil];
        
        UIAlertAction *settings = [UIAlertAction actionWithTitle:NSLocalizedString(@"33-ButtonOpenSettings", nil)
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                                             [[UIApplication sharedApplication] openURL:url];
                                                         }];
        
        [alertController addAction:settings];
        [alertController addAction:cancel];
        
        [self.navigationController presentViewController:alertController animated:YES completion:nil];
    };
    
    if (cellSwitch.on)
    {
        [appDelegate setupAppNotifications];
        
        if (![self notificatioEnabled])
        {
            alertBlock();
        }
        else
            [appDelegate showPushNotificationsAlertIfTurnedOff];
    }
    else
        alertBlock();
    
    [self.tableView reloadData];
}

#pragma mark - Delegates -

#pragma mark * UITableViewDataSource/Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    count = SettingsRowCount;
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MainSettingsTableViewCell *cell = nil;
    
    static NSString *reuseId1 = @"SETTINGS_CELL_ID";
    static NSString *reuseId2 = @"SETTINGS_BUTTONS_CELL_ID";
    
    SettingsRow currentRow = indexPath.row;
    switch (currentRow) {
        // Disable this code
#if 0
        case SettingsRowBatterySaving:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:reuseId1];
            
            UserSettings *userSettings = [UserSessionService currentUserSession].userSettings;
            
            cell.nameOptionLabel.textColor = [UIColor darkGrayColor];
            cell.nameOptionLabel.text = QliqLocalizedString(@"2035-TitleBatterySaving");
            
            cell.switchOptionMode.hidden = NO;
            cell.switchOptionMode.on = userSettings.isBatterySavingModeEnabled;
            [cell.switchOptionMode addTarget:self action:@selector(didChangeBatterySavingMode:) forControlEvents:UIControlEventValueChanged];
            
            return cell;
            break;
        }
#endif
        case SettingsRowNotificationEnable:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:reuseId1];
            
            cell.nameOptionLabel.textColor = [UIColor darkGrayColor];
            cell.nameOptionLabel.text = QliqLocalizedString(@"2036-TitlePushNotifications");

            cell.switchOptionMode.hidden = NO;
            cell.switchOptionMode.on = [self notificatioEnabled];
            [cell.switchOptionMode addTarget:self action:@selector(didChangeNotificationMode:) forControlEvents:UIControlEventValueChanged];
            
            return cell;
            
            break;
        }
        case SettingsRowPresence:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:reuseId1];
            cell.nameOptionLabel.text = QliqLocalizedString(@"2037-TitlePresence");
            cell.arrowImageView.hidden = NO;
            
            return cell;
            
            break;
        }
        case SettingsRowSoundsAndAlets:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:reuseId1];
            cell.nameOptionLabel.text = QliqLocalizedString(@"2038-TitleSoundsandAlerts");
            cell.arrowImageView.hidden = NO;
            
            return cell;
            
            break;
        }
        case SettingsRowEscalated:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:reuseId1];
            cell.nameOptionLabel.text = QliqLocalizedString(@"2039-TitleEscalatedCallNotifications");
            cell.arrowImageView.hidden = NO;
            
            return cell;
            
            break;
        }
        case SettingsRowSecurity:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:reuseId1];
            cell.nameOptionLabel.text = QliqLocalizedString(@"2040-TitleSecurity");
            cell.arrowImageView.hidden = NO;
            
            return cell;
            
            break;
        }
        case SettingsRowSupport:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:reuseId1];
            cell.nameOptionLabel.text = QliqLocalizedString(@"2041-TitleSupport");
            cell.arrowImageView.hidden = NO;
            
            return cell;
            
            break;
        }
        case SettingsRowGeneral:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:reuseId1];
            cell.nameOptionLabel.text = QliqLocalizedString(@"2464-TitleGeneral");
            cell.arrowImageView.hidden = NO;

            return cell;
            break;
        }
        case SettingsRowSyncAndLogout:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:reuseId2];
            cell.delegate = self;
            
            return cell;
            
            break;
        }
        default:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:reuseId1];
            return cell;
            break;
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SettingsRow currentRow = indexPath.row;
    
    NSArray *controllers = [self.navigationController viewControllers];
    
    switch (currentRow)
    {
        case SettingsRowPresence: {
            // As it is leaking about 144B per call.
            if (![controllers.lastObject isKindOfClass:[SettingsPresenceViewController class]]) {
                SettingsPresenceViewController *viewController = [kSettingsStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([SettingsPresenceViewController class])];
                [self.navigationController pushViewController:viewController animated:YES];
            }
            break;
        }
        case SettingsRowSoundsAndAlets: {
            // As it is leaking about 144B per call.
            if (![controllers.lastObject isKindOfClass:[SettingsSoundViewController class]]) {
                SettingsSoundViewController *viewController = [kSettingsStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([SettingsSoundViewController class])];
                [self.navigationController pushViewController:viewController animated:YES];
            }
            break;
        }
        case SettingsRowEscalated: {
            // As it is leaking about 144B per call.
            if (![controllers.lastObject isKindOfClass:[SettingsEscalatedViewController class]]) {
                SettingsEscalatedViewController *viewController = [kSettingsStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([SettingsEscalatedViewController class])];
                [self.navigationController pushViewController:viewController animated:YES];
            }
            break;
        }
        case SettingsRowSecurity: {
            // As it is leaking about 144B per call.
            if (![controllers.lastObject isKindOfClass:[SettingsSecurityViewController class]]) {
                SettingsSecurityViewController *viewController = [kSettingsStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([SettingsSecurityViewController class])];
                [self.navigationController pushViewController:viewController animated:YES];
            }
            break;
        }
        case SettingsRowSupport: {
            // As it is leaking about 144B per call.
            if (![controllers.lastObject isKindOfClass:[SettingsSupportViewController class]]) {
                SettingsSupportViewController *viewController = [kSettingsStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([SettingsSupportViewController class])];
                [self.navigationController pushViewController:viewController animated:YES];
            }
            break;
        }
        case SettingsRowGeneral: {

            if (![controllers.lastObject isKindOfClass:[SettingsGeneralViewController class]]) {
                SettingsGeneralViewController *viewController = [kSettingsStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([SettingsGeneralViewController class])];
                [self.navigationController pushViewController:viewController animated:YES];
            }
            break;
        }
        default:
            break;
    }
}

#pragma mark * MainSettingsHeaderViewDelegate

- (void)showUserProfile
{
    ProfileViewController *controller = [kSettingsStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ProfileViewController class])];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)changeAvatar
{
//    if(self.contactHeaderView.avatarView)
    if(self.contactHeaderView.avatar)
    {
        UIActionSheet_Blocks *actionSheet = [[UIActionSheet_Blocks alloc] initWithTitle:NSLocalizedString(@"1116-TextChangeAvatar", nil)
                                                                               delegate:nil
                                                                      cancelButtonTitle:NSLocalizedString(@"4-ButtonCancel", nil)
                                                                 destructiveButtonTitle:NSLocalizedString(@"23-ButtonRemoveAvatar", nil)
                                                                      otherButtonTitles:NSLocalizedString(@"24-ButtonCreateAvatar", nil), nil];
        
        [actionSheet showInView:self.view block:^(UIActionSheetAction action, NSUInteger buttonIndex) {
            
            if (action == UIActionSheetActionDidClicked)
            {
                switch (buttonIndex)
                {
                    case 0: [self saveAvatar:nil]; break;
                    case 1: [self.imageCaptureController captureImage]; break;
                    default: break;
                }
            }
        }];
    }
    else
    {
        [self.imageCaptureController captureImage];
    }
    
}

#pragma mark - MainSettingsCellDelegate

- (void)syncContactsWasPressed
{
    [QliqConnectModule syncContacts:YES];
}

- (void)logOutWasPressed
{
    [AlertController showAlertWithTitle:NSLocalizedString(@"1072-TextWarning", @"Warning")
                                message:NSLocalizedString(@"1073-TextAskDoYouWantLogout", nil)
                            buttonTitle:NSLocalizedString(@"3-ButtonYES", nil)
                      cancelButtonTitle:NSLocalizedString(@"2-ButtonNO", nil)
                             completion:^(NSUInteger buttonIndex) {
                                 if(buttonIndex == 0) {
                                     [[Login sharedService] startLogoutWithCompletition:nil];
                                 }
                             }];
}

#pragma mark - ImageController Delegate

- (void)presentImageCaptureController:(UIViewController *)controller {
    [self.navigationController presentViewController:controller animated:YES completion:nil];
}

- (void)imageCaptured:(UIImage *)image withController:(UIViewController *)contorller {
    if (image) {
        [self saveAvatar:image];
    } else {
        DDLogError(@"Nil image captured");

        [AlertController showAlertWithTitle:QliqLocalizedString(@"1023-TextError")
                                    message:QliqLocalizedString(@"2356-TextImageWasNotCaptured")
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                 completion:^(NSUInteger buttonIndex) {
                                     [SVProgressHUD dismiss];
                                 }];
    }
    
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (void) imageCaptureControllerCanceled:(UIViewController *)controller{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
