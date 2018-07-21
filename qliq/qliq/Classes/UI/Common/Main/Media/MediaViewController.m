
//
//  MediaViewController.m
//  qliq
//
//  Created by Valerii Lider on 7/29/14.
//
//

#import "MediaViewController.h"
#import "MediaFileService.h"
#import "MediaFileDBService.h"
#import "MediaTableViewCell.h"
#import "MediaFile.h"
#import "ThumbnailService.h"
#import <MobileCoreServices/MobileCoreServices.h>

#import "ImageAttachmentViewController.h"
#import "DocumentAttachmentViewController.h"
#import "AudioAttachmentViewController.h"
#import "VideoAttachmentViewController.h"
#import "RecordAudioViewController.h"
#import "CreateDocumentViewController.h"
#import "FavoriteContactsViewController.h"
#import "QliqSignViewController.h"
#import "UploadsMediaViewController.h"
#import "MediaFileUploadDBService.h"

#import "QliqConnectModule.h"
#import "MessageAttachmentDBService.h"
#import "ChatMessageService.h"
#import "MessageAttachment.h"
#import "ChatMessage.h"
#import "QliqUserDBService.h"
#import "Helper.h"
#import "MainSettingsViewController.h"
#import "Login.h"
#import "NSDate-Utilities.h"
#import "UIDevice-Hardware.h"
#import "NSString+Filesize.h"
#import "AlertController.h"

#define kViewerMediaFilesArray  @"kViewerMediaFilesArray"
#define kViewerTitle            @"kViewerTitle"
#define kViewerTitleImage       @"kViewerTitleImage"
#define kViewerMimeTypes        @"kViewerMimeTypes"
#define kViewerShowFilenames    @"kViewerShowFilenames"

#define kValueSearchBarHeight 44.f
#define kValueUploadViewHeight 132.f

typedef NS_ENUM(NSInteger, MediaType) {
    MediaTypeDocument   = 1,
    MediaTypeAll        = 2,
    MediaTypePhoto      = 3,
    MediaTypeAudio      = 4,
    MediaTypeVideo      = 5
};

@interface MediaViewController ()
<
UISearchBarDelegate,
UIImagePickerControllerDelegate,
UINavigationControllerDelegate,
RecordAudioViewControllerDelegate,
CreateDocumentViewControllerDelegate,
MediaTableViewCellDelegate
>

/**
 IBOutlet
 */
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIButton *docButton;
@property (weak, nonatomic) IBOutlet UIButton *allButton;
@property (weak, nonatomic) IBOutlet UIButton *cameraButton;
@property (weak, nonatomic) IBOutlet UIButton *audioButton;
@property (weak, nonatomic) IBOutlet UIButton *videoButton;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;

/* Upload to QliqSTOR IBOutlet */
@property (weak, nonatomic) IBOutlet UIView *uploadView;
@property (weak, nonatomic) IBOutlet UIView *uploadQliqSTORView;
@property (weak, nonatomic) IBOutlet UIView *uploadEMRView;
@property (weak, nonatomic) IBOutlet UILabel *uploadEMRBadgeLabel;
@property (weak, nonatomic) IBOutlet UILabel *uploadQliqSTORBadgeLabel;
@property (weak, nonatomic) IBOutlet UILabel *faxesSentBageLabel;

/* Constraints */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchBarHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *uploadViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *uploadEMRViewHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *uploadQliqSTORViewHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *faxesSentViewHeight;

/* Constraints for iPhoneX */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tabBarBackgroundBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerTopConstraint;
@property (weak, nonatomic) IBOutlet UIButton *uploadEMRButton;
@property (weak, nonatomic) IBOutlet UIButton *uploadQliqSTORButton;
@property (weak, nonatomic) IBOutlet UIButton *faxesSentButton;

/**
 UI
 */
@property (nonatomic, strong) UIProgressView *cachingProgress;
@property (nonatomic, strong) UIRefreshControl *refreshControl;

/**
 Data
 */
@property (nonatomic, assign) BOOL isBlockScrollViewDelegate;
@property (nonatomic, assign) BOOL isSearching;
@property (nonatomic, assign) BOOL isEMRUpload;
@property (nonatomic, assign) BOOL showDefaultUploadView;

@property (nonatomic, assign) MediaType *currentMediaType;

@property (nonatomic, strong) NSMutableArray *sortedContacts;
@property (nonatomic, strong) NSMutableArray *searchMediaFiles;
@property (nonatomic, strong) NSArray *mediaGroups;
@property (nonatomic, strong) NSMutableArray *mediaFiles;
@property (nonatomic, strong) NSMutableArray *imagesFromPhotoLibrary;

@property (nonatomic, strong) dispatch_group_t caching_group;
@property (nonatomic, retain) dispatch_queue_t refreshQueue;

@end

@implementation MediaViewController

- (void) dealloc {
    
    self.headerView = nil;
    self.searchBar = nil;
    self.tableView = nil;
    self.docButton = nil;
    self.allButton = nil;
    self.cameraButton = nil;
    self.audioButton = nil;
    self.videoButton = nil;
    self.settingsButton = nil;
    self.searchBarHeightConstraint = nil;
    self.cachingProgress = nil;
    self.refreshControl = nil;
    self.currentMediaType = nil;
    self.sortedContacts = nil;
    self.searchMediaFiles = nil;
    self.mediaGroups = nil;
    self.mediaFiles = nil;
    self.imagesFromPhotoLibrary = nil;
    self.caching_group = nil;
    self.refreshQueue = nil;
    [self removeObserverForCountUploadingMedia];
    self.isEMRUpload = nil;
    self.uploadView = nil;
    self.uploadQliqSTORView = nil;
    self.uploadQliqSTORBadgeLabel = nil;
    self.faxesSentBageLabel = nil;
    
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    /*Change constraint for iPhone X*/
    __block __weak typeof(self) weakSelf = self;
    dispatch_async_main(^{
        isIPhoneX {
            [[NSNotificationCenter defaultCenter]addObserver:weakSelf selector:@selector(rotated:) name:UIDeviceOrientationDidChangeNotification object:nil];
            
            weakSelf.containerTopConstraint.constant = weakSelf.containerTopConstraint.constant + 7.0f;
            weakSelf.tabBarBackgroundBottomConstraint.constant = weakSelf.tabBarBackgroundBottomConstraint.constant -35.0f;
            [weakSelf.view layoutIfNeeded];
        }
    });

    {
        if (!self.mediaFiles)
            self.mediaFiles = [NSMutableArray new];
        
        self.currentMediaType = MediaTypeAll;
    }
    
    self.reloadOnAppering = YES;

    //HeaderView
    // SearchBar
    {
        self.searchBarHeightConstraint.constant = 0.f;
        self.searchBar.placeholder = QliqLocalizedString(@"2107-TitleSearch");
        self.searchBar.delegate = self;
        self.searchBar.autocorrectionType = UITextAutocorrectionTypeYes;
        self.searchBar.spellCheckingType = UITextSpellCheckingTypeYes;
        self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.searchBar.keyboardType = UIKeyboardTypeAlphabet;
        self.isSearching = NO;
    }

    //UploadView
    {
        self.uploadViewHeightConstraint.constant = 0.f;
        self.uploadEMRViewHeight.constant = 0.f;
        self.uploadQliqSTORViewHeight.constant = 0.f;
        self.uploadView.hidden = YES;
        [self changeFrameHeaderView];
    }
    
    //initializing refreshQueue
    self.refreshQueue = dispatch_queue_create("handle_new_media_files", NULL);
    [self reloadGroupsNotification:nil];
    
    //add refresh controil to the table view
    {
        self.refreshControl = [[UIRefreshControl alloc] init];
        [self.refreshControl addTarget:self action:@selector(onPullToRefresh:) forControlEvents:UIControlEventValueChanged];
        [self.tableView addSubview:self.refreshControl];
    }
        
    // Notifications
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didTapBackButton) name:@"didTapBackButton" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(setSelectedSettingsButton:)
                                                     name:kDidShowedCurtainViewNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(openPDFNotificaiton:)
                                                     name:kOpenPDFNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reloadGroupsNotification:)
                                                     name:kRemoveMediaFileAndAttachmentNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(removeAllMediaFilesNotification:)
                                                     name:removeAllMediaFilesNotification
                                                   object:nil];
    }
    [self addObserverForCountUploadingMedia];

    //Upload View
    if ([self needToShowDefaultUploadView]) {
        dispatch_async_main(^{
            [self showUploadView:YES withAnimation:NO];
        });
    };
}

- (void)openPDFNotificaiton:(NSNotification *)notification
{
    self.currentMediaType = MediaTypeDocument;
    self.searchBar.text = @"";
    self.isSearching = NO;
    [self reloadGroups];
    
    DocumentAttachmentViewController *mediaViewer =  [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([DocumentAttachmentViewController class])];
    mediaViewer.mediaFile               = notification.object;
    mediaViewer.shouldShowDeleteButton  = YES;
    
    dispatch_async_main(^{
        if ([SVProgressHUD isVisible])
            [SVProgressHUD dismiss];
    });
    
    [self.navigationController pushViewController:mediaViewer animated:YES];
}

- (void)reloadGroupsNotification:(NSNotification *)notification
{
    __block __weak typeof(self) welf = self;
    dispatch_async(self.refreshQueue, ^{
        DDLogSupport(@"Reloading Media table data");
        [welf reloadGroups];
    });
}

- (void)removeAllMediaFilesNotification:(NSNotification *)notification
{
    dispatch_async(self.refreshQueue, ^{
        DDLogSupport(@"Start removing all media files from db");

        NSArray *uploadedDBFiles = [MediaFileUploadDBService getWithShareType:UploadedToEmrMediaFileUploadShareType skip:0 limit:0];
        for (MediaFileUpload *uploadFile in uploadedDBFiles) {
            [MediaFileUploadDBService removeUploadAndMediaFile:uploadFile.mediaFile];
        }

        uploadedDBFiles = [MediaFileUploadDBService getWithShareType:UploadedToQliqStorMediaFileUploadShareType skip:0 limit:0];

        for (MediaFileUpload *uploadFile in uploadedDBFiles) {
            [MediaFileUploadDBService removeUploadAndMediaFile:uploadFile.mediaFile];
        }
        DDLogSupport(@"Finisted removing all media files from db");
        
        //Deleted thumbs from device when all media files is been deleted
        //Valerii Lider 21/08/17
        DDLogSupport(@"Start removing all thumb files from db");
        
        MediaFileDBService * dbService = [MediaFileDBService sharedService];
        NSArray * thumbs = [dbService mediafiles];
        
        for (int i=0; i<thumbs.count; i++) {
            MediaFile *mediaFile = [thumbs objectAtIndex:i];
            [[ThumbnailService sharedService] removeAllThumbnailsForMediaFile:mediaFile];
        }
        DDLogSupport(@"Finisted removing all thumb files from db");
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.reloadOnAppering)
    {
        [self reloadGroupsNotification:nil];
    }

    //Upload View
    __weak __block typeof(self) welf = self;
    dispatch_async_main(^{
        [welf showUploadView:YES withAnimation:NO];
    });
}

#pragma mark - Private Methods -

- (void)cacheThumbnailsForMediaFiles:(NSArray *)mediaFiles
{
    __block __weak typeof(self) weakSelf = self;
    
    dispatch_group_t group = dispatch_group_create();
    self.caching_group = group;
    
    dispatch_queue_t query = dispatch_queue_create("caching", NULL);
    dispatch_group_async(group, query, ^{
        
        for (MediaFile * file in mediaFiles)
        {
            [file thumbnail];
        }

        weakSelf.caching_group = nil;
    });
}

- (void)onPullToRefresh:(UIRefreshControl *)refreshControl
{
    DDLogSupport(@"Media Files Refresh Called from onPullToRefresh");
    [self.refreshControl endRefreshing];
    
    NSAssert(NULL != self.refreshQueue, @"refreshQueue MUST be initialized before this method get called");
    
    __block __weak typeof(self) weakSelf = self;
    dispatch_async(self.refreshQueue, ^{
        static BOOL performingNow = NO;
        if ([AppDelegate applicationState] == UIApplicationStateBackground)
        {
            // We should try to refresh in the BG also. Because if the App is launched, it takes a while
            // for the app to become active.
            DDLogSupport(@"Refresh called in the BG.");
        }
        
        @synchronized(weakSelf)
        {
            performingNow = YES;
            DDLogSupport(@"Loading all mediaFiles from DB");
            DDLogSupport(@"Reloading table data");
            [weakSelf reloadGroups];
            performingNow = NO;
        }
    });
}

- (void)openUploadsMediaControllerToEMR:(BOOL)uploadToEMR {

    UploadsMediaViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([UploadsMediaViewController class])];
    controller.uploadToEMR = uploadToEMR;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)openFaxesSent {
     DDLogSupport(@"On faxes sent");

    UploadsMediaViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([UploadsMediaViewController class])];
    controller.faxUpload = YES;
    [self.navigationController pushViewController:controller animated:YES];
    
}

- (void)rotated:(NSNotification*)notification {
    
    if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
        
        self.uploadQliqSTORButton.contentEdgeInsets = UIEdgeInsetsMake(0, 50, 0, 0);
        self.uploadEMRButton.contentEdgeInsets      = UIEdgeInsetsMake(0, 50, 0, 0);
    }  else {
        
        self.uploadQliqSTORButton.contentEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 0);
        self.uploadEMRButton.contentEdgeInsets      = UIEdgeInsetsMake(0, 20, 0, 0);
    }
}

#pragma mark * HeaderView

- (BOOL)headerViewIsShow
{
    BOOL isShow = NO;
    
    if (self.headerView.frame.size.height > 0)
        isShow = YES;
    
    return isShow;
}

- (void)setTableViewContentOffsetY:(CGFloat)offset withAnimation:(BOOL)animated
{
    VoidBlock tableContentOffset = ^{
        self.tableView.contentOffset = CGPointMake(self.tableView.contentOffset.x, offset);
//        [self.view layoutIfNeeded];
    };

    if (animated)
    {
        [UIView animateWithDuration:0.3 delay:0.0 options:nil animations:^{
            tableContentOffset();
        } completion:nil];
    }
    else
    {
        tableContentOffset();
    }
}

- (void)showSearchBar:(BOOL)show withAnimation:(BOOL)animated
{
    float constant = show ? kValueSearchBarHeight : 0.f;
    
    if (constant != self.searchBarHeightConstraint.constant)
    {
        VoidBlock updateConstraint = ^{
            self.searchBarHeightConstraint.constant = constant;
            [self changeFrameHeaderView];
            [self.view layoutIfNeeded];
        };

        if (animated)
        {
            [UIView animateWithDuration:0.3 delay:0.0 options:nil animations:^{
                updateConstraint();
                
            } completion:nil];
        }
        else
        {
            updateConstraint();
        }
    }
}

- (void)showUploadView:(BOOL)show withAnimation:(BOOL)animated {

    //Need to update Uploading Files Badge Count
    [self updateMediaBadgeNumber:nil];
    [self showUploadEMRView:show withAnimation:animated];
    [self showUploadQliqSTORView:show withAnimation:YES];

    float constant = show ? self.uploadEMRViewHeight.constant + self.uploadQliqSTORViewHeight.constant + self.faxesSentViewHeight.constant : 0.f;

    if (constant != self.uploadViewHeightConstraint.constant)
    {
        VoidBlock updateConstraint = ^{
            self.uploadViewHeightConstraint.constant = constant;
            self.uploadView.hidden = !show;
            [self changeFrameHeaderView];
            [self.view layoutIfNeeded];
        };
        
        if (animated)
        {
            [UIView animateWithDuration:0.3 delay:0.0 options:nil animations:^{

                updateConstraint();

            } completion:nil];
        }
        else
        {
            updateConstraint();
        }
    }
}

- (void)showUploadQliqSTORView:(BOOL)show withAnimation:(BOOL)animated {

    float constant = 0;
    /*
    if (animated) {
        constant = show ? kValueSearchBarHeight : 0.f;
    }
    else {
        NSRange range = [self.uploadQliqSTORBadgeLabel.text rangeOfString:@"/"];
        NSString *textDBCount = [[self.uploadQliqSTORBadgeLabel.text substringFromIndex:range.location + 1] stringByReplacingOccurrencesOfString:@")" withString:@""];
        NSInteger count = [textDBCount integerValue];
        constant = self.uploadQliqSTORBadgeLabel.text.length > 0 && count > 0 ? kValueSearchBarHeight : 0.f;
    }
     */
//    float constant = show ? kValueSearchBarHeight : 0.f;

    NSRange range = [self.uploadQliqSTORBadgeLabel.text rangeOfString:@"/"];
    NSString *textDBCount = [[self.uploadQliqSTORBadgeLabel.text substringFromIndex:range.location + 1] stringByReplacingOccurrencesOfString:@")" withString:@""];
    NSInteger count = [textDBCount integerValue];
    constant = self.uploadQliqSTORBadgeLabel.text.length > 0 && count > 0 ? kValueSearchBarHeight : 0.f;

    if (constant != self.uploadQliqSTORViewHeight.constant)
    {
        VoidBlock updateConstraint = ^{
            self.uploadQliqSTORViewHeight.constant = constant;
            [self changeFrameHeaderView];
            [self.view layoutIfNeeded];
        };

        if (animated)
        {
            [UIView animateWithDuration:0.3 delay:0.0 options:nil animations:^{
                
                updateConstraint();
               
            } completion:nil];
        }
        else
        {
            updateConstraint();
        }
    }
}

- (void)showUploadEMRView:(BOOL)show withAnimation:(BOOL)animated {

    float constant = 0;

    /*
    if (animated) {
        constant = show ? kValueSearchBarHeight : 0.f;
    }
    else {
        NSRange range = [self.uploadEMRBadgeLabel.text rangeOfString:@"/"];
        NSString *textDBCount = [[self.uploadEMRBadgeLabel.text substringFromIndex:range.location + 1] stringByReplacingOccurrencesOfString:@")" withString:@""];
        NSInteger count = [textDBCount integerValue];
        constant = self.uploadEMRBadgeLabel.text.length > 0 && count > 0 ? kValueSearchBarHeight : 0.f;
    }
     */
//    float constant = show ? kValueSearchBarHeight : 0.f;

    NSRange range = [self.uploadEMRBadgeLabel.text rangeOfString:@"/"];
    NSString *textDBCount = [[self.uploadEMRBadgeLabel.text substringFromIndex:range.location + 1] stringByReplacingOccurrencesOfString:@")" withString:@""];
    NSInteger count = [textDBCount integerValue];
    constant = self.uploadEMRBadgeLabel.text.length > 0 && count > 0 ? kValueSearchBarHeight : 0.f;

    if (constant != self.uploadEMRViewHeight.constant)
    {
        VoidBlock updateConstraint = ^{
            self.uploadEMRViewHeight.constant = constant;
            [self changeFrameHeaderView];
            [self.view layoutIfNeeded];
        };
        
        if (animated)
        {
            [UIView animateWithDuration:0.3 delay:0.0 options:nil animations:^{

                updateConstraint();

            } completion:nil];
        }
        else
        {
            updateConstraint();
        }
    }
}

- (void)changeFrameHeaderView
{
    CGRect frame = self.headerView.frame;
    self.uploadEMRView.hidden = !(self.uploadEMRViewHeight.constant > 0);
    self.uploadQliqSTORView.hidden = !(self.uploadQliqSTORViewHeight.constant > 0);
    frame.size.height = self.searchBarHeightConstraint.constant + self.uploadEMRViewHeight.constant + self.uploadQliqSTORViewHeight.constant + self.faxesSentViewHeight.constant;
    self.headerView.frame = frame;
    [self.tableView setTableHeaderView:self.headerView];
}

- (BOOL)needToShowDefaultUploadView {

    BOOL show = NO;

    if ([MediaFileUploadDBService countWithShareType:UploadedToQliqStorMediaFileUploadShareType] > 0) {
        show = YES;
    }
    else if ([MediaFileUploadDBService countWithShareType:UploadedToEmrMediaFileUploadShareType] > 0) {
        show = YES;
    }
    self.showDefaultUploadView = show;
    return self.showDefaultUploadView;
}

#pragma mark * Data

- (void)reloadGroups
{
    MediaFileService * service = [MediaFileService getInstance];
    MediaFileDBService * dbService = [MediaFileDBService sharedService];
    
    NSArray * imageFiles    = [dbService mediafilesWithMimeTypes:[service imagesMimeTypes] archived:NO];
    NSArray * documentFiles = [dbService mediafilesWithMimeTypes:[service documentsMimeTypes] archived:NO];
    NSArray * audioFiles    = [dbService mediafilesWithMimeTypes:[service audioMimeTypes] archived:NO];
    NSArray * videoFiles    = [dbService mediafilesWithMimeTypes:[service videoMimeTypes] archived:NO];
    
    NSDictionary * imagesOptions =    [NSDictionary dictionaryWithObjectsAndKeys:
                                       imageFiles,                                  kViewerMediaFilesArray,
                                       @"Images",                                   kViewerTitle,
                                       [NSNumber numberWithBool:NO],                kViewerShowFilenames,
                                       [service imagesMimeTypes],                   kViewerMimeTypes,
                                       [UIImage imageNamed:@"icon_photocamera_blue_64x48pt"],    kViewerTitleImage, nil];
    
    NSDictionary * documentOptions =  [NSDictionary dictionaryWithObjectsAndKeys:
                                       documentFiles,                               kViewerMediaFilesArray,
                                       @"Documents",                                kViewerTitle,
                                       [NSNumber numberWithBool:YES],               kViewerShowFilenames,
                                       [service documentsMimeTypes],                kViewerMimeTypes,
                                       [UIImage imageNamed:@"icon_doc_blue_44x60pt"], kViewerTitleImage,nil];
    
    NSDictionary * audioOptions =     [NSDictionary dictionaryWithObjectsAndKeys:
                                       audioFiles,                                  kViewerMediaFilesArray,
                                       @"Audio",                                    kViewerTitle,
                                       [NSNumber numberWithBool:YES],               kViewerShowFilenames,
                                       [service audioMimeTypes],                    kViewerMimeTypes,
                                       [UIImage imageNamed:@"icon_microphon_blue_40x68pt"],     kViewerTitleImage, nil];
    
    NSDictionary * videoOptions =     [NSDictionary dictionaryWithObjectsAndKeys:
                                       videoFiles,                                  kViewerMediaFilesArray,
                                       @"Video",                                    kViewerTitle,
                                       [NSNumber numberWithBool:YES],               kViewerShowFilenames,
                                       [service videoMimeTypes],                    kViewerMimeTypes,
                                       [UIImage new],                               kViewerTitleImage, nil];
    
    self.mediaGroups = [NSArray arrayWithObjects:documentOptions, imagesOptions, audioOptions, videoOptions, nil];
    [self cacheThumbnailsForMediaFiles:imageFiles];
    
    __weak __block typeof(self) welf = self;
//    performBlockInMainThreadSync(^{
        performBlockInMainThread(^{
        [welf sortMediaList:self.currentMediaType reload:NO];
        if (welf.isSearching)
            [welf doSearch:self.searchBar.text];
        else
        {
            [welf.tableView reloadData];
        }
    });
}

- (void)sortMediaWithArray:(NSArray*)array
{
    if (!self.sortedContacts)
        self.sortedContacts = [NSMutableArray new];
    
    self.sortedContacts = [NSMutableArray arrayWithArray:[array sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"mediafileId" ascending:NO]]] ];
}

#pragma mark - Download Attachments

- (BOOL)startDownloadOfMediaFile:(MediaFile *)mediaFile forCell:(MediaTableViewCell *)cell atIndex:(NSIndexPath*)indexPath
{
    NSArray *attachments = [[MessageAttachmentDBService sharedService] getAttachmentsForMediaFileId:mediaFile.mediafileId];

    if ([attachments count] == 0)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:QliqLocalizedString(@"1023-TextError")
                                                                       message:QliqLocalizedString(@"1152-TextCannotFindMessageAttachment")
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *buttonAction = [UIAlertAction actionWithTitle:QliqLocalizedString(@"1-ButtonOK")
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];
        [alert addAction:buttonAction];
        [self presentViewController:alert animated:YES completion:nil];
    
        return NO;
    }
    
    MessageAttachment *attachment = [attachments firstObject];
    
    if ([[MediaFileService getInstance] fileSupportedWithMimeType:mediaFile.mimeType andFileName:mediaFile.fileName])
    {
        switch (attachment.status)
        {
            case AttachmentStatusDownloadFailed:
            case AttachmentStatusToBeDownloaded:
            case AttachmentStatusDownloading: {
                
                __block __weak typeof(self) weakSelf = self;
                [[QliqConnectModule sharedQliqConnectModule] downloadAttachment:attachment completion:^(CompletitionStatus status, id result, NSError * error){
        
                    if (error)
                    {
                        DDLogSupport(@"Can't download attachment %@ error:%@", attachment, error.localizedDescription);
                        
                        /*
                        dispatch_async_main(^{
                            UIAlertView_Blocks * alert = [[UIAlertView_Blocks alloc] initWithTitle:@"Failed to download"
                                                                                           message:[error localizedDescription]
                                                                                          delegate:nil
                                                                                 cancelButtonTitle:@"OK"
                                                                                 otherButtonTitles:nil];
                            [alert showWithDissmissBlock:NULL];
                        });
                         */
                    }
                    else
                    {   
                        MediaFileDBService * dbService = [MediaFileDBService sharedService];
                        MediaFile *newMediaFile = [dbService mediafileWithId:mediaFile.mediafileId];
                        
                        if ([weakSelf.mediaFiles containsObject:mediaFile])
                        {
                            @synchronized (weakSelf.mediaFiles) {
                                NSInteger indexFile = [weakSelf.mediaFiles indexOfObject:mediaFile];
                                [weakSelf.mediaFiles replaceObjectAtIndex:indexFile withObject:newMediaFile];
                            }
                        }
                        
                        if ([weakSelf.sortedContacts containsObject:mediaFile])
                        {
                            @synchronized (weakSelf.sortedContacts) {
                                NSInteger indexFile = [weakSelf.sortedContacts indexOfObject:mediaFile];
                                [weakSelf.sortedContacts replaceObjectAtIndex:indexFile withObject:newMediaFile];
                            }
                        }
                        
                        if ([weakSelf.searchMediaFiles containsObject:mediaFile])
                        {
                            @synchronized (weakSelf.searchMediaFiles) {
                                NSInteger indexFile = [weakSelf.searchMediaFiles indexOfObject:mediaFile];
                                [weakSelf.searchMediaFiles replaceObjectAtIndex:indexFile withObject:newMediaFile];
                            }
                        }
                    }
                }];
                
                [cell setupProgressHandler:attachment.attachmentId];
                return YES;
                break;
            }
        }
        return YES;
    }
    else
    {
        DDLogSupport(@"Can't open media file, mime type - %@, encryptedPath - %@", mediaFile.mimeType, mediaFile.encryptedPath);
        
        return NO;
    }
}

#pragma mark - Notifications -

- (void)setSelectedSettingsButton:(NSNotification *)notification {
    NSNumber *info = [notification object];
    
    if (info) {
        self.settingsButton.selected = [info boolValue];
    }
}

#pragma mark - Failed Uploading Files Badge

- (void)addObserverForCountUploadingMedia {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMediaBadgeNumber:) name:UpdateMediaBadgeNumberNotification object:nil];
}

- (void)removeObserverForCountUploadingMedia {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UpdateMediaBadgeNumberNotification object:nil];
}

- (void)updateMediaBadgeNumber:(NSNotification *)notif {

    __block NSInteger uploadingToQliqStorBadgeCount = 0;
    __block NSInteger uploadingToEMRBadgeCount = 0;
    __block NSInteger uploadingToFaxBadgeCount = 0;
    __block NSInteger successfullyUploadingToQliqStorBadgeCount = 0;
    __block NSInteger successfullyUploadingToEMRBadgeCount = 0;
    __block NSInteger successfullyUploadingToFaxBadgeCount = 0;

    if (notif.userInfo[@"newBadgeValue"])
    {
        uploadingToQliqStorBadgeCount = [notif.userInfo[@"newBadgeValue"] integerValue];
    }
    else
    {
        //Update Media Badge Count from db
        uploadingToQliqStorBadgeCount = [MediaFileUploadDBService countWithShareType:UploadedToQliqStorMediaFileUploadShareType];
        uploadingToEMRBadgeCount = [MediaFileUploadDBService countWithShareType:UploadedToEmrMediaFileUploadShareType];
        uploadingToFaxBadgeCount = [MediaFileUploadDBService countWithShareType:UploadedToFaxMediaFileUploadShareType];

        //Update Media Badge with Successfull status from db
        successfullyUploadingToQliqStorBadgeCount = [MediaFileUploadDBService successfullyCountgWithShareType:UploadedToQliqStorMediaFileUploadShareType skip:0 limit:0];
        successfullyUploadingToEMRBadgeCount = [MediaFileUploadDBService successfullyCountgWithShareType:UploadedToEmrMediaFileUploadShareType skip:0 limit:0];
        successfullyUploadingToFaxBadgeCount = [MediaFileUploadDBService successfullyCountgWithShareType:UploadedToFaxMediaFileUploadShareType skip:0 limit:0];
    }

    DDLogSupport(@"Updated EMR Uploading DB count - %ld with Success - %ld. Updated QliqSTOR Uploading DB count - %ld with Success - %ld. Updated Fax Uploading DB count - %ld with Success - %ld.", (long)uploadingToEMRBadgeCount, (long)successfullyUploadingToEMRBadgeCount,
                 (long)uploadingToQliqStorBadgeCount, (long)successfullyUploadingToQliqStorBadgeCount, (long)uploadingToFaxBadgeCount, (long)successfullyUploadingToFaxBadgeCount);

    __weak __block typeof(self) welf = self;
    welf.uploadQliqSTORBadgeLabel.text = [NSString stringWithFormat:@"(%ld/%ld)", (long)successfullyUploadingToQliqStorBadgeCount,(long)uploadingToQliqStorBadgeCount];
    welf.uploadEMRBadgeLabel.text = [NSString stringWithFormat:@"(%ld/%ld)", (long)successfullyUploadingToEMRBadgeCount, (long)uploadingToEMRBadgeCount];
    welf.faxesSentBageLabel.text = [NSString stringWithFormat:@"(%ld/%ld)", (long)successfullyUploadingToFaxBadgeCount,(long)uploadingToFaxBadgeCount];
}

#pragma mark - - Attachment Notification

- (void)didTapBackButton
{
    [self.navigationController popViewControllerAnimated:NO];
}

#pragma mark - Actions -

#pragma mark * Top Actions

- (void)sortMediaList:(MediaType)type reload:(BOOL)reload
{
    [self.docButton setImage:[UIImage imageNamed:@"MediaSortAll"] forState:UIControlStateNormal];
    [self.allButton setImage:[UIImage imageNamed:@"MediaSortByPicture"] forState:UIControlStateNormal];
    [self.cameraButton setImage:[UIImage imageNamed:@"MediaSortByPhoto"] forState:UIControlStateNormal];
    [self.audioButton setImage:[UIImage imageNamed:@"MediaSortByAudioRec"] forState:UIControlStateNormal];
    [self.videoButton setImage:[UIImage imageNamed:@"MediaSortByVideo"] forState:UIControlStateNormal];
    
    [self.mediaFiles removeAllObjects];
    
    switch (type)
    {
        case MediaTypeDocument: {

            [self.docButton setImage:[UIImage imageNamed:@"MediaSortAllSelected"] forState:UIControlStateNormal];
            
            NSDictionary *options = [self.mediaGroups objectAtIndex:0];
            self.mediaFiles = [[options objectForKey:kViewerMediaFilesArray] mutableCopy];
            break;
        }
            
        case MediaTypeAll: {
            
            [self.allButton setImage:[UIImage imageNamed:@"MediaSortByPictureSelected"] forState:UIControlStateNormal];
            NSArray *array = [NSArray arrayWithArray:self.mediaGroups];
            
            for (NSDictionary *options in array)
            {
                @autoreleasepool {
                    [self.mediaFiles addObjectsFromArray:[options objectForKey:kViewerMediaFilesArray]];
                }
            }
            
            break;
        }
            
        case MediaTypePhoto: {
            
            [self.cameraButton setImage:[UIImage imageNamed:@"MediaSortByPhotoSelected"] forState:UIControlStateNormal];
            
            NSDictionary *options = [self.mediaGroups objectAtIndex:1];
            self.mediaFiles = [[options objectForKey:kViewerMediaFilesArray] mutableCopy];
            break;
        }
            
        case MediaTypeAudio: {
            
            [self.audioButton setImage:[UIImage imageNamed:@"MediaSortByAudioRecSelected"] forState:UIControlStateNormal];
            
            NSDictionary *options = [self.mediaGroups objectAtIndex:2];
            self.mediaFiles = [[options objectForKey:kViewerMediaFilesArray] mutableCopy];
            break;
        }
            
        case MediaTypeVideo: {
            
            [self.videoButton setImage:[UIImage imageNamed:@"MediaSortByVideoSelected"] forState:UIControlStateNormal];
            
            NSDictionary *options = [self.mediaGroups objectAtIndex:3];
            self.mediaFiles = [[options objectForKey:kViewerMediaFilesArray] mutableCopy];
            break;
        }
        default:
            break;
    }
    
    if (reload)
        [self.tableView reloadData];
}

- (IBAction)onSortMediaList:(UIButton*)button
{
    self.currentMediaType = button.tag;
    [self sortMediaList:self.currentMediaType reload:YES];
}

#pragma mark * Bottom Actions

- (IBAction)onSearch:(id)sender
{
    FavoriteContactsViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([FavoriteContactsViewController class])];
    [self.navigationController pushViewController:controller animated:YES];
    controller = nil;
    
    //Code for searchButton
    /*
    BOOL show = self.searchBarHeightConstraint.constant == 0.f ? YES : NO;
    BOOL headerViewIsVisible = self.tableView.contentOffset.y < self.headerView.frame.size.height ? YES : NO;
    show = headerViewIsVisible ? show : YES;

    self.isBlockScrollViewDelegate = YES;
    
    if (show)
    {
        [self.searchBar becomeFirstResponder];
        [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    }
    [self showSearchBar:show withAnimation:YES ];
    
    [self performSelector:@selector(startSearch) withObject:nil afterDelay:0.3];
     */
}

- (void)startSearch
{
    BOOL isSearch = self.searchBarHeightConstraint.constant != 0.f ? YES : NO;
    NSString *searchString =  isSearch ? self.searchBar.text : @"";
    [self doSearch:searchString];
}

- (IBAction)onAddMediaOther:(id)sender
{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:QliqLocalizedString(@"1153-TextChooseTheSource")
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleAlert];
        //        __weak ContactsViewController *weakself = self;
        
        UIAlertAction *inviteFromContacts = [UIAlertAction actionWithTitle:QliqLocalizedString(@"34-ButtonAddAudio")
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction *action) {
            
            RecordAudioViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([RecordAudioViewController class])];
            controller.delegate = self;
            controller.isShowShareButton = YES;
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
            [self.navigationController presentViewController:nav animated:YES completion:nil];
        }];
        
        UIAlertAction *addTextDoc = [UIAlertAction actionWithTitle:QliqLocalizedString(@"2425-ButtonAddTextDoc")
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction *action) {
            
            CreateDocumentViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([CreateDocumentViewController class])];
            ((CreateDocumentViewController*)controller).delegate = self;
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
            [self.navigationController presentViewController:nav animated:YES completion:nil];
        }];
    
        UIAlertAction *addSnapSignDoc = [UIAlertAction actionWithTitle:QliqLocalizedString(@"2426-ButtonAddTextDoc")
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction *action) {
        
        QliqSignViewController *qliqSignViewController = [kMainStoryboard instantiateViewControllerWithIdentifier:@"QliqSignViewController"];

        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:qliqSignViewController];
        [self.navigationController presentViewController:nav animated:YES completion:nil];
    }];
    
    
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:QliqLocalizedString(@"4-ButtonCancel")
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {
            
            [alert dismissViewControllerAnimated:YES completion:nil];
        }];
        
        [alert addAction:inviteFromContacts];
        [alert addAction:addTextDoc];
        [alert addAction:addSnapSignDoc];
        [alert addAction:cancel];
        [self.navigationController presentViewController:alert animated:YES completion:nil];
}

- (IBAction)onAddMediaCamera:(id)sender
{
    __block __weak typeof(self) weakSelf = self;
    [QliqHelper getPickerForMode:PickerModePhotoAndVideo forViewController:self returnPicker:^(id picker, NSError *error) {
        if (error) {
            [AlertController showAlertWithTitle:nil
                                        message:[error.userInfo valueForKey:@"NSLocalizedDescription"]
                                    buttonTitle:nil
                              cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                     completion:NULL];
        } else if (picker) {
            [weakSelf.navigationController presentViewController:picker animated:YES completion:nil];
        }
    }];
}

- (IBAction)onSettings:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kShowCurtainViewNotification object:nil];
}

#pragma mark * Header IBActions

- (IBAction)onUploadToEMR:(id)sender {

    DDLogSupport(@"On Upload to EMR");

    self.isEMRUpload = YES;
    [self openUploadsMediaControllerToEMR:self.isEMRUpload];
}

- (IBAction)onUploadToQliqSTOR:(id)sender {

    DDLogSupport(@"On Uploads to QliqSTOR");

    self.isEMRUpload = NO;
    [self openUploadsMediaControllerToEMR:self.isEMRUpload];
}

-(IBAction)onFaxesSent:(id)sender {
    
    DDLogSupport(@"On Faxes Sent");
    
    [self openFaxesSent];
}

#pragma mark - Delegates -

#pragma mark * UITableViewDataSource/Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = 0;
    count = 1;
    
    if (self.isSearching)
        [self sortMediaWithArray:self.searchMediaFiles];
    else
        [self sortMediaWithArray:self.mediaFiles];
        
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    count = self.sortedContacts.count;
    
    return count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuseId = @"MEDIA_CELL_ID";
    MediaTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    cell.delegate = self;
    
    MediaFile *mediaFile = nil;
    mediaFile = [self.sortedContacts objectAtIndex:indexPath.row];
    
    [cell setCell:mediaFile withIndexPath:indexPath];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MediaFileService *sharedService = [MediaFileService getInstance];
    MediaFile *mediaFile = [self.sortedContacts objectAtIndex:indexPath.row];
    
    if (!mediaFile || [mediaFile.encryptedPath length] == 0) {
        
        MediaTableViewCell *cell = (MediaTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        
        if (![self startDownloadOfMediaFile:mediaFile forCell:cell atIndex:indexPath]) {
            
            DDLogSupport(@"Can't open media file, mime type - %@, encryptedPath - %@", mediaFile.mimeType, mediaFile.encryptedPath);
            
            [AlertController showAlertWithTitle:QliqLocalizedString(@"1023-TextError")
                                        message:QliqLocalizedString(@"3044-TextCanNotOpenMediaFile")
                                    buttonTitle:nil
                              cancelButtonTitle:QliqLocalizedString(@"1-ButtonOk")
                                     completion:nil];
        }
        
        [self.tableView reloadData];
        
    } else {
        
        BaseAttachmentViewController *viewer = nil;
        
        MediaFileType attachmentType = [sharedService typeNameForMime:mediaFile.mimeType FileName:mediaFile.encryptedPath];
        
        switch (attachmentType) {
                
            case MediaFileTypeDocument:{
                viewer = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([DocumentAttachmentViewController class])];
            }
                break;
            case MediaFileTypeAudio:{
                viewer = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([AudioAttachmentViewController class])];
            }
                break;
            case MediaFileTypeVideo:{
                viewer = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([VideoAttachmentViewController class])];
            }
                break;
            case MediaFileTypeImage:{
                viewer = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ImageAttachmentViewController class])];
            }
                break;
            case MediaFileTypeUnknown:{
                DDLogSupport(@"Unknown attachment type - %@, file name - %@", mediaFile.mimeType, mediaFile.encryptedPath);
            }
                break;
                
            default:
                break;
        }
        
        if (viewer) {
            viewer.mediaFile               = mediaFile;
            viewer.shouldShowDeleteButton  = YES;
            [self.navigationController pushViewController:viewer animated:YES];
        } else {
            DDLogSupport(@"Can't open media file, mime type - %@, encryptedPath - %@", mediaFile.mimeType, mediaFile.encryptedPath);
            
            [AlertController showAlertWithTitle:QliqLocalizedString(@"1023-TextError")
                                        message:QliqLocalizedString(@"3044-TextCanNotOpenMediaFile")
                                    buttonTitle:nil
                              cancelButtonTitle:QliqLocalizedString(@"1-ButtonOk")
                                     completion:nil];
        }
    }
}

#pragma mark * MediaTableVieCell Delgate

- (void)startDownloadMediaFile:(MediaFile *)mediaFile withCell:(id)cell withIndexPath:(NSIndexPath *)indexPath
{
    [self startDownloadOfMediaFile:mediaFile forCell:(MediaTableViewCell*)cell atIndex:indexPath];
}

#pragma mark * ScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.y <= -40)
    {
        if (!scrollView.isDecelerating) {
            [self showSearchBar:YES withAnimation:YES];
            if (!self.showDefaultUploadView) {
                [self showUploadView:YES withAnimation:YES];
            }
        }
    }
    else if (scrollView.contentOffset.y > self.headerView.frame.size.height)
    {
        if (0 != self.searchBarHeightConstraint.constant && !self.isBlockScrollViewDelegate)
        {
            [self setTableViewContentOffsetY:self.tableView.contentOffset.y - kValueSearchBarHeight - kValueUploadViewHeight withAnimation:NO];
            [self showSearchBar:NO withAnimation:NO];
            if (!self.showDefaultUploadView) {
                [self showUploadView:NO withAnimation:NO];
            }
        }
    }
    
    if (scrollView.contentOffset.y <= 0)
        self.isBlockScrollViewDelegate = NO;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if ([self headerViewIsShow])
    {
        if (scrollView.contentOffset.y >= 20 && scrollView.contentOffset.y < self.headerView.frame.size.height)
        {
            [self showSearchBar:NO withAnimation:YES];
            if (!self.showDefaultUploadView) {
                [self showUploadView:NO withAnimation:YES];
            }

            [self setTableViewContentOffsetY:self.headerView.frame.size.height withAnimation:YES];
        }
        else if (scrollView.contentOffset.y > 0 && scrollView.contentOffset.y < 20)
        {
            [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
        }
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    // hide the keyboard
    if ([self.searchBar isFirstResponder])
        [self.searchBar resignFirstResponder];
}

#pragma mark * UISearchBarField

- (void)doSearch:(NSString *)searchText
{
    NSMutableArray *tmpArr = self.mediaFiles;
    SearchOperation * operation = [[SearchOperation alloc] initWithArray:tmpArr andSearchString:searchText withPrioritizedAlphabetically:NO];
    self.searchMediaFiles = [[operation search] mutableCopy];
    
    self.isSearching = (operation != nil);
    
    __weak __block typeof(self) weakSelf = self;
    performBlockInMainThread(^{
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
    
    [searchBar resignFirstResponder];
}

#pragma mark - - ImagePickerController Delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    __block __weak typeof(self) weakSelf = self;
    
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        
        CFStringRef type = (__bridge CFStringRef)[info objectForKey:UIImagePickerControllerMediaType];
        
        if (UTTypeEqual(type, kUTTypeImage))
        {
            __unsafe_unretained __block UIImage * weak_image_ref = info[UIImagePickerControllerOriginalImage];
            // Rescale image before saving
            __strong UIImage *strong_image_ref = weak_image_ref;
            
            [self chooseQualityForImage:strong_image_ref attachment:NO withCompletitionBlock:^(ImageQuality quality) {

                [SVProgressHUD showWithStatus:NSLocalizedString(@"1115-TextProcessing", nil)];
                
                ///TODO: redo to Message Attachment
                CGFloat scale = [[QliqAvatar sharedInstance] scaleForQuality:quality];
                NSData * imageData = UIImageJPEGRepresentation(strong_image_ref, scale);//(strong_image_ref);
                
                MediaFile *mediaFile = [[MediaFile alloc] init];
                NSString *contentTypeForImage = [MediaFile contentTypeForImageData:imageData];
                
                mediaFile.fileName = [MediaFile generateImageFilenameWithImageType:contentTypeForImage];
                mediaFile.mimeType = [NSString stringWithFormat:@"image/%@", contentTypeForImage];
                mediaFile.timestamp = [NSDate date].timeIntervalSince1970;
                mediaFile.decryptedPath = [NSString stringWithFormat:@"%@%@",kDecryptedDirectory,mediaFile.fileName];
                
                //Request for thumbnail to cache it
                [[ThumbnailService sharedService] thumbnailForMediaFile:mediaFile];
                
                [mediaFile saveDecryptedData:imageData];
                [mediaFile encrypt];
                [mediaFile save];
                
                [SVProgressHUD dismiss];
                
                //Open MediaFile
                ImageAttachmentViewController *mediaViewer = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ImageAttachmentViewController class])];
                mediaViewer.mediaFile = mediaFile;
                mediaViewer.shouldShowDeleteButton  = YES;
                [weakSelf.navigationController pushViewController:mediaViewer animated:YES];
            }];
        }
        else if (UTTypeEqual(type, kUTTypeMovie))
        {
            [[QliqAvatar sharedInstance] convertVideo:info[UIImagePickerControllerMediaURL] usingBlock:^(NSURL *convertedVideoUrl, BOOL completed, RemoveBlock block) {
                
                if (completed) {
                    MediaFile *mediaFile = [[MediaFile alloc] init];
                    mediaFile.fileName = [MediaFile generateVideoFilename];
                    mediaFile.mimeType = @"video/mp4";
                    mediaFile.timestamp = [NSDate date].timeIntervalSince1970;
                    mediaFile.decryptedPath = convertedVideoUrl.path;
                    
                    [[ThumbnailService sharedService] thumbnailForMediaFile:mediaFile];
                    [mediaFile encrypt];
                    [mediaFile save];
                    
                    //Open MediaFile
                    VideoAttachmentViewController *mediaViewer = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([VideoAttachmentViewController class])];
                    mediaViewer.mediaFile = mediaFile;
                    mediaViewer.shouldShowDeleteButton = YES;
                    mediaViewer.removeBlock = block;
                    [weakSelf.navigationController pushViewController:mediaViewer animated:YES];
                }
//                block();
            }];
        }
        
//        [self reloadGroups];
        
        [SVProgressHUD dismiss];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (UIImage *)imageFromImage:(UIImage *)image scaledTo:(CGFloat) scale
{
    CGSize targetSize = [image size];
    targetSize.width *= scale;
    targetSize.height *= scale;
    
    return [[ThumbnailService sharedService] resizeImage:image toSize:targetSize contentMode:UIViewContentModeScaleToFill];;
}

- (void)chooseQualityForImage:(UIImage *)image attachment:(BOOL)isAttachment withCompletitionBlock:(void(^)(ImageQuality quality))completeBlock {
    
    NSUInteger estimatedSmall, estimatedMedium, estimatedLarge, estimatedActual;
    
    estimatedActual = [[QliqAvatar sharedInstance] estimatedFileSizeOfImage:image andQuality:ChoosedQualityOriginal attachment:isAttachment];
    estimatedSmall  = [[QliqAvatar sharedInstance] estimatedFileSizeOfImage:image andQuality:ChoosedQualityLow      attachment:isAttachment];
    estimatedMedium = [[QliqAvatar sharedInstance] estimatedFileSizeOfImage:image andQuality:ChoosedQualityMedium   attachment:isAttachment];
    estimatedLarge  = [[QliqAvatar sharedInstance] estimatedFileSizeOfImage:image andQuality:ChoosedQualityHight    attachment:isAttachment];
    
    NSString * originalTitle = [NSString stringWithFormat:@"%@ (%@)", NSLocalizedString(@"2016-TitleActualSize", nil),[NSString fileSizeFromBytes:estimatedActual]];
    
    NSString * mediumTitle =   [NSString stringWithFormat:@"%@ (%@)", NSLocalizedString(@"2017-TitleMedium", nil),    [NSString fileSizeFromBytes:estimatedMedium]];
    
    NSString * largeTitle =    [NSString stringWithFormat:@"%@ (%@)", NSLocalizedString(@"2018-TitleLarge", nil),     [NSString fileSizeFromBytes:estimatedLarge]];
    
    NSString * smallTitle =    [NSString stringWithFormat:@"%@ (%@)", NSLocalizedString(@"2019-TitleSmall", nil),     [NSString fileSizeFromBytes:estimatedSmall]];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"1168-TextChooseImageQuality", nil)
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:smallTitle
                                              style:UIAlertActionStyleDefault
                                            handler:^void (UIAlertAction *action) {
                                                if (completeBlock)
                                                    completeBlock(0);
                                            }]];
    [alert addAction:[UIAlertAction actionWithTitle:mediumTitle
                                              style:UIAlertActionStyleDefault
                                            handler:^void (UIAlertAction *action) {
                                                if (completeBlock)
                                                    completeBlock(1);
                                            }]];
    [alert addAction:[UIAlertAction actionWithTitle:largeTitle
                                              style:UIAlertActionStyleDefault
                                            handler:^void (UIAlertAction *action) {
                                                if (completeBlock)
                                                    completeBlock(2);
                                            }]];
    [alert addAction:[UIAlertAction actionWithTitle:originalTitle
                                              style:UIAlertActionStyleDefault
                                            handler:^void (UIAlertAction *action) {
                                                if (completeBlock)
                                                    completeBlock(3);
                                            }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    
    alert.preferredContentSize = CGSizeMake(450, 350);
    alert.popoverPresentationController.sourceView =self.view;
    alert.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMaxY(self.view.bounds)-50, 0, 0);
    alert.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - - RecordAudioViewControllerDelegate

- (void)recordAudioController:(RecordAudioViewController *)recordVC didRecordedMedaFile:(MediaFile *)mediaFile {
    [mediaFile save];
}

#pragma mark - - CreateDocumentViewControllerDelegate

- (void)createDocumentViewController:(CreateDocumentViewController *)document didCreateddMediaFile:(MediaFile *)mediaFile { }

@end
