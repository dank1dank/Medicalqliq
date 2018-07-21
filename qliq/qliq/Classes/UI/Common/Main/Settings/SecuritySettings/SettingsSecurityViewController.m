//
//  SettingsSecurityViewController.m
//  qliq
//
//  Created by Valerii Lider on 20.11.14.
//
//

#import "SettingsSecurityViewController.h"
#import "SettingsSecurityTableViewCell.h"
#import "KeychainService.h"
#import "SettingsItem.h"
#import "ResetPasswordViewController.h"
#import "NSString+Base64.h"

#import "DefaultSettingsTableViewCell.h"
#import "SettingsSwitchTableViewCell.h"
#import "ChangePinViewController.h"

#import "SecuritySettings.h"
#import "UserSessionService.h"
#import "Login.h"

#import "AlertController.h"

typedef enum {
    SwitchPin = 1,
    SwitchDevicePin,
    SwitchDeleteMedia,
    SwitchBiometrics
} SwitchAction;

typedef NS_ENUM(NSInteger, PersonalCell) {
    PersonalCellDevicePin,
    PersonalCellPin,
    PersonalCellChangePin,
    PersonalCellResetPassword,
    PersonalCellDeleteMediaUponExpiry,
    PersonalCellDeleteData,
    PersonalCellTouchId,
    PersonalCellCount
};

typedef NS_ENUM(NSInteger, AdminCell) {
    AdminCellEnforcePin,
    AdminCellRememberPassword,
    AdminCellIncativityTime,
    AdminCellLockoutTime,
    AdminCellPersonalContacts,
    AdminCellMessageRetentionPeriod,
    AdminCellCaptureScreen,
    AdminCellCount
};

typedef NS_ENUM(NSInteger, SettingsType) {
    SettingsTypeAdmin,
    SettingsTypePersonal,
    SettingsTypeCount
};

#define kDefaultCellHeight 44.f
#define kDefaultHeaderSectionHeight 20.f

@interface SettingsSecurityViewController () <UITableViewDataSource, UITableViewDelegate>


@property (weak, nonatomic) IBOutlet UILabel *navigationLeftTitleLabel;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (assign, nonatomic) BOOL alreadyInEditing;

@property (strong, nonatomic) NSMutableArray *personalSecurityItems;

@property (strong, nonatomic) SecuritySettings * settings;

@end

@implementation SettingsSecurityViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
        self.navigationLeftTitleLabel.text = QliqLocalizedString(@"105-ButtonSecurity");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO];
    
    self.settings = [UserSessionService currentUserSession].userSettings.securitySettings;
    
    [self setItemsFromSettings];
    
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setters -

- (NSMutableArray *)personalSecurityItems {
    
    if (_personalSecurityItems == nil) {
        _personalSecurityItems = [[NSMutableArray alloc] init];
    }
    
    return _personalSecurityItems;
}

#pragma mark - Private -

- (void)setItemsFromSettings
{
    self.alreadyInEditing = YES;
    
    UISwitch *switchPin = (UISwitch*)[self.tableView viewWithTag:SwitchPin];
    [switchPin setOn:[[KeychainService sharedService] pinAvailable] animated:NO];
    
    self.alreadyInEditing = NO;
}

- (void)setSettingsFromItems
{
    if (self.alreadyInEditing == NO) {
        
        if (((UISwitch *) [self.tableView viewWithTag:SwitchPin]).on) {
            DDLogSupport(@"Restoring PIN upon user's request in settings");
            NSString *decodedPin = [[[KeychainService sharedService] getPin] base64DecodedString];
            [[KeychainService sharedService] savePin:decodedPin];
        }
        else {
            DDLogSupport(@"Clearing PIN upon user's request in settings");
            [[KeychainService sharedService] clearPin];
        }
    }
}

- (void)preparePersonalSecurityItems
{
    [self.personalSecurityItems removeAllObjects];
    
    [self.personalSecurityItems addObject:@(PersonalCellDevicePin)];
    
    if (is_biometrics_are_available())
        [self.personalSecurityItems addObject:@(PersonalCellTouchId)];
    
    [self.personalSecurityItems addObject:@(PersonalCellPin)];
 
    if ([[KeychainService sharedService] pinAvailable]) {
        [self.personalSecurityItems addObject:@(PersonalCellChangePin)];
    }
    
    [self.personalSecurityItems addObject:@(PersonalCellResetPassword)];
    
    [self.personalSecurityItems addObject:@(PersonalCellDeleteMediaUponExpiry)];
    
    [self.personalSecurityItems addObject:@(PersonalCellDeleteData)];
    
}

#pragma mark - Actions -

- (void)didChangeValueInSwitch:(UISwitch *)cellSwitch
{
    switch (cellSwitch.tag)
    {
        case SwitchPin:
        {
            [self setSettingsFromItems];
            
            if (cellSwitch.on) {
                [self changePin];
            }
            
            if (!self.alreadyInEditing) {
                if (((UISwitch *) [self.tableView viewWithTag:1]).on) {
                    [[KeychainService sharedService] saveDeviceLockEnabled:NO];
                }
            }
            
                [self.tableView reloadData];
            break;
        }
        case SwitchDevicePin: {
            [self switchDevicePin];
            break;
        }
        case SwitchDeleteMedia: {
            [QliqStorage sharedInstance].deleteMediaUponExpiryKey = [NSNumber numberWithBool:cellSwitch.on];
            break;
        }
        case SwitchBiometrics:
        {
            SecuritySettings *securitySettings = [UserSessionService currentUserSession].userSettings.securitySettings;
            securitySettings.isEnabledTouchId = cellSwitch.on;
            
            [UserSessionService currentUserSession].userSettings.isTouchIdEnabled = cellSwitch.on;
            [[UserSessionService currentUserSession].userSettings write];
            break;
        }
        default:
            break;
    }
}

- (void)didChangeAdminValue:(UISwitch *)cellSwitch
{
    [AlertController showAlertWithTitle:nil
                                message:QliqLocalizedString(@"1203-TextAdminSecurityPolicySettingsCannotBeChanged")
                            buttonTitle:nil
                      cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                             completion:nil];
    
    [self.tableView reloadData];
}

- (void)resetPassword
{
    ResetPasswordViewController *controller = [kSettingsStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ResetPasswordViewController class])];
    controller.email = [[KeychainService sharedService] getUsername];
    
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)resetData
{
    [AlertController showAlertWithTitle:QliqLocalizedString(@"1072-TextWarning")
                                message:QliqLocalizedString(@"1204-TextAskDeleteData")
                            buttonTitle:QliqLocalizedString(@"3-ButtonYES")
                      cancelButtonTitle:QliqLocalizedString(@"2-ButtonNO")
                             completion:^(NSUInteger buttonIndex) {
                                 if (buttonIndex == 0) {
                                     [appDelegate deviceStatusController:nil performWipeWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
                                         [self viewWillAppear:NO];
                                     }];
                                 }
                             }];
}

- (void)changePin
{
    ChangePinViewController *controller = [kDefaultStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ChangePinViewController class])];
    
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)switchDevicePin {
    
    [AlertController showAlertWithTitle:nil
                                message:QliqLocalizedString(@"1205-TextChangeDevicePasscode")
                            buttonTitle:QliqLocalizedString(@"33-ButtonOpenSettings")
                      cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                             completion:^(NSUInteger buttonIndex) {
                                 if (buttonIndex == 0) {
                                     NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                     [[UIApplication sharedApplication] openURL:url];
                                 }
                             }];
    
    [self.tableView reloadData];
}

#pragma mark * IBActions

- (IBAction)onBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Delegates -

#pragma mark * UITableViewDelegate/DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return SettingsTypeCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    
    switch ((SettingsType)section) {
        case SettingsTypePersonal: {
            
            [self preparePersonalSecurityItems];
            
            count = self.personalSecurityItems.count;
            
            break;
        }
        case SettingsTypeAdmin: {
            count = AdminCellCount;
        }
        default:
            break;
    }
    return count;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kDefaultCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kDefaultCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    CGFloat height = 0;
    
    height = kDefaultHeaderSectionHeight;
    
    return height;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] init];
    headerView.backgroundColor = RGBa(255, 255, 255, 0.7f);
    
    NSString *titleHeader = @"";
    
    if (section == SettingsTypeAdmin) {
        titleHeader = QliqLocalizedString(@"2073-TitleAdminSettings");
    }
    else if (section == SettingsTypePersonal) {
        titleHeader = QliqLocalizedString(@"2074-TitleDeviceSettings");
    }
    
    UIFont *titleHeaderFont    = [UIFont systemFontOfSize:14.f];
    CGFloat offset             = 60.f;
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(offset/2, 0, tableView.bounds.size.width - offset, kDefaultHeaderSectionHeight)];
    headerLabel.text            = titleHeader;
    headerLabel.textColor       = RGBa(3, 120, 173, 1);
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.font            = titleHeaderFont;
    headerLabel.textAlignment   = NSTextAlignmentLeft;
    headerLabel.adjustsFontSizeToFitWidth = YES;
    
    [headerLabel setMinimumScaleFactor:8.f/[UIFont labelFontSize]];
    
    [headerView addSubview:headerLabel];
    
    return headerView;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch ((SettingsType)indexPath.section) {
        case SettingsTypePersonal: {
 
            static NSString *reuseIdentifire = @"SECURITY_SETTINGS_CELL_ID";
            SettingsSecurityTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifire];
            
            PersonalCell cellType = [self.personalSecurityItems[indexPath.row] integerValue];
            switch (cellType)
            {
                case PersonalCellDevicePin: {
                    cell.nameOptionLabel.text = QliqLocalizedString(@"2075-TitleDevicePasscode");
                    
                    cell.switchOption.hidden = NO;
                    cell.switchOption.tag = SwitchDevicePin;
                    [cell.switchOption setOn:[[KeychainService sharedService] isDeviceLockEnabled] animated:NO];
                    [cell.switchOption addTarget:self action:@selector(didChangeValueInSwitch:) forControlEvents:UIControlEventValueChanged];
                    break;
                }

                case PersonalCellPin: {
                    cell.nameOptionLabel.text = QliqLocalizedString(@"2076-TitleQliqPIN");
                    
                    cell.switchOption.hidden = NO;
                    cell.switchOption.tag = SwitchPin;
                    [cell.switchOption setOn:[[KeychainService sharedService] pinAvailable] animated:NO];
                    [cell.switchOption addTarget:self action:@selector(didChangeValueInSwitch:) forControlEvents:UIControlEventValueChanged];
                    break;
                }
                    
                case PersonalCellChangePin: {
                    
                    cell.nameOptionLabel.text = QliqLocalizedString(@"2077-TitleChangeQliqPIN");
                    
                    cell.arrowImageView.hidden = NO;
                    
                    break;
                }
                case PersonalCellResetPassword: {
                    cell.nameOptionLabel.text = QliqLocalizedString(@"2078-TitleResetPassword");
                    
                    cell.arrowImageView.hidden = NO;
                    break;
                }
                case PersonalCellDeleteMediaUponExpiry: {
                    cell.nameOptionLabel.text = QliqLocalizedString(@"2079-TitleDeleteMediaUponExpiry");
                    
                    cell.switchOption.hidden = NO;
                    cell.switchOption.tag = SwitchDeleteMedia;
                    [cell.switchOption setOn:[[QliqStorage sharedInstance].deleteMediaUponExpiryKey boolValue] animated:NO];
                    [cell.switchOption addTarget:self action:@selector(didChangeValueInSwitch:) forControlEvents:UIControlEventValueChanged];
                    break;
                }
                case PersonalCellDeleteData: {
                    cell.nameOptionLabel.text = QliqLocalizedString(@"2080-TitleDeleteData");
                    
                    cell.arrowImageView.hidden = NO;
                    break;
                }
                case PersonalCellTouchId: {
                    cell.nameOptionLabel.text = QliqLocalizedString(@"2081-TitleTouchID");
                    
                    cell.switchOption.hidden = NO;
                    cell.switchOption.tag = SwitchBiometrics;
                    cell.switchOption.on = [UserSessionService currentUserSession].userSettings.isTouchIdEnabled;
                    [cell.switchOption addTarget:self action:@selector(didChangeValueInSwitch:) forControlEvents:UIControlEventValueChanged];
                    break;
                }
                default:
                    break;
            }
            
            return cell;
            break;
        }
        case SettingsTypeAdmin: {
            
            static NSString *reuseIdentifire = @"SECURITY_SETTINGS_CELL_ID";
            SettingsSecurityTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifire];
            
            SecuritySettings *sSettings = [UserSessionService currentUserSession].userSettings.securitySettings;
            
            switch ((AdminCell)indexPath.row) {
                case AdminCellEnforcePin: {
                    
                    cell.nameOptionLabel.text = QliqLocalizedString(@"2082-TitleEnforcePIN");
                    
                    cell.switchOption.hidden = NO;
                    cell.switchOption.on = sSettings.enforcePinLogin;
                    [cell.switchOption addTarget:self action:@selector(didChangeAdminValue:) forControlEvents:UIControlEventValueChanged];
                    
                    return cell;
                    break;
                }
                case AdminCellRememberPassword: {
                    
                    cell.nameOptionLabel.text = QliqLocalizedString(@"2083-TitleRememberPassword");
                    
                    cell.switchOption.hidden = NO;
                    cell.switchOption.on = sSettings.rememberPassword;
                    [cell.switchOption addTarget:self action:@selector(didChangeAdminValue:) forControlEvents:UIControlEventValueChanged];
                    
                    return cell;
                    break;
                }
                case AdminCellIncativityTime: {
                    
                    NSUInteger minutes = sSettings.maxInactivityTime/60;
                    
                    cell.nameOptionLabel.text = QliqLocalizedString(@"2084-TitleInactivityTime");
                    cell.descriptionLabel.text = [NSString stringWithFormat:@"%lu min", (unsigned long)minutes];
                    
                    return cell;
                    break;
                }
                case AdminCellLockoutTime: {
                    
                    NSUInteger minutes = [Login sharedService].failedAttemptsController.lockInterval/60;
                    
                    cell.nameOptionLabel.text = QliqLocalizedString(@"2085-TitleFailedLoginLockoutTime");
                    cell.descriptionLabel.text = [NSString stringWithFormat:@"%lu min", (unsigned long)minutes];
                    
                    return cell;
                    break;
                }
                case AdminCellPersonalContacts: {
                    
                    cell.nameOptionLabel.text = QliqLocalizedString(@"2086-TitlePersonalContacts");
                    
                    cell.switchOption.hidden = NO;
                    cell.switchOption.on = sSettings.personalContacts;
                    [cell.switchOption addTarget:self action:@selector(didChangeAdminValue:) forControlEvents:UIControlEventValueChanged];
                    
                    return cell;
                    break;
                }
                case AdminCellMessageRetentionPeriod: {
                    
                    cell.nameOptionLabel.text = QliqLocalizedString(@"2318-TitleMessageRetentionPeriod");
                    
                    const int secondsPerDay = 60 * 60 * 24;
                    NSInteger days = sSettings.keepMessageFor / secondsPerDay;
                    
                    cell.descriptionLabel.text = QliqFormatLocalizedString1(@"2319-TitleMessageRetentionPeriod%@Days", days);
                    
                    return cell;
                    break;
                }
                case AdminCellCaptureScreen: {
                    cell.nameOptionLabel.text = QliqLocalizedString(@"2320-TitleScreenCapture");
                    
                    cell.switchOption.hidden = NO;
                    cell.switchOption.on = !sSettings.blockScreenshots;
                    [cell.switchOption addTarget:self action:@selector(didChangeAdminValue:) forControlEvents:UIControlEventValueChanged];
                    
                    return cell;
                    break;
                }
                default: {
                    static NSString *cellIdentifier = kSettingsTableViewCell_ID;
                    DefaultSettingsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
                    
                    if(!cell) {
                        UINib *nib = [UINib nibWithNibName:NSStringFromClass([DefaultSettingsTableViewCell class]) bundle:nil];
                        [tableView registerNib:nib forCellReuseIdentifier:cellIdentifier];
                        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
                    }
                    [cell configureCellWithTitle:nil withDescription:nil withArrow:NO];
                    return cell;
                    break;
                }
            }
            break;
        }
        default: {
            
            static NSString *cellIdentifier = kSettingsTableViewCell_ID;
            DefaultSettingsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            
            if(!cell) {
                UINib *nib = [UINib nibWithNibName:NSStringFromClass([DefaultSettingsTableViewCell class]) bundle:nil];
                [tableView registerNib:nib forCellReuseIdentifier:cellIdentifier];
                cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            }
            [cell configureCellWithTitle:nil withDescription:nil withArrow:NO];
            return cell;
            break;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch ((SettingsType)indexPath.section) {
        case SettingsTypePersonal: {
            
            PersonalCell cellType = [self.personalSecurityItems[indexPath.row] integerValue];
            switch (cellType)
            {
                case PersonalCellResetPassword: {
                    [self resetPassword];
                    break;
                }
                case PersonalCellDeleteData: {
                    [self resetData];
                    break;
                }
                case PersonalCellChangePin: {
                    [self changePin];
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case SettingsTypeAdmin: {
            
            break;
        }
        default:
            break;
    }
}

@end
