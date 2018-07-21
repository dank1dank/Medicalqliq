//
//  TimestampCell.m
//  qliq
//
//  Created by Valeriy Lider on 10/1/14.
//
//

#import "TimestampCell.h"

#import "ChatMessage.h"
#import "MessageStatusLog.h"

#import "NSDate+Format.h"

#import "QliqUserDBService.h"

#define kValueCheckMarkImageViewRightOffsetConstraint   1.f
#define KValueDeliveredStatusLabelRightOffsetConstraint 5.f

@interface TimestampCell ()

/**
 IBOutlets
 */
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *checkMarkImageView;
@property (weak, nonatomic) IBOutlet UILabel *deliveredStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *timestampLabel;
@property (weak, nonatomic) IBOutlet UIImageView *accessoryImageView;


/* Constraints */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *checkMarkImageViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *checkMarkImageViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *checkMarkImageViewRightOffsetConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *deliveredStatusLabelRightOffsetConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *deliveredStatusLabelWidthConstraint;


@property (weak, nonatomic) IBOutlet NSLayoutConstraint *timesatampLabelWidthConstraint;

@end

@implementation TimestampCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {

    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Public -

- (void)setCellWithMessage:(ChatMessage*)message withMessageStatusLog:(MessageStatusLog*)messageLog isGroupMessage:(BOOL)isGroupMessage whithSelectedQliqUser:(QliqUser*)user
{
    QliqUser *groupMessageUser = nil;
    if (isGroupMessage && messageLog.status != SentToQliqStorMessageStatus)
    {
        groupMessageUser = [[QliqUserDBService sharedService] getUserWithId:messageLog.qliqId];
    }
    
    //Title
    {
        NSString *title = [messageLog statusMsg:message.totalRecipientCount showQliqUserName:!user];
        if (groupMessageUser)
            title = [groupMessageUser nameDescription];
        
        self.titleLabel.text = title;
    }
    
    //DeliveredStatus
    {
        self.checkMarkImageView.hidden = YES;
        self.checkMarkImageViewRightOffsetConstraint.constant = 0;
        self.checkMarkImageViewWidthConstraint.constant = 0;
     
        self.deliveredStatusLabel.hidden = YES;
        self.deliveredStatusLabel.text = @"";
        self.deliveredStatusLabelRightOffsetConstraint.constant = 0;
        self.deliveredStatusLabelWidthConstraint.constant = 0;
        
        if (isGroupMessage && messageLog.qliqId)
        {
            NSString *deliveredStatus = nil;
            NSString *checkMarkImageName = nil;
            
            switch (messageLog.status)
            {
                case DeliveredMessageStatus: {
                    deliveredStatus = QliqLocalizedString(@"1921-StatusDelivered");
                    checkMarkImageName = @"MessageDetailCheckmark";
                    break;
                }
                case ReadMessageStatus: {
                    deliveredStatus = QliqLocalizedString(@"1923-StatusRead");
                    checkMarkImageName = @"MessageDetailDoubleCheckmark";
                    break;
                }
                case AckReceivedMessageStatus: {
                    deliveredStatus = QliqLocalizedString(@"1942-StatusAcknowledged");
                    checkMarkImageName = @"MessageDetailDoubleCheckmark";
                    break;
                }
                default: break;
            }
            
            if (deliveredStatus)
            {
                self.deliveredStatusLabel.text = deliveredStatus;
                self.deliveredStatusLabel.hidden = NO;
                self.deliveredStatusLabelRightOffsetConstraint.constant = KValueDeliveredStatusLabelRightOffsetConstraint;
                self.deliveredStatusLabelWidthConstraint.constant = [[QliqAvatar sharedInstance] getWidthForLabel:self.deliveredStatusLabel].width;
                
                if (checkMarkImageName)
                {
                    CGFloat checkMarkImageWidth = 0;
                    
                    if ([checkMarkImageName isEqualToString:@"MessageDetailDoubleCheckmark"]) {
                        checkMarkImageWidth = 16.f;
                    }
                    else if ([checkMarkImageName isEqualToString:@"MessageDetailCheckmark"]) {
                        checkMarkImageWidth = 12.f;
                    }
                    
                    CGSize checkMarkImageViewSize = CGSizeMake(checkMarkImageWidth, 10.f);
                    UIImage *checkMarkImage = [UIImage imageNamed:checkMarkImageName];
                    
                    self.checkMarkImageView.hidden = NO;
                    self.checkMarkImageView.image = checkMarkImage;
                    self.checkMarkImageViewRightOffsetConstraint.constant = kValueCheckMarkImageViewRightOffsetConstraint;
                    self.checkMarkImageViewWidthConstraint.constant = checkMarkImageViewSize.width;
                    self.checkMarkImageViewHeightConstraint.constant = checkMarkImageViewSize.height;
                }
            }
        }
    }
    
    //Timestamp
    {
        self.timestampLabel.text = [[NSDate dateWithTimeIntervalSince1970:messageLog.timestamp] stringWithTimeWithSecondsAndDate];
        self.timesatampLabelWidthConstraint.constant = [[QliqAvatar sharedInstance] getWidthForLabel:self.timestampLabel].width;
    }
    
    //AddArrow
    {
        self.accessoryImageView.hidden = YES;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        if (groupMessageUser) {
            self.accessoryImageView.hidden = NO;
            self.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
    }
}


@end
