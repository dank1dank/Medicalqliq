//
//  SelectPDFTableViewCell.m
//  qliq
//
//  Created by Spire User on 18/11/2016.
//
//

#import "SelectPDFTableViewCell.h"

#import "MediaFile.h"
#import "ChatMessage.h"
#import "ChatMessageService.h"
#import "NSDate-Utilities.h"
#import "MessageAttachmentDBService.h"
#import "MessageAttachment.h"

@implementation SelectPDFTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

- (void)setCell:(id)item withIndexPath:(NSIndexPath *)indexPath
{
    if ([item isKindOfClass:[MediaFile class]])
    {
        MediaFile *pdfFile = item;
        self.contentTypeImageView.image = [UIImage imageNamed:@"KeyboardGroupDocuments"];
        self.selectFileLabel.text = pdfFile.fileName;
        
        self.contentTypeImageView.image = [pdfFile thumbnail];
        
        NSArray *attachments = [[MessageAttachmentDBService sharedService] getAttachmentsForMediaFileId:pdfFile.mediafileId];
        if (attachments.count > 0)
        {
            MessageAttachment *attachment = [attachments firstObject];
            ChatMessage *message = [ChatMessageService getMessageWithUuid:attachment.messageUuid];
            self.timeLabel.text = [self convertToDate:message];
        }
        else
        {
            NSDate *pdfDate = [NSDate dateWithTimeIntervalSince1970:pdfFile.timestamp];
            self.timeLabel.text = [self converCreateDateToString:pdfDate];
        }
    }
}

#pragma mark - Private -

- (NSString *)convertToDate:(ChatMessage *)message
{
    NSDate *messageDate = [NSDate dateWithTimeIntervalSince1970:message.createdAt];
    NSString *fullTime = [self converCreateDateToString:messageDate];
    return fullTime;
}

- (NSString *)converCreateDateToString:(NSDate*)messageDate
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.timeStyle                     = NSDateFormatterShortStyle;
    formatter.doesRelativeDateFormatting    = YES;
    NSString *time = [formatter stringFromDate:messageDate];
    
    formatter = nil;
    formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle                     = NSDateFormatterMediumStyle;
    formatter.doesRelativeDateFormatting    = YES;
    NSString *date = [formatter stringFromDate:messageDate];
    
    NSString *fullTime = @"";
    
    if ([messageDate isToday])
        fullTime = [NSString stringWithFormat:@"%@",time];
    else
        fullTime = [NSString stringWithFormat:@"%@\n%@", date ,time];
    
    return fullTime;
}


@end
