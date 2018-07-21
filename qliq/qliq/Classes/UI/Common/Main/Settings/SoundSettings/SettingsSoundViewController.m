//
//  SettingsSoundViewController.m
//  qliq
//
//  Created by Valeriy Lider on 21.11.14.
//
//

#import "SettingsSoundViewController.h"
#import "SettingsSoundTableViewCell.h"
#import "SettingsRingtoneViewController.h"
#import "QliqUserNotifications.h"
#import "UIDevice-Hardware.h"

typedef NS_ENUM(NSInteger, SettingsSound) {
    SettingsSoundIncomingMessages,
    SettingsSoundIncomingCareChannelMessages,
    SettingsSoundOther,
    SettingsSoundCount
};

typedef NS_ENUM(NSInteger, IncomingMessages) {
    IncomingMessagesNormal,
    IncomingMessagesUrgent,
    IncomingMessagesAsap,
    IncomingMessagesFyi,
    IncomingMessagesCount
};

typedef NS_ENUM(NSInteger, Other) {
    OtherSendMessage,
    OtherAcknowledged,
    OtherCount
};

@interface SettingsSoundViewController () <UITableViewDataSource, UITableViewDelegate>


@property (weak, nonatomic) IBOutlet UILabel *navigationLeftTitleLabel;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation SettingsSoundViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Navigation Bar
    self.navigationLeftTitleLabel.text = QliqLocalizedString(@"104-ButtonSoundSettings");
    
    
    self.soundSettings = [UserSessionService currentUserSession].userSettings.soundSettings;
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO];
    
    self.soundSettings = [UserSessionService currentUserSession].userSettings.soundSettings; // to update the settings
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

#pragma mark -
#pragma mark UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView  {
    return SettingsSoundCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    
    SettingsSound currentSettingsSound = section;
    switch (currentSettingsSound)
    {
        case SettingsSoundIncomingMessages: {
            count = IncomingMessagesCount;
            break;
        }
        case SettingsSoundIncomingCareChannelMessages: {
            count = IncomingMessagesCount;
            break;
        }
        case SettingsSoundOther: {
            count = OtherCount;
            break;
        }
        default:
            break;
    }
    
    return count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = 0;
    
    SettingsSound currentSettingsSound = section;
    switch (currentSettingsSound)
    {
        case SettingsSoundIncomingMessages: {
            height = tableView.sectionHeaderHeight;
            break;
        }
        case SettingsSoundIncomingCareChannelMessages: {
            height = tableView.sectionHeaderHeight;
            break;
        }
        case SettingsSoundOther: {
            height = tableView.sectionHeaderHeight;
            break;
        }
        default:
            break;
    }
    
    return height;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] init];
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 7, 300, 15)];
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.font = [UIFont fontWithName:@"HelveticaNeueLTStd-Bd" size:12];
    headerLabel.textColor = [UIColor colorWithRed:0.0f/255.0f green:120.0f/255.0f blue:174.0f/255.0f alpha:1.0f];
    headerView.backgroundColor = [UIColor colorWithRed:255/255.0f green:255/255.0f blue:255/255.0f alpha:0.7];
    [headerView addSubview:headerLabel];
    
    SettingsSound currentSettingsSound = section;
    switch (currentSettingsSound)
    {
        case SettingsSoundIncomingMessages: {
            headerLabel.text = QliqLocalizedString(@"2053-TitleIncomingMessages");
            return headerView;
            break;
        }
        case SettingsSoundIncomingCareChannelMessages: {
            headerLabel.text = QliqLocalizedString(@"20601-TitleCareChannelMessages");
            return headerView;
            break;
        }
        case SettingsSoundOther: {
            headerLabel.text = QliqLocalizedString(@"2054-TitleOther");
            return headerView;
            break;
        }

        default:
            return nil;
            break;
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SettingsSoundTableViewCell *cell = nil;
    
    static NSString *reuseId = @"SOUND_SETTINGS_CELL_ID";
    cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    NSArray *priorities = [self.soundSettings priorities];
    NSArray *prioritiesCareChannel = [self.soundSettings prioritiesCareChannel];
    NSArray *otherTitles = @[NotificationTypeSend, NotificationTypeAck, NotificationTypeRinger];
    
    SettingsSound currentSettingsSound = indexPath.section;
    switch (currentSettingsSound)
    {
        case SettingsSoundIncomingMessages: {
            
            cell.switchOption.hidden = YES;
            cell.arrowImage.hidden = NO;
            cell.descriptionLabel.hidden = NO;
            
            Ringtone *ringtone = [self.soundSettings ringtoneForPriority:[priorities objectAtIndex:indexPath.row] andType:NotificationTypeIncoming];
            cell.descriptionLabel.text = [ringtone name];
            
            IncomingMessages currentIncomingMessages = indexPath.row;
            switch (currentIncomingMessages) {
                case IncomingMessagesNormal: {
                    cell.titleLabel.text = QliqLocalizedString(@"2055-TitleNormalMessage");
                    break;
                }
                case IncomingMessagesUrgent: {
                    cell.titleLabel.text = QliqLocalizedString(@"2056-TitleUrgentMessage");
                    break;
                }
                case IncomingMessagesAsap: {
                    cell.titleLabel.text = QliqLocalizedString(@"2057-TitleASAPMessage");
                    break;
                }
                case IncomingMessagesFyi: {
                    cell.titleLabel.text = QliqLocalizedString(@"2058-TitleFYIMessage");
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case SettingsSoundIncomingCareChannelMessages:
        {
            cell.switchOption.hidden = YES;
            cell.arrowImage.hidden = NO;
            cell.descriptionLabel.hidden = NO;
            
            Ringtone *ringtone = [self.soundSettings ringtoneForPriority:[prioritiesCareChannel objectAtIndex:indexPath.row] andType:NotificationTypeIncomingCareChannel];
            cell.descriptionLabel.text = [ringtone name];
            
            IncomingMessages currentIncomingMessages = indexPath.row;
            switch (currentIncomingMessages) {
                case IncomingMessagesNormal: {
                    cell.titleLabel.text = QliqLocalizedString(@"2055-TitleNormalMessage");
                    break;
                }
                case IncomingMessagesUrgent: {
                    cell.titleLabel.text = QliqLocalizedString(@"2056-TitleUrgentMessage");
                    break;
                }
                case IncomingMessagesAsap: {
                    cell.titleLabel.text = QliqLocalizedString(@"2057-TitleASAPMessage");
                    break;
                }
                case IncomingMessagesFyi: {
                    cell.titleLabel.text = QliqLocalizedString(@"2058-TitleFYIMessage");
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case SettingsSoundOther: {
            
            cell.switchOption.hidden = YES;
            cell.arrowImage.hidden = NO;
            cell.descriptionLabel.hidden = NO;
            
            Ringtone *ringtone = [self.soundSettings ringtoneForPriority:NotificationPriorityNormal andType:[otherTitles objectAtIndex:indexPath.row]];
            cell.descriptionLabel.text = [ringtone name];
            
            Other currentOther = indexPath.row;
            switch (currentOther)
            {
                case OtherSendMessage: {
                    cell.titleLabel.text = QliqLocalizedString(@"2059-TitleSendMessage");
                    break;
                }
                case OtherAcknowledged: {
                    cell.titleLabel.text = QliqLocalizedString(@"2060-TitleAcknowledged");
                    break;
                }
                default:
                    break;
            }
            break;
        }
        default:
            return nil;
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *priorities = [self.soundSettings priorities];
    NSArray *prioritiesCareChannel = [self.soundSettings prioritiesCareChannel];
    NSArray *otherTitles = @[NotificationTypeSend, NotificationTypeAck, NotificationTypeRinger];
    
    SettingsSound currentSettingsSound = indexPath.section;
    switch (currentSettingsSound)
    {
        case SettingsSoundIncomingMessages: {

            NotificationsSettings *notificationSettings = [self.soundSettings notificationsSettingsForPriority:[priorities objectAtIndex:indexPath.row]];
            Ringtone *ringtone = [notificationSettings ringtoneForType:NotificationTypeIncoming];
            
            SettingsRingtoneViewController *controller = [kSettingsStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([SettingsRingtoneViewController class])];
            
            controller.otherSounds = NO;
            controller.forCareChannel = NO;
            controller.typeSound = indexPath.row;
            controller.currentRingtone = ringtone;
            controller.notificationSettings = notificationSettings;
            [self.navigationController pushViewController:controller animated:YES];
            break;
        }
        case SettingsSoundIncomingCareChannelMessages: {
            
            NotificationsSettings *notificationSettings = [self.soundSettings notificationsSettingsForPriority:[prioritiesCareChannel objectAtIndex:indexPath.row]];
            Ringtone *ringtone = [notificationSettings ringtoneForType:NotificationTypeIncomingCareChannel];
            
            SettingsRingtoneViewController *controller = [kSettingsStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([SettingsRingtoneViewController class])];
            
            controller.otherSounds = NO;
            controller.forCareChannel = YES;
            controller.typeSound = indexPath.row;
            controller.currentRingtone = ringtone;
            controller.notificationSettings = notificationSettings;
            [self.navigationController pushViewController:controller animated:YES];
            break;
        }
        case SettingsSoundOther: {

            NotificationsSettings *notificationSettings = [self.soundSettings notificationsSettingsForPriority:NotificationPriorityNormal];
            Ringtone *ringtone = [notificationSettings ringtoneForType:[otherTitles objectAtIndex:indexPath.row]];
            
            SettingsRingtoneViewController *controller = [kSettingsStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([SettingsRingtoneViewController class])];
            
            controller.forCareChannel = NO;
            controller.otherSounds = YES;
            controller.typeSound = indexPath.row;
            controller.currentRingtone = ringtone;
            controller.notificationSettings = notificationSettings;
            [self.navigationController pushViewController:controller animated:YES];
            break;
        }

        default:
            break;
    }
}

#pragma mark - IBActions

- (IBAction)onBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didChangeValueInSwitch:(UISwitch *)cellSwitch
{
    if ([cellSwitch isOn])
    {
        DDLogSupport(@"Registering for remote notifications");
            [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
    }
    else
    {
        [[QliqUserNotifications getInstance] cancelChimeNotifications:YES];
    }
}

- (BOOL) isSimulator {
    return ([[UIDevice currentDevice] isSimulator] == YES);
}

@end
