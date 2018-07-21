//
//  UploadsMediaTableViewCell.m
//  qliq
//
//  Created by Valerii Lider on 04/11/2017.
//
//

#import "UploadsMediaTableViewCell.h"
#import "MediaFileUpload.h"

#import "NSDate-Utilities.h"
#import "MediaFileService.h"

#define kUploadingStatus @"Sharing"
#define kUploadedToCloudStatus @"Shared to Cloud"
#define kFinalProcessingSuccesfulStatus @"Shared"
#define kSharingFailed @"Sharing Failed"

#define kBlueColor RGBa(0, 120, 174, 1)

@interface UploadsMediaTableViewCell () <ProgressObserver>

//IBOutlets
@property (nonatomic, weak) IBOutlet UILabel *fileNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *fileStatusLabel;
@property (nonatomic, weak) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *checkMarkQliqCloud;
@property (weak, nonatomic) IBOutlet UIImageView *checkMarkQliqStor;

//Constrints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *fileStatusLabelLeadingConstraint;

//Progress Handler
@property (nonatomic, strong) UIProgressView *progressBar;

@end

@implementation UploadsMediaTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    // Initialization code
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.selectedBackgroundView = [[UIView alloc] init];
    self.selectedBackgroundView.backgroundColor = [UIColor clearColor];

    self.progressBar = [[UIProgressView alloc] initWithFrame:CGRectMake(5, 32, 30, 15)];
    self.progressBar.backgroundColor = [UIColor redColor];

    [self.contentTypeImageView addSubview:self.progressBar];
    [self.progressBar setHidden:YES];

    self.checkMarkQliqCloud.hidden = YES;
    self.checkMarkQliqStor.hidden = YES;

    self.fileStatusLabel.textColor = kBlueColor;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setCell:(id)item withIndexPath:(NSIndexPath *)indexPath
{
    if ([item isKindOfClass:[MediaFileUpload class]])
    {
        MediaFileUpload *upload = item;
        QxMediaFile *mediaFile = upload.mediaFile;

        self.contentTypeImageView.image = [UIImage imageNamed:@"KeyboardGroupDocuments"];
        self.contentTypeImageView.image = [mediaFile thumbnailAsImage];
        self.contentTypeImageView.backgroundColor = [UIColor clearColor];

        //Need to update uploading status
        self.fileStatusLabel.text = [upload statusToUiText];
        self.fileStatusLabel.textColor = kBlueColor;

        switch (upload.status) {
            case UnknownMediaFileUploadStatus: {

                break;
            }
            case PendingUploadMediaFileUploadStatus: {

                break;
            }
            case UploadingMediaFileUploadStatus: {

                self.checkMarkQliqStor.hidden = YES;
                self.checkMarkQliqCloud.hidden = YES;
                break;
            }
            case UploadToCloudFailedMediaFileUploadStatus:
            case TemporaryQliqStorFailureErrorMediaFileUploadStatus:
            case PermanentQliqStorFailureErrorMediaFileUploadStatus:
            case ThirdPartyFailureStatusMediaFileUploadStatus: {

                self.checkMarkQliqCloud.hidden = YES;
                self.checkMarkQliqStor.hidden = YES;
                self.fileStatusLabel.text = [NSString stringWithFormat:@"x %@", self.fileStatusLabel.text];
                self.fileStatusLabel.font = [UIFont fontWithName:self.fileStatusLabel.font.fontName size:12.f];
                self.fileStatusLabel.textColor = [UIColor redColor];
                break;
            }
            case UploadedToCloudMediaFileUploadStatus: {

                self.checkMarkQliqCloud.hidden = NO;
                self.checkMarkQliqStor.hidden = YES;
                break;
            }
            case FinalProcessingSuccesfulMediaFileUploadStatus:
            case ThirdPartySuccessStatusMediaFileUploadStatus: {

                self.checkMarkQliqCloud.hidden = NO;
                self.checkMarkQliqStor.hidden = NO;
                break;
            }
            case TargetNotFoundMediaFileUploadStatus: {

                break;
            }
            default:
                break;
        }

        if ([upload isFailed]) {
            self.checkMarkQliqCloud.hidden = YES;
            self.checkMarkQliqStor.hidden = YES;
            self.fileStatusLabel.text = [NSString stringWithFormat:@"x %@", self.fileStatusLabel.text];
            self.fileStatusLabel.font = [UIFont fontWithName:self.fileStatusLabel.font.fontName size:12.f];
            self.fileStatusLabel.textColor = [UIColor redColor];
        }

        //Configure fileStatusLabelLeadingConstraint
        if (!self.checkMarkQliqCloud.hidden) {
            self.fileStatusLabelLeadingConstraint.constant = 0.f + self.checkMarkQliqCloud.frame.size.width + 2.f;
        }

        if (!self.checkMarkQliqStor.hidden) {
            self.fileStatusLabelLeadingConstraint.constant += self.fileStatusLabelLeadingConstraint.constant;
        }

        if (self.checkMarkQliqStor.hidden && self.checkMarkQliqCloud.hidden) {
            self.fileStatusLabelLeadingConstraint.constant = 0.f;
        }

        self.fileNameLabel.text = mediaFile.fileName;

        // Adam Sowa: the below condition is invalid:
//        if (mediaFile || [mediaFile.encryptedFilePath length] != 0) {
//            if ([self.delegate respondsToSelector:@selector(startDownloadOfUploadingFile:forCell:withIndexPath:)]) {
//                [self.delegate startDownloadOfUploadingFile:mediaFile forCell:self withIndexPath:indexPath];
//            }
//        }

        /*
        if ([upload isFailed]) {

            if ([self.delegate respondsToSelector:@selector(startDownloadOfUploadingFile:forCell:withIndexPath:)]) {
                [self.delegate startDownloadOfUploadingFile:mediaFile forCell:self withIndexPath:indexPath];
            }
        }
         */

        self.timeLabel.text = [mediaFile timestampToUiText];
    }
}

#pragma mark - Private -

#pragma mark - Progress Observing -

- (void)setupProgressHandler:(NSInteger)attachmentId
{
    self.progressHandler = [appDelegate.network.progressHandlers progressHandlerForKey:[NSString stringWithFormat:@"%ld", (long)attachmentId]];

    /* if progress handlers exists - then attachment in process */
    if (self.progressHandler != nil)
    {
        self.progressHandler.observer = self;
        [self.progressBar setHidden:NO];
    }
    else
    {
        self.progressHandler.observer = nil;
        [self.progressBar setHidden:YES];
    }
}

- (void)progressHandler:(ProgressHandler *)progressHandler didChangeProgress:(CGFloat)progress
{
    [self.progressBar setProgress:progress];
}

- (void)progressHandler:(ProgressHandler *)progressHandler didChangeState:(ProgressState)state
{
    BOOL progressHidden = (state != ProgressStateDownloading && state != ProgressStateUploading);
    [self.progressBar setHidden:progressHidden];
}

@end
