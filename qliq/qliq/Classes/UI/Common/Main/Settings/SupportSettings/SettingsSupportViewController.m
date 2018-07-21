//
//  SettingsSupportViewController.m
//  qliq
//
//  Created by Valeriy Lider on 21.11.14.
//
//

#import "SettingsSupportViewController.h"
#import "QliqSip.h"
#import "FeedBackSupportViewController.h"
#import "SettingsSupportTableViewCell.h"
#import "SettingsItem.h"
#import "MediaFileService.h"
#import "MediaFileDBService.h"
#import "NSString+Filesize.h"
#import "ConversationDBService.h"

#import "MediaGridViewController.h"

#import "QliqUserDBService.h"

typedef NS_ENUM(NSInteger, SupportItem) {
    SupportItemDocuments,
    SupportItemPhotos,
    SupportItemAudio,
    SupportItemVideo,
    SupportItemCashes,
    SupportItemMessage,
    SupportItemContacts,
    SupportItemUpdateEmails,
    SupportItemConnection,
    SupportItemCount
};

#define kDefaultCellHeight 44.f

@interface SettingsSupportViewController () <UITableViewDataSource, UITableViewDelegate, SettingsSupportCellDelegate, MediaGridViewControllerDelegate>


@property (weak, nonatomic) IBOutlet UILabel *navigationLeftTitleLabel;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
//@property (weak, nonatomic) IBOutlet UILabel *softwareUpdateLabel;
@property (weak, nonatomic) IBOutlet UIButton *updateSoftwareButton;

@property (weak, nonatomic) IBOutlet UIImageView *serverStatusImage;
@property (weak, nonatomic) IBOutlet UILabel *serverStatusTitleLabel;

@property (weak, nonatomic) IBOutlet UILabel *serverStatusLabel;

@property (weak, nonatomic) IBOutlet UIButton *sendFeedBackButton;
@property (weak, nonatomic) IBOutlet UIButton *reportErrorButton;
@property (nonatomic, strong) NSArray *mediaGroups;

@property (strong, nonatomic) SettingsItems *settingItems;

@end

@implementation SettingsSupportViewController

- (void)dealloc {
    self.navigationLeftTitleLabel = nil;
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.versionLabel = nil;
    self.updateSoftwareButton = nil;
    [self.serverStatusImage removeFromSuperview];
    self.serverStatusImage = nil;
    self.serverStatusTitleLabel = nil;
    self.serverStatusLabel = nil;
    self.sendFeedBackButton = nil;
    self.reportErrorButton = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)configureStaticText {
    
    //NavigationBar
    self.navigationLeftTitleLabel.text = QliqLocalizedString(@"106-ButtonSupportSettings");
    
    self.serverStatusTitleLabel.text = QliqLocalizedString(@"2021-TitleServerStatus");
    
    [self.sendFeedBackButton setTitle:QliqLocalizedString(@"2022-TitleSendFeedback") forState:UIControlStateNormal];

    [self.reportErrorButton setTitle:QliqLocalizedString(@"2023-TitleReportError") forState:UIControlStateNormal];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureStaticText];
    
    //Configure Controller
    [self configureHeaderView];
    [self.tableView reloadData];
    
    [self getMediaFiels];
    //Add Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshServerStatus)
                                                 name:QliqReachabilityChangedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onUpdateContactsListNotification:)
                                                 name:kUpdateContactsListNotificationName
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Private

- (void)configureHeaderView
{
    //Set CurrentVersion
    self.versionLabel.text = [NSString stringWithFormat:@"@%@ %@", QliqLocalizedString(@"2088-TitleVersion"), [self currentVersion]];
    
    //oconfigure UpdateButton
    BOOL updateAvailable = [[AppDelegate currentBuildVersion] integerValue] < [appDelegate.availableVersion integerValue];
    NSString *updateText = @"";
    if (!updateAvailable) {
        updateText = QliqLocalizedString(@"2089-TitleSoftwareUpdate");
    }
    else {
        updateText = QliqLocalizedString(@"2090-TitleUpdateAvailable");
    }
    [self.updateSoftwareButton setTitle:updateText forState:UIControlStateNormal];
    
    //CongigureServer Status
    [self refreshServerStatus];
    
    self.settingItems = [[SettingsItems alloc] init];
    [self newStatisticsSettingsItems];
}

- (void)refreshServerStatus {
    BOOL connected = [appDelegate.network.reachability sipReachable];
    self.serverStatusLabel.text = connected ? QliqLocalizedString(@"2091-TitleConnected") : QliqLocalizedString(@"2092-TitleNotConnected");
    self.serverStatusImage.image = connected ? [UIImage imageNamed:@"ServerImage"] : [UIImage imageNamed:@"ServerRedImage"];
}

- (void)onUpdateContactsListNotification:(NSNotification *)notification
{
    dispatch_async_main(^{
        [self.tableView reloadData];
    });
}

#pragma mark - Helpers

- (NSInteger)getAllContactCount {
    return [[QliqUserDBService sharedService] getAllOtherUsersCount];
}

- (NSString *)currentVersion {
    NSString *shortVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *bundleVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString *versionToDisplay = [NSString stringWithFormat:@"%@ (%@)",shortVersion,bundleVersion];
    return versionToDisplay;
}

- (NSUInteger)bytesCountAtPath:(NSString *)path {
    NSDictionary *attributes =[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    NSNumber *size = [attributes objectForKey:NSFileSize];
    return size.unsignedIntegerValue;
}

- (void)newStatisticsSettingsItems
{
    SettingsItems *settingitems = [[SettingsItems alloc] init];
   
    NSMutableArray *items = [[NSMutableArray alloc] init];
    
    MediaFileService *service = [MediaFileService getInstance];
    MediaFileDBService *dbService = [MediaFileDBService sharedService];
    
    NSDictionary *mediaFilesItemsRequest = [NSDictionary dictionaryWithObjectsAndKeys:
                                            [dbService mediafilesWithMimeTypes:[service imagesMimeTypes] archived:NO], @"Photos",
                                            [dbService mediafilesWithMimeTypes:[service videoMimeTypes] archived:NO], @"Video",
                                            [dbService mediafilesWithMimeTypes:[service audioMimeTypes] archived:NO], @"Audio",
                                            [dbService mediafilesWithMimeTypes:[service documentsMimeTypes] archived:NO], @"Documents",
                                            nil];
    
    [mediaFilesItemsRequest enumerateKeysAndObjectsUsingBlock:^(NSString * itemName, NSArray *mediaFiles, BOOL *stop) {
        
        SettingsItem * item = [[SettingsItem alloc] initWithStyle:SettingsItemStyleKeyValueLeft];
        item.title = itemName;
        item.showShevron = YES;
        item.context = [NSValue valueWithPointer:@selector(openMediaLibrary)];
        
        QliqLabel * label = [[QliqLabel alloc] initWithFrame:CGRectMake(0, 0, 200, 20) style:QliqLabelStyleBold];
        item.valueView = label;
        
        NSUInteger bytesCount = 0;
        for (MediaFile * mediaFile in mediaFiles){
            bytesCount += [self bytesCountAtPath:[mediaFile encryptedPath]];
        }
        label.text = [NSString stringWithFormat:@"%lu files (%@)",(unsigned long)[mediaFiles count],[NSString fileSizeFromBytes:bytesCount]];
        item.info = [NSString stringWithFormat:@"%lu files (%@)",(unsigned long)[mediaFiles count],[NSString fileSizeFromBytes:bytesCount]]; // For storyboard
        
        [items addObject:item];
    }];
    
    SettingsItem * messagesItem = [[SettingsItem alloc] initWithStyle:SettingsItemStyleKeyValueLeft];
    messagesItem.title = @"Message";
    QliqLabel * messageslabel = [[QliqLabel alloc] initWithFrame:CGRectMake(0, 0, 200, 20) style:QliqLabelStyleBold];
    messagesItem.valueView = messageslabel;
    messagesItem.showShevron = YES;
    messagesItem.context = [NSValue valueWithPointer:@selector(openRecent)];
    messageslabel.text = [NSString stringWithFormat:@"%lu threads (%@)",(unsigned long)[[ConversationDBService sharedService] numberOfConversations],[NSString fileSizeFromBytes:[[ConversationDBService sharedService] sizeOfAllConversations]]];
    messagesItem.info = [NSString stringWithFormat:@"%lu threads (%@)",(unsigned long)[[ConversationDBService sharedService] numberOfConversations],[NSString fileSizeFromBytes:[[ConversationDBService sharedService] sizeOfAllConversations]]]; // For storyboard
    
    SettingsItem * cachesItem = [[SettingsItem alloc] initWithStyle:SettingsItemStyleKeyValueLeft];
    cachesItem.title = @"Caches";
    QliqLabel * cachesItemlabel = [[QliqLabel alloc] initWithFrame:CGRectMake(0, 0, 200, 20) style:QliqLabelStyleBold];
    cachesItem.valueView = cachesItemlabel;
    
    NSUInteger cacheBytes = 0;
    for (NSString * path in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:kDecryptedDirectory error:nil]){
        cacheBytes += [self bytesCountAtPath:[NSString stringWithFormat:@"%@%@",kDecryptedDirectory,path]];
    }
    cachesItemlabel.text = [NSString fileSizeFromBytes:cacheBytes];
    cachesItem.info = [NSString fileSizeFromBytes:cacheBytes]; // For storyboard
    
    [items addObject:cachesItem];
    [items addObject:messagesItem];
    [settingitems setItems:items forSection:[SettingsSection newWithTitle:@"Statistics" order:0]];
    
    self.settingItems = settingitems;
}

#pragma mark - Actions

- (void)didChangeValueInSwitch:(UISwitch *)cellSwitch {
    DDLogSupport(@"Switch \"Receive app update emails\" switched: %d", cellSwitch.on);
}


#pragma mark - IBActions

- (IBAction)onBack:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onSendFeedback:(id)sender
{
    FeedBackSupportViewController *controller = [kSettingsStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([FeedBackSupportViewController class])];
    controller.reportType = ReportTypeFeedback;
    [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)onReportError:(id)sender
{
    FeedBackSupportViewController *controller = [kSettingsStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([FeedBackSupportViewController class])];
    controller.reportType = ReportTypeError;
    [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)onUpdateSoftware:(id)sender {
    
    BOOL updateAvailable = [[AppDelegate currentBuildVersion] integerValue] < [appDelegate.availableVersion integerValue];
    if (updateAvailable) {
        NSURL *url = [NSURL URLWithString:@"http://itunes.apple.com/us/app/qliq/id439811557?mt=8"];
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (IBAction)onReconnect:(id)sender {
    [[QliqSip sharedQliqSip] registerUserWithAccountSettings:[UserSessionService currentUserSession].sipAccountSettings];
}

#pragma mark - UITableViewDataSource/Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kDefaultCellHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return SupportItemCount;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] init];
    headerView.backgroundColor = [UIColor clearColor];
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 7, 300, 15)];
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.font = [UIFont fontWithName:@"HelveticaNeueLTStd-Bd" size:12];
    headerLabel.textColor = RGBa(0, 120, 174, 1);
    headerLabel.text = QliqLocalizedString(@"2093-TitleStatistics");
    
    if (headerLabel.text) {
        headerView.backgroundColor = RGBa(255, 255, 255, 0.7);
    }
    
    [headerView addSubview:headerLabel];
    
    return headerView;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SettingsSupportTableViewCell *cell = nil;
    cell.delegate = self;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    static NSString *reuseId1 = @"SUPPORT_SETTINGS_CELL_ID";
    static NSString *reuseId2 = @"SUPPORT_SETTINGS_BUTTONS_CELL_ID";
    
    switch ((SupportItem)indexPath.row) {
        case SupportItemPhotos: {
            cell = [tableView dequeueReusableCellWithIdentifier:reuseId1];
            cell.arrowImage.hidden = NO;
            
            [cell configureCellWithItem:[self.settingItems itemForIndexPath:indexPath]];
            
            break;
        }
        case SupportItemVideo: {
            cell = [tableView dequeueReusableCellWithIdentifier:reuseId1];
            cell.arrowImage.hidden = NO;
            
            [cell configureCellWithItem:[self.settingItems itemForIndexPath:indexPath]];
            
            break;
        }

        case SupportItemAudio: {
            cell = [tableView dequeueReusableCellWithIdentifier:reuseId1];
            cell.arrowImage.hidden = NO;
            
            [cell configureCellWithItem:[self.settingItems itemForIndexPath:indexPath]];
            
            break;
        }
        case SupportItemDocuments: {
            cell = [tableView dequeueReusableCellWithIdentifier:reuseId1];
            cell.arrowImage.hidden = NO;
            
            [cell configureCellWithItem:[self.settingItems itemForIndexPath:indexPath]];
            
            break;
        }
        case SupportItemCashes: {
            cell = [tableView dequeueReusableCellWithIdentifier:reuseId1];
            
            [cell configureCellWithItem:[self.settingItems itemForIndexPath:indexPath]];
            
            break;
        }
        case SupportItemMessage: {
            cell = [tableView dequeueReusableCellWithIdentifier:reuseId1];
            
            [cell configureCellWithItem:[self.settingItems itemForIndexPath:indexPath]];
            
            break;
        }
        case SupportItemContacts: {
            cell = [tableView dequeueReusableCellWithIdentifier:reuseId1];
            cell.titleLabel.text = QliqLocalizedString(@"2094-TitleContacts");
            cell.descriptionLabel.text = [NSString stringWithFormat:@"%ld", (long)[self getAllContactCount]];
            
            break;
        }
        case SupportItemUpdateEmails: {
            cell = [tableView dequeueReusableCellWithIdentifier:reuseId1];
            cell.switchOption.hidden = NO;
            [cell.switchOption addTarget:self action:@selector(didChangeValueInSwitch:) forControlEvents:UIControlEventValueChanged];
            
            cell.titleLabel.text = QliqLocalizedString(@"2095-TitleReceiveAppUpdateEmails");
            
            break;
        }
        case SupportItemConnection: {
            cell = [tableView dequeueReusableCellWithIdentifier:reuseId2];
            cell.delegate = self;
            cell.titleLabel.text = QliqLocalizedString(@"2024-TitleConnection");
            
            [cell.rightButton setTitle:QliqLocalizedString(@"1902-TextClose") forState:UIControlStateNormal];
            
            break;
        }
        default: {
            cell = [tableView dequeueReusableCellWithIdentifier:reuseId1];
            break;
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MediaGridViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([MediaGridViewController class])];
    
    switch ((SupportItem)indexPath.row) {
        case SupportItemPhotos:{

            controller.viewOptions = self.mediaGroups[0];
            break;
        }
        case SupportItemVideo:{
            controller.viewOptions = self.mediaGroups[3];
            break;
        }
        case SupportItemAudio:{
            controller.viewOptions = self.mediaGroups[2];
            break;
        }
        case SupportItemDocuments: {
            controller.viewOptions = self.mediaGroups[1];
            break;
        }
        default:
            return;
            break;
    }
    controller.delegate = self;
    controller.fromSupportSettings = YES;
    controller.isGetMediaForConversation = NO;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    [self.navigationController presentViewController:navigationController animated:YES completion:nil];
}


- (void) getMediaFiels
{
    MediaFileService * service = [MediaFileService getInstance];
    MediaFileDBService * dbService = [MediaFileDBService sharedService];
    
    NSArray * imageFiles    = [dbService mediafilesWithMimeTypes:[service imagesMimeTypes] archived:NO];
    NSArray * documentFiles = [dbService mediafilesWithMimeTypes:[service documentsMimeTypes] archived:NO];
    NSArray * audioFiles    = [dbService mediafilesWithMimeTypes:[service audioMimeTypes] archived:NO];
    NSArray * videoFiles    = [dbService mediafilesWithMimeTypes:[service videoMimeTypes] archived:NO];
    
    NSDictionary * documentOptions =  @{kViewerMediaFilesArray : documentFiles,
                                        kViewerTitle           : @"Documents",
                                        kViewerTitleImage      : [UIImage imageNamed:@"KeyboardGroupDocuments"],
                                        kViewerMimeTypes       : [service documentsMimeTypes],
                                        kViewerShowFilenames   : @(YES)};
    
    NSDictionary * imagesOptions =    @{kViewerMediaFilesArray : imageFiles,
                                        kViewerTitle           : @"Images",
                                        kViewerTitleImage      : [UIImage imageNamed:@"KeyboardCroupImages"],
                                        kViewerMimeTypes       : [service imagesMimeTypes],
                                        kViewerShowFilenames   : @(NO)};
    
    NSDictionary * audioOptions =     @{kViewerMediaFilesArray : audioFiles,
                                        kViewerTitle           : @"Audio",
                                        kViewerTitleImage      : [UIImage imageNamed:@"KeyboardGroupAudio"],
                                        kViewerMimeTypes       : [service audioMimeTypes],
                                        kViewerShowFilenames   : @(YES),};
    
    NSDictionary * videoOptions =     @{kViewerMediaFilesArray : videoFiles,
                                        kViewerTitle           : @"Video",
                                        kViewerTitleImage      : [UIImage imageNamed:@"KeyboardGroupVideo"],
                                        kViewerMimeTypes       : [service videoMimeTypes],
                                        kViewerShowFilenames   : @(YES)};
    
    self.mediaGroups = [NSArray arrayWithObjects:imagesOptions,documentOptions,audioOptions,videoOptions,nil];
}

#pragma mark - SettingsSupportCellDelegate

- (void)closeConnectionWasPressed
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:QliqLocalizedString(@"1072-TextWarning")
                                                                   message:QliqLocalizedString(@"1206-TextAskCloseConnection")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:QliqLocalizedString(@"3-ButtonYES")
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
                                                          [[QliqSip sharedQliqSip] setRegistered:NO];
                                                      }];
    
    UIAlertAction *noAction = [UIAlertAction actionWithTitle:QliqLocalizedString(@"2-ButtonNO")
                                                       style:UIAlertActionStyleDefault
                                                     handler:nil];
    [alert addAction:yesAction];
    [alert addAction:noAction];
    [self presentViewController:alert animated:YES completion:nil];
    
}

@end
