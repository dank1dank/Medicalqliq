//
//  MediaGroupsListViewController.m
//  qliqConnect
//
//  Created by Paul Bar on 12/15/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import "MediaGroupsListViewController.h"

#import "MediaGridViewController.h"

#import <QuartzCore/QuartzCore.h>

#import "MediaFile.h"
#import "ThumbnailService.h"

#import "MediaFileService.h"
#import "MediaFileDBService.h"

@interface MediaGroupsListViewController() <MediaGridViewControllerDelegate>
{
    UIView * cachingView;
    UIProgressView * cachingProgress;
    dispatch_group_t caching_group;
}


@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSArray *mediaGroups;

@end


@implementation MediaGroupsListViewController

- (void)configureDefaultText {
    [self.cancelButton setTitle:QliqLocalizedString(@"4-ButtonCancel") forState:UIControlStateNormal];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureDefaultText];
    
    //TableView
    {
         self.tableView.tableFooterView = [[ UIView alloc ] initWithFrame:CGRectZero];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadGroups];
}

- (void)dealloc{
    self.fromSupportSettings = nil;
}

#pragma mark - Private - 

- (void)reloadGroups
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
    
//    [self cacheThumbnailsForMediaFiles:imageFiles];
    [self.tableView reloadData];
}

- (UIView *) newCachingView{
    CGSize parentSize = self.view.bounds.size;// CGSizeMake(320, 366);
    CGSize viewSize = CGSizeMake(240, 90);
    
    UIView * view = [[UIView alloc] initWithFrame:CGRectMake((parentSize.width - viewSize.width)/2, (parentSize.height - viewSize.height)/2, viewSize.width, viewSize.height)];
    view.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
    view.layer.cornerRadius = 5.0f;
    
    UILabel * descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, viewSize.width-20, 40)];
    [descriptionLabel setText:@"Reloading Media Library"];
    descriptionLabel.backgroundColor = [UIColor clearColor];
    descriptionLabel.textColor = [UIColor whiteColor];
    [view addSubview:descriptionLabel];
    
    UIProgressView * progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(10, viewSize.height-20, viewSize.width-20, 10)];
    [progressView setProgressViewStyle:UIProgressViewStyleBar];
    progressView.progress = 0.0;
    progressView.tag = 0xFF;
    [view addSubview:progressView];
    
    return view;
}

- (void) cacheThumbnailsForMediaFiles:(NSArray *) _mediaFiles{
    
    dispatch_group_t group = dispatch_group_create();
    caching_group = group;
    
    dispatch_queue_t query = dispatch_queue_create("caching", NULL);
    dispatch_group_async(group, query, ^{
        
        
        BOOL showProgress = [[ThumbnailService sharedService] numberToGenerateForMediaFiles:_mediaFiles] > 0;
        __block int i = 0;
        for (MediaFile * file in _mediaFiles){
            [file thumbnail];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (cachingView.alpha != 1 && showProgress){
                    [UIView animateWithDuration:0.3 animations:^{
                        cachingView.alpha = 1;
                    }];
                }
                cachingProgress.progress = ++i / (float) [_mediaFiles count];
            });
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.3 animations:^{
                cachingView.alpha = 0;
            } completion:^(BOOL finished){
                
            }];
        });
        caching_group = nil;
    });
    //    dispatch_release(query);
    //    dispatch_release(group);
    
}

#pragma mark - Actions -

- (IBAction)onCancel:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Delegates -

#pragma mark * UITableView Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.mediaGroups.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *reuseId = @"GROUPS_CELL_ID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId forIndexPath:indexPath];
    
    NSDictionary * group = self.mediaGroups[indexPath.row];
    cell.imageView.image        = group[kViewerTitleImage];
    cell.textLabel.text         = group[kViewerTitle];
    cell.detailTextLabel.text   = [NSString stringWithFormat:@"(%lu)", (unsigned long)[group[kViewerMediaFilesArray] count]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (caching_group)
    {
        cachingView.alpha = 1.0;
        
        dispatch_group_notify(caching_group, dispatch_get_main_queue(), ^{
            [self tableView:tableView didSelectRowAtIndexPath:indexPath];
        });
        return;
    }
    
    MediaGridViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([MediaGridViewController class])];
    controller.viewOptions = self.mediaGroups[indexPath.row];
    controller.delegate = self;
    controller.fromSupportSettings = YES;
    controller.isGetMediaForConversation = self.isGetMediaForConversation;
    [self.navigationController pushViewController:controller animated:YES];

    [self.tableView reloadData];
}


#pragma mark * MediaGridViewController Delegate

- (void)mediaGridViewController:(MediaGridViewController*)controller didSelectMediaFile:(MediaFile *)mediaFile
{
    [self.delegate mediaGroupsListViewController:self didSelectMediaFile:mediaFile];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
