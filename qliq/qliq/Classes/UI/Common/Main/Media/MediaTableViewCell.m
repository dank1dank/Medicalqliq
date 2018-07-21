//
//  MediaTableViewCell.m
//  qliq
//
//  Created by Valerii Lider on 7/29/14.
//
//

#import "MediaTableViewCell.h"

#import "MediaFile.h"
#import "ChatMessage.h"
#import "MessageAttachment.h"

#import "ChatMessageService.h"
#import "QliqUserDBService.h"
#import "MessageAttachmentDBService.h"

#import "Helper.h"
#import "NSDate-Utilities.h"

@interface MediaTableViewCell() <ProgressObserver>

@property (nonatomic, strong) UIProgressView *progressBar;
@property (nonatomic, strong) ProgressHandler *progressHandler;

- (void) progressHandler:(ProgressHandler *)progressHandler didChangeProgress:(CGFloat) progress;
- (void) progressHandler:(ProgressHandler *)progressHandler didChangeState:(ProgressState)state;

@end

@implementation MediaTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {

    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Initialization code
    self.progressBar = [[UIProgressView alloc] initWithFrame:CGRectMake(5, 32, 30, 15)];
    self.progressBar.backgroundColor = [UIColor redColor];
    
    [self.contentTypeImageView addSubview:self.progressBar];
    [self.progressBar setHidden:YES];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

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

- (void)setCell:(id)item withIndexPath:(NSIndexPath *)indexPath
{
    if ([item isKindOfClass:[MediaFile class]])
    {
        MediaFile *mediaFile = item;
        
        self.contentTypeImageView.image = [UIImage imageNamed:@"KeyboardGroupDocuments"];
        
        self.fileLabel.text = mediaFile.fileName;
        
        self.contentTypeImageView.image = [mediaFile thumbnail];
        
        // To get information about mediafile
        NSArray *attachments = [[MessageAttachmentDBService sharedService] getAttachmentsForMediaFileId:mediaFile.mediafileId];
        if (attachments.count > 0)
        {
            MessageAttachment *attachment = [attachments firstObject];
            ChatMessage *message = [ChatMessageService getMessageWithUuid:attachment.messageUuid];
            BOOL isReceivedMessage = ![[Helper getMyQliqId] isEqualToString:[message fromQliqId]];
          
            if (isReceivedMessage)
            {
                self.directionLabel.text = [NSString stringWithFormat:@"%@:", QliqLocalizedString(@"2109-TitleFrom")];
                self.nameLabel.text = [self nameFromQliqId:message.fromQliqId];
            }
            else
            {
                self.directionLabel.text = [NSString stringWithFormat:@"%@:", QliqLocalizedString(@"2110-TitleTo")];
                self.nameLabel.text = [self nameFromQliqId:message.toQliqId];
            }
            self.timeLabel.text = [self convertToDate:message];
            
            if (!mediaFile || [mediaFile.encryptedPath length] == 0)
                [self.delegate startDownloadMediaFile:mediaFile withCell:self withIndexPath:indexPath];
        }
        else
        {
            self.directionLabel.text = [NSString stringWithFormat:@"%@:", QliqLocalizedString(@"2109-TitleFrom")];
            self.nameLabel.text = [self nameFromQliqId:[Helper getMyQliqId]];
            self.timeLabel.text = [self convertDateFromName:mediaFile.fileName];
            
            NSFileManager* fm = [NSFileManager defaultManager];
            NSDictionary* attrs = [fm attributesOfItemAtPath:mediaFile.encryptedPath error:nil];
            
            NSString *time =  QliqLocalizedString(@"2111-TitleCustom");
            
            if (attrs)
            {
                NSDate *date = (NSDate*)[attrs objectForKey: NSFileCreationDate];
                time = [self converCreateDateToString:date];
            }
            else
            {
                time = [self convertDateFromName:mediaFile.fileName];
            }
            
            self.timeLabel.text = time;
        }
    }
}

#pragma mark - Private -

- (NSString *)convertToDate:(ChatMessage *)message
{
    //OLD Way
    /*
     NSDate *messageDate = [NSDate dateWithTimeIntervalSince1970:message.createdAt];
     NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
     formatter.timeStyle = NSDateFormatterShortStyle;
     //    formatter.dateStyle = NSDateFormatterMediumStyle;
     formatter.doesRelativeDateFormatting = YES;
     return [formatter stringFromDate:messageDate];
     */
    
    //1425071277
    NSDate *messageDate = [NSDate dateWithTimeIntervalSince1970:message.createdAt];

    NSString *fullTime = [self converCreateDateToString:messageDate];
    
    return fullTime;
}

- (NSString *)convertDateFromName:(NSString *)name
{
    NSString *convertTime = QliqLocalizedString(@"2111-TitleCustom");
    
    NSRange r = [name rangeOfString:@"-"];
    
    /*
     r.location = r.location + 1;
     r.length = 2;
     
     NSString *month = [name substringWithRange:r];
     
     r.location = r.location + 3;
     r.length = 2;
     
     NSString *day = [name substringWithRange:r];
     
     r.location = r.location + 3;
     r.length = 2;
     
     NSString *year = [name substringWithRange:r];
     
     NSString *time = [NSString stringWithFormat:@"%@-%@-20%@", day, month, year];
     */
    
    r.location = r.location + 1;
    r.length = 8;
    
    if (name.length >= r.location + r.length) {
        NSString *time = [name substringWithRange:r];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MM-dd-yy"];
        
        NSDate *dateCreate = [[NSDate alloc] init];
        dateCreate = [dateFormatter dateFromString:time];
        
        if (dateCreate)
            convertTime = [self converCreateDateToString:dateCreate];
    }
    return convertTime;
}

- (NSString*)converCreateDateToString:(NSDate*)messageDate
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.timeStyle                     = NSDateFormatterShortStyle;
    formatter.doesRelativeDateFormatting    = YES;
    NSString *time = [formatter stringFromDate:messageDate];
    
    formatter = nil;
    formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle                     = NSDateFormatterMediumStyle;
    NSString *date = [formatter stringFromDate:messageDate];
    
    NSString *fullTime = @"";
    
    if ([messageDate isToday]) {
        formatter.doesRelativeDateFormatting    = YES;
        NSString *date = [formatter stringFromDate:messageDate];
        fullTime = [NSString stringWithFormat:@"%@\n%@", date ,time];
    }
    else {
        fullTime = [NSString stringWithFormat:@"%@\n%@", date ,time];
    }
    
    return fullTime;
}

- (NSString *)nameFromQliqId:(NSString *)qliqId
{
    QliqUserDBService *userService = [[QliqUserDBService alloc] init];
    QliqUser *user = [userService getUserWithId:qliqId];
    
    NSString *name = user.displayName;
    if (!name)
    {
        QliqGroupDBService *groupService = [[QliqGroupDBService alloc] init];
        QliqGroup *group = [groupService getGroupWithId:qliqId];
        if (group)
            name = [group name];
    }
    
    return name;
}

#pragma mark - Progress Observing -

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
