//
//  UploadsMediaViewController.m
//  qliq
//
//  Created by Valerii Lider on 04/11/2017.
//
//

#import "UploadsMediaViewController.h"
#import "UploadsMediaTableViewCell.h"

//Preview controllers
#import "DocumentAttachmentViewController.h"
#import "ImageAttachmentViewController.h"
#import "AudioAttachmentViewController.h"
#import "VideoAttachmentViewController.h"

//For testing
#import "MediaFileService.h"
#import "MediaFileDBService.h"
#import "MessageAttachment.h"
#import "MessageAttachmentDBService.h"
#import "QliqConnectModule.h"
#import "ACPDownloadView.h"
#import "ACPStaticImagesAlternative.h"
#import "UploadToQliqStorService.h"
#import "UploadToEmrService.h"
#import "SipContactDBService.h"
#import "MediaFileUploadDBService.h"
#import "QxQliqStorClient.h"
#import "FaxContactDBService.h"

#import "NotificationUtils.h"
#import "MainViewController.h"
#import "AlertController.h"
#import "Constants.h"

#define kUpdateUploadFiles @"UpdateUploadFiles"

#define kUploadTargetKey @"uploadTargetKey"
#define kEMRPublicKey @"EMRPublicKey"
#define kFileNameKey @"fileNameKey"

@interface UploadsMediaViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UploadsMediaTableViewCellDelegate, MediaFileUploadObserver>

//IBOutlets
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

//Constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewTopConstraint;

//Data
@property (nonatomic, strong) NSMutableArray *mediaFileUploads;
@property (nonatomic, strong) NSMutableArray *searchingUploadFiles;
@property (nonatomic, assign) BOOL isSearching;

//Banner View
@property (nonatomic, strong) UIView *bannerView;
@property (nonatomic, strong) ACPDownloadView *activityView;

//Uploadind Services
@property (nonatomic, strong) UploadToQliqStorService *uploadToQliqStorService;
@property (nonatomic, strong) UploadToEmrService *uploadToEmrService;

@end

@implementation UploadsMediaViewController

- (void)dealloc {

    [self.bannerView removeFromSuperview];
    self.bannerView = nil;
    self.tableView.dataSource = nil;
    self.tableView.delegate = nil;
    self.searchBar = nil;
    self.mediaFileUploads = nil;
    self.uploadingMediaFile = nil;
    self.searchingUploadFiles = nil;
    self.activityView = nil;
    self.uploadsEMRInfo = nil;
    self.uploadToEmrService = nil;
    self.uploadToQliqStorService = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureDefaultText];

    if (self.uploadingMediaFile != nil) {
        [self startUpload];
    }
    
    //TableView
    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    //HeaderView
    // SearchBar
    {
        self.searchBar.placeholder = QliqLocalizedString(@"2107-TitleSearch");
        self.searchBar.delegate = self;
        self.searchBar.autocorrectionType = UITextAutocorrectionTypeYes;
        self.searchBar.spellCheckingType = UITextSpellCheckingTypeYes;
        self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.searchBar.keyboardType = UIKeyboardTypeAlphabet;
        self.isSearching = NO;
    }

    // Notifications
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUploadFiles:) name:kUpdateUploadFiles object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reuploadFile:) name:ReuploadMediaFileNotification object:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    [[MediaFileUploadObservable sharedInstance] addObserver:self];
    
    // Reload data because user could modify something inside per upload viewer (deleted, reuploaded)
    [self reloadUploadFiles];
    self.navigationController.navigationBarHidden = NO;
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[MediaFileUploadObservable sharedInstance] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private -

- (void)configureDefaultText {

    if (self.uploadToEMR) {
        self.navigationItem.title = QliqLocalizedString(@"11101-TextUploadToEMR");
    } else if(self.faxUpload){
        self.navigationItem.title = QliqLocalizedString(@"3053-TextFaxesSent");
    } else {
        self.navigationItem.title = QliqLocalizedString(@"12271-TextUploadToQliqStor");
    }
    self.navigationController.navigationBarHidden = NO;
}

- (void)appWillEnterForeground:(NSNotification *)notification {
    
    if (self.uploadingMediaFile != nil ||
        [MediaFileUploadDBService countWithShareType:UploadedToEmrMediaFileUploadShareType] > 0 ||
        [MediaFileUploadDBService countWithShareType:UploadedToQliqStorMediaFileUploadShareType] > 0) {
    }
}

- (void)showUploadingUpdatesView {

    [self updateBannerFrameForSize:[UIScreen mainScreen].bounds.size];
    [self updateActivityView];
    self.bannerView.hidden = NO;
    UILabel *lbl = [self.bannerView viewWithTag:123];

    NSString *titleUpload = nil;
    if (self.uploadToEMR) {
        titleUpload = QliqLocalizedString(@"2455-TitleEMR");
    } else {
        titleUpload = QliqLocalizedString(@"2456-TitleQliqSTOR");
    }
    lbl.text = QliqFormatLocalizedString1(@"2453-TitleUploadingTo{UploadingType}", titleUpload);
    lbl.textColor = [UIColor grayColor];
}

- (void)startUpload {
    
    void (^startUploadBlock)(NSString *qliqSTORGroupId) = ^(NSString *qliqSTORGroupId) {
        [self showUploadingUpdatesView];
        if (self.faxUpload) {
            [self uploadFaxFile:self.uploadingMediaFile toQliqStorId:qliqSTORGroupId toFaxContact:self.faxContact withSubject:self.faxSubject andBody:self.faxBody];
        } else {
            [self uploadFile:self.uploadingMediaFile withQliqSTORId:qliqSTORGroupId];
        }
        self.uploadingMediaFile = nil;
    };
    
    VoidBlock showMultipleQliqSTORsAlert = ^{
        
        QliqAlertView *multipleQliqSTORsAlert = [[QliqAlertView alloc] initWithInverseColor:NO];
        multipleQliqSTORsAlert.useMultipleQliqSTORsAvialable = YES;
        [multipleQliqSTORsAlert setContainerViewWithImage:[UIImage imageNamed:@""]
                                                withTitle:self.uploadToEMR ? QliqLocalizedString(@"1110-TextUploadToEMR") : QliqLocalizedString(@"1227-TextUploadToQliqStor")
                                                 withText:QliqLocalizedString(@"3037-TextMultipleQliqSTORsAvilable")
                                             withDelegate:nil
                                         useMotionEffects:YES];
        [multipleQliqSTORsAlert setButtonTitles:[NSMutableArray arrayWithObjects:QliqLocalizedString(@"4-ButtonCancel"), QliqLocalizedString(@"44-ButtonSave"), nil]];
        
        [multipleQliqSTORsAlert setOnButtonTouchUpInside:^(QliqAlertView *alertView, int buttonIndex) {
            if (buttonIndex != 0) {
                
                QliqStorPerGroup *selectedQliqSTORGroup = alertView.selectedTypeQliqSTORGroup;
                
                BOOL isSaveAsDefault = [alertView isSaveDefaultOption];
                
                if (selectedQliqSTORGroup && isSaveAsDefault) {
                    
                    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                    [userDefaults setBool:isSaveAsDefault forKey:kUploadToQliqSTORKey];
                    
                    [QxQliqStorClient setDefaultQliqStor:selectedQliqSTORGroup.qliqStorQliqId groupQliqId:selectedQliqSTORGroup.groupQliqId];
                    
                }
                
                if ([selectedQliqSTORGroup qliqStorQliqId].length > 0 && alertView.destinationGroupTextField.text.length > 0) {
                    
                    startUploadBlock(selectedQliqSTORGroup.qliqStorQliqId);
                } else if (!alertView.destinationGroupTextField.text.length) {
                    
                    [AlertController showAlertWithTitle:QliqLocalizedString(@"1072-TextWarning")
                                                message:QliqLocalizedString(@"2451-TitleSelectTypeField")
                                            buttonTitle:nil
                                      cancelButtonTitle:QliqLocalizedString(@"1-ButtonOk")
                                             completion:^(NSUInteger buttonIndex) {
                                                 [alertView show];
                                             }];
                } else if (!selectedQliqSTORGroup) {
                    
                    DDLogSupport(@"Can't to find QliqSTOR Group");
                }
            } else {
                if (self.mediaFileUploads.count == 0) {
                    [self onBackButton:nil];
                }
            }
        }];
        
        performBlockInMainThreadSync(^{
            [multipleQliqSTORsAlert show];
        });
    };
    
    if (QxQliqStorClient.qliqStors.count > 1 && (([QxQliqStorClient shouldShowQliqStorSelectionDialog]) ||
                                                 ([[NSUserDefaults standardUserDefaults] boolForKey:kUploadToQliqSTORKey] == NO))) {
        showMultipleQliqSTORsAlert();
    } else {
        
        if ([QxQliqStorClient defaultQliqStor].qliqStorQliqId) {
            
            startUploadBlock([QxQliqStorClient defaultQliqStor].qliqStorQliqId);
        } else {
            
            DDLogSupport(@"Cannot find the QliqSTOR group with qliqSTORQliqId = %@", [QxQliqStorClient defaultQliqStor].qliqStorQliqId);
            
            [AlertController showAlertWithTitle:nil
                                        message:QliqLocalizedString(@"3040-QliqSTORisNotActivated")
                                    buttonTitle:nil
                              cancelButtonTitle:QliqLocalizedString(@"1-ButtonOk")
                                     completion:^(NSUInteger buttonIndex) {
                                         [self onBackButton:nil];
                                     }];
        }
    }
}

- (void)dismissUploadingViewWithCompletitionStatus:(CompletitionStatus)complitionStatus {

    __weak __typeof(self)welf = self;

    VoidBlock hiddenUploadingUpdatesView = ^{

        [UIView animateWithDuration:0.15 delay:0.0f
             usingSpringWithDamping:0.05f
              initialSpringVelocity:0.1f
                            options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                                welf.bannerView.hidden = YES;
                                //Update Top tableView Constraint
                                welf.tableViewTopConstraint.constant = 0.f;
                            } completion:nil];
    };

    if (complitionStatus == CompletitionStatusError) {

        NSString *titleUpload = nil;
        if (welf.uploadToEMR) {
            titleUpload = QliqLocalizedString(@"2455-TitleEMR");
        }
        else {
            titleUpload = QliqLocalizedString(@"2456-TitleQliqSTOR");
        }

        UILabel *lbl = [welf.bannerView viewWithTag:123];
        lbl.text = QliqFormatLocalizedString1(@"2454-TitleUploadingTo{UploadingType}Failed", titleUpload);
        lbl.textColor = [UIColor redColor];
        lbl.adjustsFontSizeToFitWidth = YES;
        lbl.numberOfLines = 2.f;
        welf.tableViewTopConstraint.constant = welf.bannerView.frame.size.height;
        //play sound
        SoundSettings * soundSettings = [UserSessionService currentUserSession].userSettings.soundSettings;
        Ringtone * ringtone = [[soundSettings notificationsSettingsForPriority:NotificationPriorityNormal] ringtoneForType:NotificationTypeSend];
        [ringtone play];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (1.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            hiddenUploadingUpdatesView();
        });
    }
    else {
        hiddenUploadingUpdatesView();
    }
}

- (void)updateBannerFrameForSize:(CGSize)size {

    UILabel *lbl = nil;
    CGFloat height = 35.f;
    CGFloat maxY = CGRectGetMaxY(self.searchBar.frame);

    if (!self.bannerView) {
        self.bannerView = [[UIView alloc] initWithFrame:CGRectMake(0.f, maxY, size.width, height)];
        [self.view addSubview:self.bannerView];
        lbl = [[UILabel alloc] initWithFrame:self.bannerView.bounds];
        lbl.tag = 123;
        lbl.textAlignment = NSTextAlignmentCenter;
        self.bannerView.backgroundColor = [UIColor whiteColor];
        [self.bannerView addSubview:lbl];
    } else {
        self.bannerView.frame = CGRectMake(0.f, maxY, size.width, height);
        lbl = [self.bannerView viewWithTag:123];
        lbl.frame = self.bannerView.bounds;
    }

    lbl.text = QliqLocalizedString(@"2427-TitleCheckingForUpdates");
    lbl.textColor = [UIColor grayColor];

    //Update Top tableView Constraint
    self.tableViewTopConstraint.constant = self.bannerView.frame.size.height;
}

- (void)updateActivityView {

    if (!self.activityView) {
        self.activityView = [ACPDownloadView new];
    }
    else {
        [self.activityView setIndicatorStatus:ACPDownloadStatusNone];
    }

    CGFloat activityViewSize = 28.f;
    CGFloat positionX = self.bannerView.frame.size.width - activityViewSize - 20.f;
    CGFloat positionY = (self.bannerView.frame.size.height - activityViewSize)/2;
    [self.activityView setFrameOriginX:positionX];
    [self.activityView setFrameOriginY:positionY];
    [self.activityView setWidth:activityViewSize];
    [self.activityView setHeight:activityViewSize];

    self.activityView.hidden = NO;
    self.activityView.backgroundColor = [UIColor clearColor];
    self.activityView.clearsContextBeforeDrawing = YES;
    [self.activityView setTintColor:RGBa(24.f, 122.f, 181.f, 0.75)];

    ACPStaticImagesAlternative * myOwnImages = [ACPStaticImagesAlternative new];
    [myOwnImages setStrokeColor:[UIColor whiteColor]];
    [self.activityView setImages:myOwnImages];

    //Status by default.
    [self.activityView setIndicatorStatus:ACPDownloadStatusIndeterminate];
    [self.bannerView addSubview:self.activityView];
}

- (void)uploadFailedFiles:(UITapGestureRecognizer*)tapGestureRecognizer {

    UIView *failedImage = tapGestureRecognizer.view;
    if (self.mediaFileUploads.count > failedImage.tag) {

        MediaFileUpload *upload = [self.mediaFileUploads objectAtIndex:failedImage.tag];
        if ([upload isFailed]) {
            [self showUploadingUpdatesView];
            [self reupload:upload];
        }
    }
}

// We don't use this method, it is bad idea to retry all files at once
//- (void)reuploadAllFailedUploads {
//
//    for (MediaFileUpload *upload in self.mediaFileUploads) {
//        if ([upload isFailed]) {
//            [self showUploadingUpdatesView];
//            [self reupload:upload];
//        }
//    }
//}

#pragma mark * Data

- (void)reloadUploadFiles {

     if (self.uploadToEMR) {
         
        self.mediaFileUploads = [MediaFileUploadDBService getWithShareType:UploadedToEmrMediaFileUploadShareType skip:0 limit:0];
     } else if (self.faxUpload) {
         
         self.mediaFileUploads = [MediaFileUploadDBService getWithShareType:UploadedToFaxMediaFileUploadShareType skip:0 limit:0];
     } else {
         
        self.mediaFileUploads = [MediaFileUploadDBService getWithShareType:UploadedToQliqStorMediaFileUploadShareType skip:0 limit:0];
    }
    [self sortUploadsMediaFile:self.mediaFileUploads];

    __weak __block typeof(self) welf = self;
    performBlockInMainThread(^{
        if (welf.isSearching)
            [welf doSearch:self.searchBar.text];
        else
        {
            [welf.tableView reloadData];
        }
    });
}

- (void)sortUploadsMediaFile:(NSArray *)uploadsMediaFile {

    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"databaseId" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:descriptor];
    uploadsMediaFile = [uploadsMediaFile sortedArrayUsingDescriptors:sortDescriptors];

    if (self.isSearching) {
        self.searchingUploadFiles = [uploadsMediaFile mutableCopy];
    }
    else {
        self.mediaFileUploads = [uploadsMediaFile mutableCopy];
    }
}

#pragma mark - Download Uploading File


- (BOOL)startDownloadOfUploadingFile:(QxMediaFile *)mediaFile forCell:(UploadsMediaTableViewCell *)cell atIndex:(NSIndexPath*)indexPath
{
    if (mediaFile && mediaFile.fileName) {
        [cell setupProgressHandler:mediaFile.databaseId];
        DDLogSupport(@"Reupload failed file with name - %@", mediaFile.fileName);
        [self uploadFailedFile:mediaFile];
    }
    return YES;
}

#pragma mark - Actions -

#pragma mark * IBActions

- (IBAction)onBackButton:(id)sender {
    DDLogSupport(@"Back from UploadsMediaViewController");

    for (id controller in appDelegate.navigationController.viewControllers) {
        if ([controller isKindOfClass:[MainViewController class]]) {
            [appDelegate.navigationController popToViewController:controller animated:NO];
            [NSNotificationCenter postNotificationToMainThread:OpenMediaControllerNotification  withObject:nil userInfo:nil];
            break;
        }
    }
    
    if (self.navigationController.presentingViewController && [[self.navigationController viewControllers].firstObject isEqual:self]) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - Notifications -

- (void)updateUploadFiles:(NSNotification *)notification {
    QxMediaFile *mediaFile = [notification object];

    if (mediaFile) {
        for (MediaFileUpload *uploadFile in self.mediaFileUploads) {
            if (uploadFile.mediaFile.databaseId == mediaFile.databaseId) {
                [self.mediaFileUploads removeObject:uploadFile];
                break;
            }
        }
    }
    
    __weak __block typeof(self) weakSelf = self;
    dispatch_async_main(^{
        [weakSelf.tableView reloadData];
    });
}

- (void)reuploadFile:(NSNotification *)notification {
    MediaFileUpload *upload = [notification object];

    if (upload && [upload isFailed]) {
        [self showUploadingUpdatesView];
        [self reupload:upload];
        self.uploadingMediaFile = nil;
    }
}

#pragma mark - Delegate Methods -
#pragma mark * TableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return [[self activeUploadsArray] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *uploadsMediaCellID = @"UploadsMediaTableViewCell_ID";
    UploadsMediaTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:uploadsMediaCellID];
    cell.delegate = self;

    NSMutableArray *array = [self activeUploadsArray];
    if (indexPath.row >= array.count) {
        return nil;
    }
    MediaFileUpload *upload = [array objectAtIndex:indexPath.row];

    [cell setCell:upload withIndexPath:indexPath];
    cell.contentTypeImageView.tag = indexPath.row;
    UITapGestureRecognizer *tapFailedFileGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(uploadFailedFiles:)];
    [cell.contentTypeImageView setUserInteractionEnabled:YES];
    [cell.contentTypeImageView addGestureRecognizer:tapFailedFileGestureRecognizer];

    return cell;
}

- (NSMutableArray *) activeUploadsArray
{
    if (self.isSearching) {
        return self.searchingUploadFiles;
    } else {
        return self.mediaFileUploads;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    MediaFileUpload *upload = [[self activeUploadsArray] objectAtIndex:indexPath.row];
    if (!upload) {
        return;
    }

    MediaFileService *sharedService = [MediaFileService getInstance];
    BaseAttachmentViewController *viewer = nil;
    
    if ([sharedService isDocumentFileMime:[upload.mediaFile.fileName pathExtension] FileName:upload.mediaFile.fileName])
    {
        // Document
        viewer = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([DocumentAttachmentViewController class])];
    }
    else if ([sharedService isAudioFileMime:[upload.mediaFile.fileName pathExtension] FileName:upload.mediaFile.fileName])
    {
        // Audio
        viewer = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([AudioAttachmentViewController class])];
    }
    else if ([sharedService isImageFileMime:[upload.mediaFile.fileName pathExtension] FileName:upload.mediaFile.fileName])
    {
        // Image
        viewer = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ImageAttachmentViewController class])];
    }
    else if ([sharedService isVideoFileMime:[upload.mediaFile.fileName pathExtension] FileName:upload.mediaFile.fileName])
    {
        // Video
        viewer = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([VideoAttachmentViewController class])];
    }
    
    if (viewer) {
        viewer.upload = upload;
        viewer.shouldShowDeleteButton  = YES;
        [self.navigationController pushViewController:viewer animated:YES];
    }
}

#pragma mark * UploadsMediaTableViewCell Delgate

- (BOOL)startDownloadOfUploadingFile:(QxMediaFile *)mediaFile forCell:(id)cell withIndexPath:(NSIndexPath*)indexPath
{
    return [self startDownloadOfUploadingFile:mediaFile forCell:(UploadsMediaTableViewCell*)cell atIndex:indexPath];
}

#pragma mark * UISearchBarField

- (void)doSearch:(NSString *)searchText
{
    NSMutableArray *tmpArr = self.mediaFileUploads;

    SearchOperation * operation = [[SearchOperation alloc] initWithArray:tmpArr andSearchString:searchText withPrioritizedAlphabetically:NO];
    self.searchingUploadFiles = [[operation searchUploadFileForSearchText:searchText] mutableCopy];

    self.isSearching = (operation != nil);

    __weak __block typeof(self) weakSelf = self;
    dispatch_async_main(^{
        [weakSelf.tableView reloadData];
    });
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {

    [self doSearch:searchText];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {

    [self doSearch:searchBar.text];
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text = nil;
    [searchBar resignFirstResponder];
}

#pragma mark * UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.searchBar resignFirstResponder];
}

- (void) uploadFile:(MediaFile *)mediaFile withQliqSTORId:(NSString *)qliqSTORId
{
    if (self.uploadToEMR) {

        if (self.uploadToEmrService == nil) {
            self.uploadToEmrService = [[UploadToEmrService alloc] init];
        }

        if (self.uploadsEMRInfo) {

            EmrUploadParams *uploadTarget = [self.uploadsEMRInfo objectForKey:kUploadTargetKey];
            NSString *emrTargetPublicKey = [self.uploadsEMRInfo objectForKey:kEMRPublicKey];
            NSString *fileName = [self.uploadsEMRInfo objectForKey:kFileNameKey];

            NSString *thumbnail = [self.uploadingMediaFile base64EncodedThumbnail];

            DDLogSupport(@"Start uploading media file with name - %@, with file path - %@ to EMR %@", fileName, mediaFile.decryptedPath, uploadTarget.qliqStorQliqId);
            [self.uploadToEmrService uploadFile:self.uploadingMediaFile.decryptedPath
                                displayFileName:fileName
                                      thumbnail:thumbnail
                                             to:uploadTarget
                                      publicKey:emrTargetPublicKey
                               withCompletition:^(CompletitionStatus status, id result, NSError *error) {
                [self handleUploadToQliqStorCompleted:status error:error];
            } withIsCancelled:nil];
        }
        else {
            DDLogError(@"Can't to start upload media file to EMR, because 'uploadsEMRInfo' dict is nil: %@", self.uploadsEMRInfo);
        }
    }
    else {
        QliqStorUploadParams *uploadTarget = [[QliqStorUploadParams alloc] init];
        [self uploadFile:mediaFile toQliqStorId:qliqSTORId withQliqStorParams:uploadTarget];
    }
}

- (void) uploadFile:(MediaFile *)mediaFile toQliqStorId:(NSString *)qliqStorId withQliqStorParams:(QliqStorUploadParams *)uploadTarget
{
    if (self.uploadToQliqStorService == nil) {
        self.uploadToQliqStorService = [[UploadToQliqStorService alloc] init];
    }
    
    NSString *publicKey = nil;
    NSString *thumbnail = [mediaFile base64EncodedThumbnail];
    
    uploadTarget.uploadUuid = [[NSUUID UUID] UUIDString];
    uploadTarget.qliqStorQliqId = qliqStorId;
    SipContact *qliqStorContact = [[SipContactDBService sharedService] sipContactForQliqId:uploadTarget.qliqStorQliqId];
    if (qliqStorContact) {
        publicKey = qliqStorContact.publicKey;
    }
    
    VoidBlock upload = ^{
        NSString *faxInfo = @"";
        if (uploadTarget.faxNumber.length > 0) {
            faxInfo = [NSString stringWithFormat:@"to fax: %@", uploadTarget.faxNumber];
        }
        DDLogSupport(@"Start uploading media file %@ with name - %@, with file path - %@ to QliqSTOR %@", faxInfo, mediaFile.fileName, mediaFile.decryptedPath, qliqStorId);
        [self.uploadToQliqStorService uploadFile:mediaFile.decryptedPath
                                 displayFileName:mediaFile.fileName
                                       thumbnail:thumbnail
                                              to:uploadTarget
                                       publicKey:publicKey
                                  withCompletion:^(CompletitionStatus status, id result, NSError *error) {
                                      [self handleUploadToQliqStorCompleted:status error:error];
                                  } withIsCancelled:nil];
    };
    
    //For uploding file from QliqSign
    if (![mediaFile.decryptedPath containsString:@"tmp"] || mediaFile.decryptedPath.length == 0) {
        [mediaFile decryptAsyncCompletitionBlock:^{
            upload();
        }];
    }
    else {
        upload();
    }
}

- (void) uploadFaxFile:(MediaFile *)mediaFile toQliqStorId:(NSString *)qliqStorId toFaxContact:(FaxContact *)contact withSubject:(NSString*)subjectText andBody:(NSString*)body
{
    QliqStorUploadParams *uploadTarget = [[QliqStorUploadParams alloc] initWithFaxContact:contact];
    uploadTarget.faxSubject = subjectText;
    uploadTarget.faxBody = body;
    [self uploadFile:mediaFile toQliqStorId:qliqStorId withQliqStorParams:uploadTarget];
}

- (void) uploadFailedFile:(QxMediaFile *)mediaFile
{
    if (self.uploadToQliqStorService == nil) {
        self.uploadToQliqStorService = [[UploadToQliqStorService alloc] init];
    }

    NSString *publicKey = nil;
    NSString *thumbnail = mediaFile.thumbnail;

    QliqStorUploadParams *uploadTarget = [[QliqStorUploadParams alloc] init];
    uploadTarget.uploadUuid = [[NSUUID UUID] UUIDString];
    uploadTarget.qliqStorQliqId = [QliqGroupDBService getFirstQliqStorId];
    SipContact *qliqStorContact = [[SipContactDBService sharedService] sipContactForQliqId:uploadTarget.qliqStorQliqId];
    if (qliqStorContact) {
        publicKey = qliqStorContact.publicKey;
    }

    [self.uploadToQliqStorService uploadFile:mediaFile.decryptedFilePath displayFileName:mediaFile.fileName thumbnail:thumbnail to:uploadTarget publicKey:publicKey withCompletion:^(CompletitionStatus status, id result, NSError *error) {
        [self handleUploadToQliqStorCompleted:status error:error];
    } withIsCancelled:nil];
}

- (void) reupload:(MediaFileUpload *)upload
{
    if (self.uploadToQliqStorService == nil) {
        self.uploadToQliqStorService = [[UploadToQliqStorService alloc] init];
    }
    
    NSString *publicKey = nil;
    SipContact *qliqStorContact = [[SipContactDBService sharedService] sipContactForQliqId:upload.qliqStorQliqId];
    if (qliqStorContact) {
        publicKey = qliqStorContact.publicKey;
    }

    DDLogSupport(@"Reuploading upload: %@, file: %@", upload.uploadUuid, upload.mediaFile.fileName);
    [self.uploadToQliqStorService reuploadFile:upload publicKey:publicKey withCompletion:^(CompletitionStatus status, id result, NSError *error) {
        [self handleUploadToQliqStorCompleted:status error:error];
    } withIsCancelled:nil];
}

- (void) handleUploadToQliqStorCompleted:(CompletitionStatus) status error:(NSError *)error
{
    dispatch_async_main(^{
        [[NSNotificationCenter defaultCenter] postNotificationName:UpdateMediaBadgeNumberNotification object:nil userInfo:nil];
        
        [SVProgressHUD dismiss];
    });
    
    NSString *document = self.faxUpload ? @"fax document" : @"file";
    if (error) {
        
        DDLogSupport(@"Can't to load upload %@, status - %u, error - %@", document, status, error.localizedDescription);
        [AlertController showAlertWithTitle:QliqLocalizedString(@"1072-TextWarning")
                                    message:error.localizedDescription
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOk")
                                 completion:^(NSUInteger buttonIndex) {
                                     [self dismissUploadingViewWithCompletitionStatus:status];
                                 }];
    } else {
        
        DDLogSupport(@"The upload %@ was sent to server, status - %u", document, status);
        [AlertController showAlertWithTitle:@"Info"
                                    message:@"The upload was sent to server"
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOk")
                                 completion:^(NSUInteger buttonIndex) {
                                     [self dismissUploadingViewWithCompletitionStatus:status];
                                 }];
    }
}

- (void) mediaFileUploadEvent:(MediaFileUploadObserverEvent)event databaseId:(int)databaseId
{
    [self reloadUploadFiles];
}


@end
