//
//  ImagesViewController.m
//  qliqConnect
//
//  Created by Paul Bar on 12/15/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import "MediaGridViewController.h"
//#import "QliqButton.h"
#import "MediaGridCollectionViewCell.h"

#import "MediaFile.h"
#import "AlertController.h"
#import "QliqSignViewController.h"

#import "MessageAttachment.h"

#import "MessageAttachmentDBService.h"
#import "QliqConnectModule.h"
#import "MediaFileDBService.h"
#import "MediaFileService.h"

#import "KeyboardAccessoryViewController.h"

#import "DocumentAttachmentViewController.h"
#import "VideoAttachmentViewController.h"
#import "ImageAttachmentViewController.h"
#import "AudioAttachmentViewController.h"

@interface MediaGridViewController() <UICollectionViewDataSource, UICollectionViewDelegate>

/**
 IBOutlets
 */
@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

/**
 UI
 */
@property (nonatomic, strong) UIToolbar * optionsToolbar;

/**
 Data
 */
@property (nonatomic, assign) BOOL showFilenames;
@property (nonatomic, assign) BOOL selectionMode;
@property (nonatomic, assign) BOOL showArchiveFolder;

@property (nonatomic, strong) NSMutableArray *selectedMediafiles;

@end

@implementation MediaGridViewController

- (void)dealloc {
    self.optionsToolbar = nil;
    [self.selectedMediafiles removeAllObjects];
    self.selectedMediafiles = nil;
    self.mediafiles = nil;
    self.keyboardAccessoryViewController = nil;
    self.viewOptions = nil;
    self.fromSupportSettings = nil;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        self.selectionMode      = NO;
        self.showArchiveFolder  = YES;
        self.selectedMediafiles = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)configureDefaultText {
    [self.cancelButton setTitle:QliqLocalizedString(@"4-ButtonCancel") forState:UIControlStateNormal];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.viewArhive) {
        self.cancelButton.hidden = YES;
        self.navigationItem.title = QliqLocalizedString(@"2419-QliqGallery");
    } else {
        self.cancelButton.hidden = NO;
        self.navigationItem.title = @"";
    }
    
    if (self.mediafiles.count == 0) {
        [self getFiles];
    }
    
    [self configureDefaultText];
    
    //OptionsToolbar
    {
        self.optionsToolbar = [self newOptionsToolbar];
        [self.view addSubview:self.optionsToolbar];
    }
        
    //CollectionView
    {
        self.collectionView.userInteractionEnabled = YES;
    }
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.collectionView reloadData];
    [self doLayout];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

#pragma mark - Diferent -

- (UIBarButtonItem *) barItemWithTitle:(NSString *) title target:(id) target action: (SEL) action{
    
    UIImage *enabledImage = [UIImage imageNamed:@"qliqBlueButton.png"];
    UIImage *disabledImage = [UIImage imageNamed:@"qliqGrayButton.png"];
    
    UIButton * btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 65, 35)];
    [btn setBackgroundImage:enabledImage forState:UIControlStateNormal];
    [btn setBackgroundImage:disabledImage forState:UIControlStateDisabled];
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
    btn.titleLabel.textColor = [UIColor whiteColor];
    [btn setTitle:title forState:UIControlStateNormal];
    
    [btn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    
    return [[UIBarButtonItem alloc] initWithCustomView:btn];
}

- (UIToolbar *) newOptionsToolbar{
    
    UIToolbar * toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [toolbar setBarStyle:UIBarStyleBlackTranslucent];
    
    UIBarButtonItem * share = [self barItemWithTitle:NSLocalizedString(@"2014-TitleShare", nil) target:self action:@selector(share)];
    UIBarButtonItem * archive = [self barItemWithTitle:NSLocalizedString(@"2015-TitleArchive", nil) target:self action:@selector(archive)];
    //    UIBarButtonItem * delete = [self barItemWithTitle:@"Delete" target:self action:@selector(delete)];
    UIBarButtonItem * space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    NSMutableArray * buttonsArray= [[NSMutableArray alloc] init];
    [buttonsArray addObjectsFromArray:[NSArray arrayWithObjects:space,share,space, nil]];
    if (!self.viewArhive)  [buttonsArray addObjectsFromArray:[NSArray arrayWithObjects:archive,space, nil]];
    //    [buttonsArray addObjectsFromArray:[NSArray arrayWithObjects:delete,space, nil]];
    
    [toolbar setItems:buttonsArray];
    
//    UIImage * image = [UIImage imageNamed:@"bg-toolbar"];
//    [toolbar setBackgroundImage:image];
    
    return toolbar;
}

- (void) setButtonsEnabled:(BOOL) _enabled{
    for (UIBarButtonItem * barItem in [self.optionsToolbar items]){
        if ([barItem.customView isKindOfClass:[UIButton class]]){
            ((UIButton *)barItem.customView).enabled = _enabled;
        }
    }
}

- (void)doLayout
{
    self.optionsToolbar.alpha = self.selectionMode;
    
    //    self.tableView.frame = self.view.bounds;
    
    CGRect frame = self.optionsToolbar.frame;
    frame.origin.y = self.view.bounds.size.height - frame.size.height;
    self.optionsToolbar.frame = frame;
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    [super loadView];
    
    //    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    //    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleSize;
    //    self.tableView.delegate = self;
    //    self.tableView.dataSource = self;
    //    [self.view addSubview:self.tableView];
    //
    //    self.tableView.separatorStyle = 1;
    //    self.tableView.backgroundColor = [UIColor colorWithWhite:0.2039f alpha:1.0f];
    //    self.tableView.separatorColor = [UIColor colorWithWhite:0.2039f alpha:1.0f];
    //    self.tableView.bounces = YES;
    //    self.view.backgroundColor = [UIColor colorWithWhite:0.2039f alpha:1.0f];
    
    //    self.collectionView.backgroundColor = [UIColor redColor];
    
    if(!self.viewArhive && self.keyboardAccessoryViewController == nil)
    {
        UIButton *viewArchiveButton = [[UIButton alloc] init];
        viewArchiveButton.backgroundColor = [UIColor colorWithWhite:0.2039f alpha:1.0f];//self.tableView.backgroundColor;
        viewArchiveButton.frame = CGRectMake(0.0,
                                             0.0,
                                             0.0,
                                             50.);//[self tableView:self.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]
        [viewArchiveButton setTitle:@"View archive" forState:UIControlStateNormal];
        [viewArchiveButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        viewArchiveButton.titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
        [viewArchiveButton addTarget:self action:@selector(presentArchive) forControlEvents:UIControlEventTouchUpInside];
        //        self.tableView.tableFooterView = viewArchiveButton;
    }
}

AUTOROTATE_METHOD

#pragma mark - Setters -

- (void)setViewOptions:(NSDictionary *)viewOptions
{
    _viewOptions = viewOptions;
    
    self.showFilenames = [[self.viewOptions valueForKey:kViewerShowFilenames] boolValue];
    [self getFiles];
}

#pragma mark - Private -

- (void)getFiles
{
    MediaFileService * service = [MediaFileService getInstance];
    MediaFileDBService * dbService = [MediaFileDBService sharedService];

    NSString *tittle = [self.viewOptions objectForKey:kViewerTitle];

    if ([tittle isEqualToString:@"Images"]) {
        self.mediafiles = [dbService mediafilesWithMimeTypes:[service imagesMimeTypes] archived:NO];
    }
    else if ([tittle isEqualToString:@"Documents"]) {
        self.mediafiles = [dbService mediafilesWithMimeTypes:[service documentsMimeTypes] archived:NO];
    }
    else if ([tittle isEqualToString:@"Audio"]) {
        self.mediafiles = [dbService mediafilesWithMimeTypes:[service audioMimeTypes] archived:NO];
    }
    else if ([tittle isEqualToString:@"Video"]) {
        self.mediafiles = [dbService mediafilesWithMimeTypes:[service videoMimeTypes] archived:NO];
    }

    if (self.mediafiles.count != 0)
        self.mediafiles = [NSMutableArray arrayWithArray:[self.mediafiles sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"mediafileId" ascending:NO]]] ];
}

- (void)toggleSelectionMode{
    
    self.selectionMode = !self.selectionMode;
    
    [UIView animateWithDuration:0.2 animations:^{
        [self doLayout]; 
    }];
    
    if(!self.selectionMode && [self.selectedMediafiles count] > 0){
        [self.selectedMediafiles removeAllObjects];
        [self.collectionView reloadData];
    }
}

- (void)deleteFromArrayFile:(MediaFile *)mediaFile{
    NSMutableArray * mediafilesMutable = [NSMutableArray arrayWithArray:self.mediafiles];
    [mediafilesMutable removeObject:mediaFile];
    self.mediafiles = [NSArray arrayWithArray:mediafilesMutable];
}

- (void)share
{
    
}

- (void)archive
{
    if([self.selectedMediafiles count] > 0)
    {
        [[MediaFileDBService sharedService] markAsArchivedMediafiles:[NSArray arrayWithArray:self.selectedMediafiles]];
        for (MediaFile * _file in self.selectedMediafiles){
            [self deleteFromArrayFile:_file];
        }
        [self.selectedMediafiles removeAllObjects];
        [self.collectionView reloadData];
    }
}

- (void)delete
{
    if([self.selectedMediafiles count] > 0)
    {
        [[MediaFileDBService sharedService] markAsDeletedMediafiles:[NSArray arrayWithArray:self.selectedMediafiles]];
        for (MediaFile * _file in self.selectedMediafiles){
            [self deleteFromArrayFile:_file];
        }
        [self.selectedMediafiles removeAllObjects];
        [self.collectionView reloadData];
    }
}

- (void)presentArchive {
    
    MediaGridViewController *ctrl = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([MediaGridViewController class])];
    ctrl.viewArhive = YES;
    
    NSMutableDictionary * options = [NSMutableDictionary dictionaryWithDictionary:self.viewOptions];
    [options setValue:[[MediaFileDBService sharedService] mediafilesWithMimeTypes:[options valueForKey:kViewerMimeTypes] archived:YES] forKey:kViewerMediaFilesArray];
    ctrl.viewOptions = options;
    [self.navigationController pushViewController:ctrl animated:YES];
}

- (void)cancelButtonPressed {

    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)startDownloadOfMediaFile:(MediaFile *)mediaFile forCell:(MediaGridCollectionViewCell *)cell
{
    NSArray *attachments = [[MessageAttachmentDBService sharedService] getAttachmentsForMediaFileId:mediaFile.mediafileId];
    if ([attachments count] == 0) {
        
        [AlertController showAlertWithTitle:QliqLocalizedString(@"1023-TextError")
                                    message:QliqLocalizedString(@"1152-TextCannotFindMessageAttachment")
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                 completion:nil];
        return NO;
    }
    MessageAttachment *attachment = attachments[0];
    
	if ([[MediaFileService getInstance] fileSupportedWithMimeType:mediaFile.mimeType andFileName:mediaFile.fileName]) {
        
		switch (attachment.status)
		{
            case AttachmentStatusDownloadFailed:
			case AttachmentStatusToBeDownloaded:{
				
                [[QliqConnectModule sharedQliqConnectModule] downloadAttachment:attachment completion:^(CompletitionStatus status, id result, NSError * error){
					if (error){
                        dispatch_async_main(^{
                            
                            [AlertController showAlertWithTitle:QliqLocalizedString(@"1063-TextFailedDownload")
                                                        message:[error localizedDescription]
                                                    buttonTitle:nil
                                              cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                                     completion:nil];
                        });
					} else {
                        // Open the file
                        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
                        @try {
                            [self collectionView:self.collectionView didHighlightItemAtIndexPath:indexPath];
                        }
                        @catch (NSException *exception) {
                        }
                    }
				}];
                NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
                [cell setupProgressHandler:attachment.attachmentId atIndex:indexPath.row];
                return YES;
                break;
			}
            default: {
                [self.delegate mediaGridViewController:self didSelectMediaFile:mediaFile];
                [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                break;
            }
        }
        return NO;
    } else {
        
        [AlertController showAlertWithTitle:QliqLocalizedString(@"1023-TextError")
                                    message:QliqLocalizedString(@"1004-TextUnsupportedFile")
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                 completion:nil];
        return  NO;
    }
}

#pragma mark - Actions -

- (IBAction)onBack:(id)sender {
    
    if (self.navigationController.presentingViewController && [[self.navigationController viewControllers].firstObject isEqual:self]) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)onCancel:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Delegates -

#pragma mark - UICollectionViewDelegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.mediafiles.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuseID = @"MEDIA_GRID_ITEM_CELL_ID";
    MediaGridCollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:reuseID forIndexPath:indexPath];
    
    MediaFile *mediaFile = self.mediafiles[indexPath.row];
    cell.thumbnailImageView.hidden = NO;
    cell.thumbnailImageView.image = mediaFile.thumbnail;
    [cell setSelected:[self.selectedMediafiles containsObject:mediaFile]];
 
    if (self.showFilenames) {
        [cell setName:mediaFile.fileName];
        cell.mediafileNameLabel.hidden = NO;
    }
    else {
        cell.mediafileNameLabel.hidden = YES;
    }
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(kMediaGridCollectionViewCellWidth, kMediaGridCollectionViewCellHeight);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    __block MediaFile *mediaFile = self.mediafiles[indexPath.row];
    // Reload from db because the file could changed since the view was loaded
    mediaFile = [[MediaFileDBService sharedService] mediafileWithId:mediaFile.mediafileId];
    
    MediaGridCollectionViewCell *cell = (MediaGridCollectionViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
    
    __weak __block typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.2 delay:0.3 usingSpringWithDamping:1.0 initialSpringVelocity:1.0 options:0 animations:^{
        cell.thumbnailImageView.hidden = YES;
        [weakSelf.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        cell.thumbnailImageView.hidden = NO;
    }];
    
    if(!self.selectionMode)
    {
        if (!mediaFile || [mediaFile.encryptedPath length] == 0)
        {
            [self startDownloadOfMediaFile:mediaFile forCell:cell];
        }
        else
        {
            //Documents
            if ([[MediaFileService getInstance] isDocumentFileMime:mediaFile.mimeType FileName:mediaFile.encryptedPath])
            {
                DocumentAttachmentViewController *mediaViewer =  [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([DocumentAttachmentViewController class])];
                mediaViewer.mediaFile = mediaFile;
                mediaViewer.shouldShowDeleteButton = YES;
                mediaViewer.shouldDismissController = YES;
                mediaViewer.viewMode = self.isGetMediaForConversation;
                [self.navigationController pushViewController:mediaViewer animated:YES];
            }
            
            //Audio
            if ([[MediaFileService getInstance] isAudioFileMime:mediaFile.mimeType FileName:mediaFile.encryptedPath])
            {
                AudioAttachmentViewController *mediaViewer = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([AudioAttachmentViewController class])];
                mediaViewer.mediaFile = mediaFile;
                mediaViewer.shouldShowDeleteButton = YES;
                mediaViewer.shouldDismissController = YES;
                mediaViewer.viewMode = self.isGetMediaForConversation;
                [self.navigationController pushViewController:mediaViewer animated:YES];
            }
            
            //Image
            if ([[MediaFileService getInstance] isImageFileMime:mediaFile.mimeType FileName:mediaFile.encryptedPath])
            {
                if (self.fromSupportSettings) {
                    ImageAttachmentViewController *mediaViewer = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ImageAttachmentViewController class])];mediaViewer.mediaFile = mediaFile;
                    mediaViewer.shouldShowDeleteButton = YES;
                    mediaViewer.shouldDismissController = YES;
                    mediaViewer.viewMode = self.isGetMediaForConversation;
                    [self.navigationController pushViewController:mediaViewer animated:YES];
                }
                else {
                    if (self.viewArhive==YES) {
                        
                        if (mediaFile) {
                            [self.delegate mediaGridViewController:self didSelectMediaFile:mediaFile];
                        }
                        else
                        {
                            
                            [AlertController showAlertWithTitle:QliqLocalizedString(@"1023-TextError")
                                                        message:QliqLocalizedString(@"1938-StatusErrorCannotFindAttachment")
                                               buttonTitle:nil
                                              cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                                     completion:nil];
                        }
                    } else {
                        MessageAttachment *attachment = [[ MessageAttachment alloc ] initWithMediaFile:mediaFile];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"AddAttachmentToMessage" object:attachment userInfo:nil];
                        
                        [self onCancel:nil];
                    }
                }
            }
            
            //Video
            if ([[MediaFileService getInstance] isVideoFileMime:mediaFile.mimeType FileName:mediaFile.encryptedPath])
            {
                VideoAttachmentViewController *mediaViewer = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([VideoAttachmentViewController class])];
                mediaViewer.mediaFile = mediaFile;
                mediaViewer.shouldShowDeleteButton = YES;
                mediaViewer.shouldDismissController = YES;
                mediaViewer.viewMode = self.isGetMediaForConversation;
                [self.navigationController pushViewController:mediaViewer animated:YES];
            }
        }
    }
    else
    {
        if([self.selectedMediafiles containsObject:mediaFile])
        {
            [self.selectedMediafiles removeObject:mediaFile];
            [cell setSelected:NO];
        }
        else
        {
            [cell setSelected:YES];
            [self.selectedMediafiles addObject:mediaFile];
        }
    }
}

@end
