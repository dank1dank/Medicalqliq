//
//  ConversationTableViewCell.m
//  qliq
//
//  Created by Valerii Lider on 7/31/14.
//
//

#import "ConversationTableViewCell.h"


#import "MessageAttachment.h"
#import "MediaFileService.h"
#import "QliqUserDBService.h"
#import "AckView.h"
#import "QliqAssistedView.h"
#import "ContactAvatarService.h"
#import "ACPDownloadView.h"
#import "ACPIndeterminateGoogleLayer.h"
#import "ACPStaticImagesAlternative.h"
#import "MessageStatusLogDBService.h"
#import "NSDate+Format.h"
#import "Helper.h"

#define MinAttachmentWidth   175
#define kAvatarViewWidth     35.f
#define kValueCheckmarkWidth 10.f
#define kValueForMessageTimestampOffset 10.f

#define kValueBubbleMessageEndOffset 10.f

/**
 Vertical & Height & AlignY constraint Value
 */
//TextLabel
#define kValueTextLabelTop                      1.f
#define kValueTextLabelWithDelivStatusBottom    14.f
#define kValueTextLabelBottom                   14.f//3.f

#define kValueMessageViewTop                    0.f
#define kValueMessageViewBottom                 -5.f
#define kValueMessageViewWithAttachmentBottom   -10.f

#define kValueTimeLabelTop                      2.f
#define kValueTimeLabelHeight                   14.f

#define kValueAttachmentViewBottom              -5.f

#define kValueAckViewHeight                     30.f
#define kValueAckViewBottom                     5.f
#define kValueDifferenceShiftFromAvatarViewForMyAckView         7.f
#define kValueDifferenceShiftFromAvatarViewForContactAckView         8.f

#define kValueQliqAssistedViewBottom            -5.f
#define kValueQliqAssistedViewTop               -5.f

//Attachment
#define kValueAttachmentViewImageHeight         110.f
#define kValueAttachmentViewDocHeight           60.f
#define kValueAttachmentViewVideoHeight         110.f
#define kValueAttachmentViewAudioHeight         60.f



//BootomMessageInfo
#define kValueBotOffsetBottomInfoViewConstraint 2.f

/**
 Horizontal & Width & AlignX constraint Value
 */
//TextLabel
#define kValueTextLabelOffsetFromStartBubbleMessage          10.f
#define kValueTextLabelOffsetFromEndBubbleMessage            5.f

#define kValueAvatarViewOffsetConstraint                     7.f
#define kValueOffsetBetweenAvatarAndMessageViewConstraint    2.f

//MessageViewInfo
#define kValueClockImageOffsetFromEndBubbleMessageConstraint 5.f
#define kValueClockImageWidthConstraint                      8.f
#define kValueoffsetTimeLabelToClockImage                    2.f

#define kValueNameLabelToOffsetConstraint                    2.f
#define kValueNameLabelToStartBubbleMessageOffsetConstraint  10.f

#define kValueQliqAssistedViewLableMarginConstraint  10.f

//BootomMessageInfo
#define kValueLeftOffsetCheckMark1Constraint                 7.f

#define kValueGradientViewHeightConstraint 20.f

#define kValueAvatarViewTopConstraint 5.f

NSString *const ConversationMyCellId = @"ConversationMyCellReuseId";
NSString *const ConversationWithAttachmentMyCellId = @"ConversationWithAttachmentMyCellReuseId";
NSString *const ConversationContactCellId = @"ConversationContactCellReuseId";
NSString *const ConversationWithAttachmentContactCellId = @"ConversationWithAttachmentContactCellReuseId";

@interface ConversationTableViewCell () <AttachmentViewDelegate, ProgressObserver, AckViewDelegate, QliqAssistedViewDelegate, UIGestureRecognizerDelegate, UITextViewDelegate>

#pragma mark IBOutlet
@property (weak, nonatomic) IBOutlet UIView *gradientView;
@property (nonatomic, weak) IBOutlet UIButton *checkmarkButton;

/** AvatarView */
@property (weak, nonatomic) IBOutlet UIView *avatarView;

@property (weak, nonatomic) IBOutlet ACPDownloadView *activityView;
@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (weak, nonatomic) IBOutlet UILabel *urgentIndicator;

/** MessageView */

@property (nonatomic, weak) IBOutlet UIImageView *backgroundImage;

//TopInfo
@property (weak, nonatomic) IBOutlet UIImageView *clockImage;
@property (weak, nonatomic) IBOutlet UILabel *time;
@property (weak, nonatomic) IBOutlet UILabel *name;



//BottomInfo
@property (weak, nonatomic) IBOutlet UIImageView *chekmarkSended;
@property (weak, nonatomic) IBOutlet UILabel *deliverdCountLabel;
@property (weak, nonatomic) IBOutlet UIImageView *chekmarkViewed;
@property (weak, nonatomic) IBOutlet UILabel *readCountLabel;

/** AttachmentView */
@property (nonatomic, weak) IBOutlet UIView *attachmentView_Image;

@property (nonatomic, weak) IBOutlet UIImageView *attachmentMainImage;
@property (nonatomic, weak) IBOutlet UILabel *attachmentNameLabel;

/** AckView */
@property (nonatomic, weak) IBOutlet AckView *ackView;

/** QliqAssisted View */
@property (nonatomic, weak) IBOutlet QliqAssistedView *qliqAssistedView;

#pragma mark Constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *gradientViewHeightConstraint;

/** AvatarView */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *avatarViewTopConstraint;


/** MessageView */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topMessageViewConstant;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomMessageViewConstant;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *attachMentContentsTopOffsetConstraint;

//TimeLabel Constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topTimeLabelConstant;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightTimeLabelConstant;

//TextMessage Constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topTextLabelConstant;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomTextLabelConstant;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textLabelOffsetFromStartBubbleMessage;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textLabelOffsetFromEndBubbleMessage;


//QliqAssistedViewConstraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightQliqAssistedView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *qliqAssitedWidthConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *qliqAssistedTitleLabelTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *qliqAssistedTitleLabelBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *qliqAssistedTitleLabelLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *qliqAssistedTitleLabelTrallingConstraint;


@property (weak, nonatomic) IBOutlet NSLayoutConstraint *qliqAssistedBottomConstraint;


/** AckView Constraints */

//AcknowledgedViewConstraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightAcknowledgedView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ackViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ackTitleLabelWidthConstraint;

//Constraints used for DeletingMode
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *avatarViewWidthConstraint;

//BottomInfoView
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *botOffsetBottomInfoViewConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftOffsetCheckMark1Constraint;

/* Attachment Constraints */

//MainBubbleAttachmentView
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *attachmentBubbleHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *attachmentBubbleWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomAttachmentViewConstant;

//ImageView
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *attachmentImageWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *attachmentImageHeightConstraint;

/**
 Horizontal & Width & AlignX constraint Value
 */
//Read/Delivered count
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *deliveredCountLabelWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *readCountLabelWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *checkmarkDeliveredWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *checkmarkReadWidthConstraint;


//Avatar
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *avatarViewOffsetConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *offsetBetweenAvatarAndMessageViewConstraint;



//BubbleMessageView
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *messageWidthConstraint;

//MessageInfo
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *timeWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *offsetTimeLabelToClockImage;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *clockImageOffsetFromEndBubbleMessageConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *clockImageWidthConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nameLabelToOffsetConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nameLabelToStartBubbleMessageOffsetConstraint;


//AckView
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ackViewToAvatarViewOffsetConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *qliqAssistedViewToAvatarViewOffsetConstraint;
//AttachmentView
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *attachmentViewToAvatarViewConstraint;


#pragma mark UI

@property (nonatomic, weak) ProgressHandler *progressHandler;

/** - Gesture Recognizers */
@property (nonatomic, strong) UILongPressGestureRecognizer *cellLongPressGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *tapAttachmentImageGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *tapAvatarImageGestureRecognizer;

#pragma mark Data

@property (nonatomic, assign) TypeCell currentTypeCell;

@property (nonatomic, assign) BOOL isMyMessage;
@property (nonatomic, assign) BOOL itsForMessageTimestamp;
@property (nonatomic, assign) BOOL isGroupConversation;
@property (nonatomic, assign) BOOL canTapAvatar;
@property (nonatomic, assign) BOOL showProgressBar;

@property (nonatomic, assign) BOOL showQliqAssistedView;

@property (nonatomic, assign) BroadcastType broadcastType;

@property (nonatomic, strong) UIColor *mainTextColor;

//** - Global Value */
@property (nonatomic, strong) ChatMessage *chatMessage;

@end

@implementation ConversationTableViewCell

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
    }
    return self;
}

- (void)dealloc
{
    self.ackView.delegate = nil;
    self.checkmarkButton = nil;
    [self stopProgressObserving];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    //Self
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    //Add GestureRecognizers
    {
        //Cell LongPress
        {
            self.cellLongPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPress:)];
            self.cellLongPressGestureRecognizer.delaysTouchesBegan = NO;
            self.cellLongPressGestureRecognizer.delaysTouchesEnded = NO;
            self.cellLongPressGestureRecognizer.cancelsTouchesInView = YES;
            self.cellLongPressGestureRecognizer.minimumPressDuration = 0.3;
            self.cellLongPressGestureRecognizer.delegate = self;
            [self addGestureRecognizer:self.cellLongPressGestureRecognizer];
        }
        //Tap AttachmentImage
        {
            self.tapAttachmentImageGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapAttachmentImage:)];
            [self.attachmentView_Image addGestureRecognizer:self.tapAttachmentImageGestureRecognizer];
            
        }
        //Tap AvatarImage
        {
            self.tapAvatarImageGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapAvatarImage:)];
            [self.avatarView addGestureRecognizer:self.tapAvatarImageGestureRecognizer];
        }
    }
    //AvatarView
    {
        //AvaftarImage
        {
            self.avatar.layer.cornerRadius = 17;
            self.avatar.clipsToBounds = YES;
        }
        //ActivityStatus
        {
            ACPStaticImagesAlternative * myOwnImages = [ACPStaticImagesAlternative new];
            UIColor *color = kColorAvatarTittle;
            [myOwnImages updateColor:color];
            [self.activityView setImages:myOwnImages];
            
            //Status by default.
            [self.activityView setIndicatorStatus:ACPDownloadStatusRunning];
        }
        //Indicators
        {
            self.urgentIndicator.font = [UIFont systemFontOfSize:10];
        }
    }
    //MessageView
    {
        //TextMessage
        {
            
        }
    }
    //AttachmentView
    {
        /** Set ImageView */
        self.attachmentView_Image.layer.cornerRadius = 3;
        self.attachmentView_Image.layer.masksToBounds = YES;
    }
    //QliqAssistedView
    {
        
    }
    //AckView
    {
    
    }
    
    [self prepareForReuse];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.chatMessage = nil;
    self.isMyMessage = NO;
    self.itsForMessageTimestamp = NO;
    self.canTapAvatar = NO;
    self.mainTextColor = [UIColor blackColor];
    
    
    //Main
    {
        //GradientView
        self.gradientView.hidden = YES;
        self.gradientViewHeightConstraint.constant = kValueGradientViewHeightConstraint;
    }
    //AvatarView
    {
        //AvatarImage
        {
            
        }
        //Activity Status
        {
            
        }
        //Indicators
        {
            self.urgentIndicator.textColor = [UIColor whiteColor];
            self.urgentIndicator.backgroundColor = [UIColor clearColor];
        }
    }
    //MessageView
    {
        //DeliveredReadIndicators
        {
            UIImage *imageChekmark  = [UIImage imageNamed:@"CheckmarkAckBlue"];
            
            self.checkmarkDeliveredWidthConstraint.constant  = 0.f;
            self.chekmarkSended.hidden                       = YES;
            self.chekmarkSended.image                        = imageChekmark;
            
            self.checkmarkReadWidthConstraint.constant       = 0.f;
            self.chekmarkViewed.hidden                       = YES;
            self.chekmarkViewed.image                        = imageChekmark;
            
            self.deliveredCountLabelWidthConstraint.constant = 0.f;
            self.deliverdCountLabel.hidden                   = YES;
            self.deliverdCountLabel.text                     = @"";
            
            self.readCountLabelWidthConstraint.constant      = 0.f;
            self.readCountLabel.hidden                       = YES;
            self.readCountLabel.text                         = @"";
        }
        //TextMessage
        {
            self.messageTextView.text = nil;
            self.messageTextView.text = @"";
            self.messageTextView.editable = NO;
            self.messageTextView.selectable = YES;
            self.messageTextView.attributedText = nil;
            self.messageTextView.dataDetectorTypes = UIDataDetectorTypePhoneNumber | UIDataDetectorTypeLink;
            self.messageTextView.delegate = self;
        }
    }
    //AttachmentView
    {
        self.attachmentMainImage.hidden = YES;
        self.attachmentMainImage.image = [UIImage imageNamed:@"imageFrame"];
    }
    //AckView
    {
        
    }
}

#pragma mark - Class Methods -

+ (CGFloat)getBotTextLabelValue:(BOOL)isMyMessage withMessage:(ChatMessage*)message
{
    BOOL isMyMessageWithoutAttachment = isMyMessage && !message.hasAttachment;
    CGFloat botTextLabel = isMyMessageWithoutAttachment ? kValueTextLabelWithDelivStatusBottom : kValueTextLabelBottom;
    
    return botTextLabel;
}

+ (CGFloat)getCellHeightWithMessage:(ChatMessage*)message withBounds:(CGRect)bounds itsForMessageTimestamp:(BOOL)itsForMessageTimestamp
{
    CGFloat heightCell = 0.f;
    CGFloat bottomMessageViewValue;
    
    BOOL isMyMessage = [message isMyMessage];
//    BOOL isAckShow = message.ackRequired ? ([message isAcked] && !isMyMessage ? NO : YES) : NO;
    BOOL isAckShow = message.ackRequired;
    BOOL isQliqAssistedShow = [QliqAssistedView isPhoneNumbersDetectedForChatMessage:message].count > 0;
    
    // QliqAssisted & Ack Views
    CGFloat qliqAssistedViewHeight = [QliqAssistedView getQliqAssistedViewSizeWithMarginsVertical:kValueQliqAssistedViewLableMarginConstraint
                                                                                       horizontal:kValueQliqAssistedViewLableMarginConstraint
                                                                                     avatarOffset:isMyMessage ? kValueDifferenceShiftFromAvatarViewForMyAckView : kValueDifferenceShiftFromAvatarViewForContactAckView].height;
    if (isAckShow && isQliqAssistedShow) {
        bottomMessageViewValue = qliqAssistedViewHeight + kValueAckViewHeight + kValueQliqAssistedViewTop + kValueQliqAssistedViewBottom + kValueAckViewBottom;
    } else if (isQliqAssistedShow) {
        bottomMessageViewValue = qliqAssistedViewHeight + kValueQliqAssistedViewTop + kValueAckViewBottom;
    } else if (isAckShow) {
        bottomMessageViewValue = kValueAckViewHeight + kValueQliqAssistedViewBottom + kValueAckViewBottom;
    } else {
        bottomMessageViewValue = kValueAckViewBottom;
    }
    
    bottomMessageViewValue += fabs(kValueAckViewBottom);
    
    
    // Message View Size
    CGSize textSize = [ConversationTableViewCell getSizeOfText:message.text
                                                    withBounds:bounds
                                        itsForMessageTimestamp:itsForMessageTimestamp];
    
    CGFloat textLabelBottomValue = [ConversationTableViewCell getBotTextLabelValue:isMyMessage withMessage:message];
    
    // Attachment
    CGFloat attachmentHeight = 0.f;
    if (message.hasAttachment)
    {
        MessageAttachment *attachment = [message.attachments firstObject];
        MediaFileService *sharedService = [MediaFileService getInstance];
        
        if ([sharedService isDocumentFileMime:attachment.mediaFile.mimeType FileName:attachment.mediaFile.encryptedPath])
            attachmentHeight = kValueAttachmentViewDocHeight;
        else if ([sharedService isAudioFileMime:attachment.mediaFile.mimeType FileName:attachment.mediaFile.encryptedPath])
            attachmentHeight = kValueAttachmentViewAudioHeight;
        else if ([sharedService isImageFileMime:attachment.mediaFile.mimeType FileName:attachment.mediaFile.encryptedPath])
            attachmentHeight = kValueAttachmentViewImageHeight;
        else if ([sharedService isVideoFileMime:attachment.mediaFile.mimeType FileName:attachment.mediaFile.encryptedPath])
            attachmentHeight = kValueAttachmentViewVideoHeight;
        else
            attachmentHeight = kValueAttachmentViewDocHeight;
        
        attachmentHeight = attachmentHeight + kValueMessageViewWithAttachmentBottom;
    }
    
    heightCell =
    //BubbleMessage Offsets
    kValueMessageViewTop    +
    bottomMessageViewValue  +
    //TopMessageInfo
    kValueTimeLabelTop      +
    kValueTimeLabelHeight   +
    //TextMessage
    kValueTextLabelTop      +
    textSize.height         +
    textLabelBottomValue    +
    //Attachment
    attachmentHeight;
    
    if (itsForMessageTimestamp) {
        heightCell += kValueForMessageTimestampOffset - bottomMessageViewValue;
    }
    
    CGFloat minCellHeight = 56.f;
    heightCell = MAX(minCellHeight, heightCell);
    
    return heightCell;
}

+ (CGSize)getSizeOfText:(NSString *)text withBounds:(CGRect)bounds itsForMessageTimestamp:(BOOL)itsForMessageTimestamp {
    CGSize textSize = CGSizeZero;
    
    CGFloat maxWidthTextLabel = 0.f;
    {
        CGRect rect = bounds;
        
        if (UIInterfaceOrientationIsLandscape(([UIApplication sharedApplication].statusBarOrientation)) ) {
            rect = CGRectMake(0, 0, MAX(bounds.size.height, bounds.size.width), MIN(bounds.size.height, bounds.size.width) );
        }
        
        CGFloat maxWidthBubbleMessage = [ConversationTableViewCell getMaxWidthBubbleMessage];
        
        maxWidthTextLabel =
        maxWidthBubbleMessage -
        kValueTextLabelOffsetFromStartBubbleMessage -
        kValueTextLabelOffsetFromEndBubbleMessage;
    }
    
    static UITextView *calculationView = nil;
    if (calculationView == nil) {
        calculationView = [[UITextView alloc] init];
        calculationView.textContainerInset = UIEdgeInsetsMake(0,0,0,0);
        calculationView.textAlignment = NSTextAlignmentLeft;
        calculationView.dataDetectorTypes = UIDataDetectorTypePhoneNumber | UIDataDetectorTypeLink;
    }
    
    calculationView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    
    if (itsForMessageTimestamp) {
        calculationView.text = @"";
        textSize.height = [calculationView sizeThatFits:CGSizeMake(maxWidthTextLabel, FLT_MAX)].height;
        
        calculationView.text = text;
        textSize.width = [calculationView sizeThatFits:CGSizeMake(maxWidthTextLabel, FLT_MAX)].width;
    }
    else {
        calculationView.text = text;
        textSize = [calculationView sizeThatFits:CGSizeMake(maxWidthTextLabel, FLT_MAX)];
    }
    
    return textSize;
}

#pragma mark - Public -

- (void)setCellMessage:(ChatMessage *)message
                ofUser:(BOOL)isUsersMessage
   isGroupConversation:(BOOL)isGroupConversation
         broadcastType:(BroadcastType)broadcastType
itsForMessageTimestamp:(BOOL)itsForMessageTimestamp
{
    //** SetGlobalValue */
    {
        self.chatMessage = message;
        
        self.isMyMessage = [[UserSessionService currentUserSession].user.qliqId isEqualToString:[message fromQliqId]];
        self.isGroupConversation = isGroupConversation;
        self.itsForMessageTimestamp = itsForMessageTimestamp;
        self.mainTextColor = self.isMyMessage ? RGBa(85, 85, 85, 1) : [UIColor whiteColor];
        //Set Current TypeCell
        {
            if (self.isMyMessage) {
                self.currentTypeCell = [self.chatMessage hasAttachment] ? TypeCellMyWithAttachment : TypeCellMy;
            }
            else {
                self.currentTypeCell = [self.chatMessage hasAttachment] ? TypeCellReceivedWithAttachment : TypeCellReceived;
            }
        }
    }
    //*****(Set Local Value)*****/
    NSTimeInterval timestamp = 0;
    
    BOOL isMessageSending = NO;
    //Satus Send
    {
        NSString *statusText = [message deliveryStatusToStringWithTimestamp:&timestamp];
        isMessageSending = [statusText isEqualToString:QliqLocalizedString(@"1919-StatusSending")];
    }
    //*****(Set...)*****/
    [self setDefaultConstraints];
    
    //*****(Configure...)*****/
    
       //AvatarView
    {
        /** Avatar Image */
        [self configureAvatarImageView:isMessageSending];
        
        /** Activity Status */
        [self configureActivityStatus];
        
        /** Indicators */
        [self configureMessagePriorityIndicator];
    }
    //MessageView
    {
        /** Set Bubble Color */
        self.backgroundImage.image = [self getBubbleImageWithModeForUser:YES];
        
        //** Set Time */
        [self configureTimeLabelWithTimestamp:timestamp];
        
        /** Set NameLabel */
        [self configureNameLabel];
        
        /** Set TextMessage */
        [self configureTextMessage];
        
        /** Message status Indicators */
        [self configureStatusIndicators:isMessageSending];
    }
    //AttachmentView
    {
        [self configureAttachmentView];
        
        /** Progres handler */
        self.showProgressBar = message.deliveryStatus == 0;
        [self setupProgressHandlers];
    }
    //QliqAssisted View
    {
        [self configureQliqAssistedView];
    }
    //Acknowledged View
    {
        [self configureAckView];
    }
    //Main
    {
        /** SetBubbleMessageWidth */
        [self configureBubbleMessageViewWidth];
        
        /** ConfigureCellForMessagetimestamp */
        [self configureCellForMessageTimestampMode];
    }
}

- (void)showDeletingMode:(BOOL)isDeletingMode messageIsChecked:(BOOL)messageIsChecked
{
    self.checkmarkButton.hidden = !isDeletingMode;
    self.avatarView.hidden = isDeletingMode;
    self.avatarViewWidthConstraint.constant = isDeletingMode ? 0.f : kAvatarViewWidth;
    self.backgroundImage.image = [self getBubbleImageWithModeForUser:!isDeletingMode];
    self.messageTextView.userInteractionEnabled = !isDeletingMode;
    
    if (!self.checkmarkButton.hidden) {
        UIImage *checkmarkImage = messageIsChecked ? [UIImage imageNamed:@"ConversationChecked"] : [UIImage imageNamed:@"ConversationUnChecked"];
        [self.checkmarkButton setImage:checkmarkImage forState:UIControlStateNormal];
        checkmarkImage = nil;
    }
}

#pragma mark - Configure UI Elements -

- (void)configureBubbleMessageViewWidth
{
    ChatMessage *message = self.chatMessage;
   
    CGFloat nameLabelWidth    = 0;
    CGFloat widthForTopMessageInfo = 0.f;
    CGFloat widthForBotMessageInfo = 0.f;
    CGFloat maxWidthBubbleMessage = [self getMaxWidthForAdditionalView];
    
    CGSize messageTextSize = CGSizeZero;

    //Size of message text
    {   messageTextSize = [ConversationTableViewCell getSizeOfText:message.text
                                                        withBounds:[UIScreen mainScreen].bounds
                                            itsForMessageTimestamp:self.itsForMessageTimestamp];
        nameLabelWidth = [self getWidthForLabel:self.name];
    }
    
    //Width For Top Message Info
    {
        CGFloat widthAllInfoWithoutNameWidth =
        self.clockImageOffsetFromEndBubbleMessageConstraint.constant    +
        self.clockImageWidthConstraint.constant                         +
        fabs(self.offsetTimeLabelToClockImage.constant)                 +
        self.timeWidthConstraint.constant                               +
        self.nameLabelToStartBubbleMessageOffsetConstraint.constant     +
        self.nameLabelToOffsetConstraint.constant;
        
        CGFloat maxWidthForNameLabel = maxWidthBubbleMessage - widthAllInfoWithoutNameWidth;
        
        CGFloat widthForNameLabel = MIN(maxWidthForNameLabel, nameLabelWidth);
        
        widthForTopMessageInfo = widthAllInfoWithoutNameWidth + widthForNameLabel;
        
        widthForTopMessageInfo = MIN(widthForTopMessageInfo, maxWidthBubbleMessage);
    }
    
    //Width For Bottom Message Info
    {
        CGFloat widthCheckmark = self.isMyMessage ?
        self.checkmarkDeliveredWidthConstraint.constant     +
        self.checkmarkReadWidthConstraint.constant          +
        self.deliveredCountLabelWidthConstraint.constant    +
        self.readCountLabelWidthConstraint.constant         +
        self.leftOffsetCheckMark1Constraint.constant        +
        + 15.f
        : 0.f;
        
        widthForBotMessageInfo = MIN(widthCheckmark, maxWidthBubbleMessage);
    }
    
    CGFloat widthMaxMessageInfo = MAX(widthForTopMessageInfo, widthForBotMessageInfo);
    
    //Width For Message With offsets
    CGFloat widthMaxTextLabelWithOffsets =
    messageTextSize.width +
    self.textLabelOffsetFromStartBubbleMessage.constant +
    self.textLabelOffsetFromEndBubbleMessage.constant;
    
    CGFloat widthMax = MAX(widthMaxTextLabelWithOffsets, widthMaxMessageInfo);
    CGFloat widthBubbleMessage = MIN(maxWidthBubbleMessage, widthMax);
    
    //Width for Qliq Assisted View
    if (!self.qliqAssistedView.hidden)
    {
        CGFloat minimumQliqAssistedWidth = self.qliqAssitedWidthConstraint.constant;
        minimumQliqAssistedWidth = MIN(maxWidthBubbleMessage, minimumQliqAssistedWidth);
        widthBubbleMessage = MAX(widthBubbleMessage, minimumQliqAssistedWidth);
    }
    
    //Width for Ack View
    if (!self.ackView.hidden)
    {
        CGFloat minimumAckWidth = self.ackTitleLabelWidthConstraint.constant + 50.f;
        minimumAckWidth = MIN(maxWidthBubbleMessage, minimumAckWidth);
        widthBubbleMessage = MAX(widthBubbleMessage, minimumAckWidth);
    }
    
    CGFloat additionalWidthForBubbleTale = self.isMyMessage ? kValueDifferenceShiftFromAvatarViewForMyAckView : kValueDifferenceShiftFromAvatarViewForContactAckView;
    
    if (message.hasAttachment && message.attachments.count != 0)
    {
        //TODO: create calculation size for attachmentView
        widthBubbleMessage = MAX(MinAttachmentWidth, widthBubbleMessage);
        
        self.messageWidthConstraint.constant            = widthBubbleMessage + additionalWidthForBubbleTale;
        self.attachmentBubbleWidthConstraint.constant   = widthBubbleMessage;
        self.qliqAssitedWidthConstraint.constant        = widthBubbleMessage;
        self.ackViewWidthConstraint.constant            = widthBubbleMessage;
    }
    else
    {
        self.messageWidthConstraint.constant            = widthBubbleMessage + additionalWidthForBubbleTale;
        self.qliqAssitedWidthConstraint.constant        = widthBubbleMessage;
        self.ackViewWidthConstraint.constant            = widthBubbleMessage;
    }
}

- (void)configureCellForMessageTimestampMode
{
    if (self.itsForMessageTimestamp)
    {
        //GradientView
        {
            self.gradientView.hidden = NO;
            
            CGRect rect = CGRectMake(0, 0, MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height), self.gradientView.frame.size.height);
            
            CAGradientLayer *gradient = [CAGradientLayer layer];
            gradient.frame = rect;
            NSInteger value = 150;
            gradient.colors = [NSArray arrayWithObjects:
                               //                           (id)[[UIColor clearColor] CGColor],
                               (id)[[UIColor colorWithWhite:value alpha:0.1f] CGColor],
                               (id)[[UIColor colorWithWhite:value alpha:0.2f] CGColor],
                               (id)[[UIColor colorWithWhite:value alpha:0.3f] CGColor],
                               (id)[[UIColor colorWithWhite:value alpha:0.4f] CGColor],
                               (id)[[UIColor colorWithWhite:value alpha:0.5f] CGColor],
                               (id)[[UIColor colorWithWhite:value alpha:0.6f] CGColor],
                               (id)[[UIColor colorWithWhite:value alpha:0.7f] CGColor],
                               (id)[[UIColor colorWithWhite:value alpha:0.8f] CGColor],
                               (id)[[UIColor colorWithWhite:value alpha:0.9f] CGColor],
                               (id)[[UIColor whiteColor] CGColor], nil];
            //    gradient.locations = @[@0.0f, @0.15f, @0.7f, @1.f];
            self.gradientView.backgroundColor = [UIColor clearColor];
            self.gradientView.userInteractionEnabled = NO;
            for (CALayer *layer in [self.gradientView.layer sublayers])
            {
                [layer removeFromSuperlayer];
            }
            [self.gradientView.layer insertSublayer:gradient atIndex:0];
        }
        
        //BottomMessageInfo
        {
            self.chekmarkSended.hidden = YES;
            self.deliverdCountLabel.hidden = YES;
            self.chekmarkViewed.hidden = YES;
            self.readCountLabel.hidden = YES;
        }
        //Main
        {
            self.topMessageViewConstant.constant = kValueForMessageTimestampOffset;
            self.avatarViewTopConstraint.constant = kValueForMessageTimestampOffset;
        }
    }
}

#pragma mark * AvatarView

- (void)configureAvatarImageView:(BOOL)isMessageSending
{
    /** Set Avatar Image */
    QliqUser *user = [[QliqUserDBService sharedService] getUserWithId:self.chatMessage.fromQliqId];
    self.avatar.image = [[ QliqAvatar sharedInstance] getAvatarForItem:user withTitle:nil];
    
    
    self.avatar.hidden = self.chatMessage.isDelivered ? NO : YES;
    
    if (self.isMyMessage)
    {
        self.avatar.hidden = isMessageSending;
        
        if (!self.avatar.hidden && !self.chatMessage.isDelivered)
        {
            self.canTapAvatar = YES;
            self.avatar.image = [UIImage imageNamed:@"mark"];
        }
    }
}

- (void)configureMessagePriorityIndicator
{
    self.urgentIndicator.hidden             = NO;
    self.urgentIndicator.text               = @"";
    
    switch (self.chatMessage.priority)
    {
        case ChatMessagePriorityUrgen: {
            
            self.urgentIndicator.text = @"Urgent";
            self.urgentIndicator.backgroundColor = [UIColor orangeColor];
            break;
        }
        case ChatMessagePriorityAsSoonAsPossible: {
            
            self.urgentIndicator.text = @"ASAP";
            self.urgentIndicator.backgroundColor = RGBa(0, 118, 171, 1);
            break;
        }
        case ChatMessagePriorityForYourInformation: {
            
            self.urgentIndicator.text = @"FYI";
            self.urgentIndicator.backgroundColor = RGBa(0, 163, 224, 1);
            break;
        }
        default: {
            self.urgentIndicator.hidden = YES;
            break;
        }
    }
}

- (void)configureActivityStatus
{
    self.activityView.hidden = !self.avatar.hidden;
    
    if (self.avatar.hidden) {
        [self.activityView setIndicatorStatus:ACPDownloadStatusIndeterminate];
    }
    else {
        [self.activityView setIndicatorStatus:ACPDownloadStatusNone];
    }
}

#pragma mark * MessageView

- (void)configureTimeLabelWithTimestamp:(NSTimeInterval)timestamp
{
    //1433510205
    NSTimeInterval time = self.chatMessage.createdAt;
    NSDate *messageDate = [NSDate dateWithTimeIntervalSince1970:time];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.timeStyle = NSDateFormatterShortStyle;
    formatter.dateStyle = NSDateFormatterMediumStyle;
    formatter.doesRelativeDateFormatting = YES;
    
    //TimeLabel
    {
        self.time.text = [formatter stringFromDate:messageDate];
        self.time.textColor = self.mainTextColor;
        self.timeWidthConstraint.constant = [self getWidthForLabel:self.time];
    }
    
    NSString *clockImageName = !self.isMyMessage ? @"ConversationTime" : @"ConversationTimeGrey";
    self.clockImage.image = [UIImage imageNamed:clockImageName];
}

- (void)configureNameLabel
{
    QliqUserDBService *userService = [[QliqUserDBService alloc] init];
    QliqUser *user = [userService getUserWithId:self.chatMessage.fromQliqId];
    
    self.name.text = self.isMyMessage ? @"Me" : user.displayName;
    self.name.textColor = self.mainTextColor;
}

- (void)configureTextMessage
{
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    
    self.messageTextView.backgroundColor = [UIColor clearColor];
    self.messageTextView.font = font;
    self.messageTextView.textContainerInset = UIEdgeInsetsMake(0,0,0,0);
    self.messageTextView.textAlignment = NSTextAlignmentLeft;
    self.messageTextView.showsHorizontalScrollIndicator = NO;
    self.messageTextView.showsVerticalScrollIndicator = NO;
    self.messageTextView.editable = NO;
    self.messageTextView.selectable = YES;
    self.messageTextView.scrollEnabled = NO;
    self.messageTextView.userInteractionEnabled = YES;
    self.messageTextView.dataDetectorTypes = UIDataDetectorTypePhoneNumber | UIDataDetectorTypeLink;
    self.messageTextView.linkTextAttributes = @{NSFontAttributeName: font,
                                                NSForegroundColorAttributeName : self.mainTextColor,
                                                NSUnderlineStyleAttributeName : @1};
    self.messageTextView.textColor = self.mainTextColor;

    NSString *correctedMessage = [QliqAssistedView getCorrectedPhoneNumberForMessage:self.chatMessage];
    if (correctedMessage.length > 0) {
        self.chatMessage.text = correctedMessage;
    }

    self.messageTextView.text = self.chatMessage.text;
    
    if (self.chatMessage.text) {
        
        NSDictionary *attributes = @{NSFontAttributeName: font,
                                     NSForegroundColorAttributeName : self.mainTextColor};
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:self.chatMessage.text attributes:attributes];
        
        if (self.chatMessage.recalledStatus != NotRecalledStatus) {
            [attributedString addAttribute:NSStrikethroughStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:NSMakeRange(0, attributedString.length)];
        }
        
        self.messageTextView.attributedText = attributedString;
    }
}

- (NSString *)getDeliveryStatusMessage {
    NSString *statusMessage = @"";
    
    
    NSTimeInterval timestamp = 0;
    NSString *statusText = [self.chatMessage deliveryStatusToStringWithTimestamp:&timestamp];
    if ([self.chatMessage isMyMessage]) {
        if (self.chatMessage.recalledStatus != NotRecalledStatus) {
            statusText = QliqLocalizedString(@"1944-StatusRecalled");
        }
        statusMessage = statusText;
    }
    
    return statusMessage;
}

- (void)configureStatusIndicators:(BOOL)isMessageSending
{
    NSInteger deliveryStatus          = self.chatMessage.deliveryStatus;
    NSInteger totalRecipientCount     = self.chatMessage.totalRecipientCount;
    NSInteger deliveredRecipientCount = self.chatMessage.deliveredRecipientCount;
    NSInteger openedRecipientCount    = self.chatMessage.openedRecipientCount;
    
    BOOL showReadCheckMark      = NO;
    BOOL showDeliveredCheckMark = NO;
    BOOL showReadLabel          = NO;
    BOOL showDeliveredLabel     = NO;
    
    NSString *deliveredText = @"";
    NSString *readText      = @"";
    
    //For Group/Multiply Conversation
    if (totalRecipientCount > 0 && self.isGroupConversation && self.broadcastType && self.broadcastType != ReceivedBroadcastType)
    {
        BOOL isOpenedRecipientCountEqualToTotalRecipientCount = openedRecipientCount == totalRecipientCount;
        //Delivered Label
        if (deliveredRecipientCount < totalRecipientCount)
        {
            showDeliveredLabel = YES;
            deliveredText = [NSString stringWithFormat:@"%ld/%ld %@", (long)deliveredRecipientCount, (long)totalRecipientCount, QliqLocalizedString(@"1921-StatusDelivered")];
        }
        else if (deliveredRecipientCount == totalRecipientCount)
        {
            showDeliveredCheckMark = YES;
            
            if (!isOpenedRecipientCountEqualToTotalRecipientCount )
            {
                showDeliveredLabel = YES;
                deliveredText = QliqLocalizedString(@"1921-StatusDelivered");
            }
        }
        //Read Label
        if (openedRecipientCount < totalRecipientCount)
        {
            showReadLabel = YES;
            readText = [NSString stringWithFormat:@"%ld/%ld %@", (long)openedRecipientCount, (long)totalRecipientCount, QliqLocalizedString(@"1923-StatusRead")];
        }
        else if (isOpenedRecipientCountEqualToTotalRecipientCount)
        {
            showReadCheckMark = YES;
            showReadLabel = YES;
            readText = QliqLocalizedString(@"1923-StatusRead");
        }
    }
    //For Single Conversation
    else
    {
        if (deliveryStatus == MessageStatusDelivered)
        {
            showDeliveredCheckMark  = YES;
            showDeliveredLabel      = YES;
            deliveredText = [self getDeliveryStatusMessage];//@"Delivered";
        }
        else if (deliveryStatus == MessageStatusRead)
        {
            showDeliveredCheckMark  = YES;
            showReadCheckMark       = YES;
            showReadLabel           = YES;
            readText = [self getDeliveryStatusMessage];
        }
        else {
            showDeliveredLabel      = YES;
            deliveredText = [self getDeliveryStatusMessage];
        }
    }
    
    self.chekmarkSended.hidden = isMessageSending ? YES : !showDeliveredCheckMark;
    self.chekmarkViewed.hidden = isMessageSending ? YES : !showReadCheckMark;
    
    self.deliverdCountLabel.hidden = !showDeliveredLabel;
    self.readCountLabel.hidden     = !showReadLabel;
    
    self.deliverdCountLabel.text    = deliveredText;
    self.readCountLabel.text        = readText;
    
    //Configure constraints
    self.checkmarkDeliveredWidthConstraint.constant = self.chekmarkSended.hidden ? 0 : kValueCheckmarkWidth;
    self.checkmarkReadWidthConstraint.constant      = self.chekmarkViewed.hidden ? 0 : kValueCheckmarkWidth;
    
    self.deliveredCountLabelWidthConstraint.constant = (self.deliverdCountLabel.hidden && self.deliverdCountLabel.text.length > 0) ? 0 : [self getSizeOfLabel:self.deliverdCountLabel].width;
    
    self.readCountLabelWidthConstraint.constant = (self.readCountLabel.hidden && self.readCountLabel.text.length > 0) ? 0 : [self getSizeOfLabel:self.readCountLabel].width;
}

#pragma mark * AttachmentView

- (void)configureAttachmentView
{
    if ([self.chatMessage hasAttachment])
    {
        MediaFileService *sharedService = [MediaFileService getInstance];
        MessageAttachment *attachment = [self.chatMessage.attachments firstObject];
        
        //Documents
        if ([sharedService isDocumentFileMime:attachment.mediaFile.mimeType FileName:attachment.mediaFile.encryptedPath]) {
            
            self.attachmentMainImage.hidden = YES;
            
            self.attachmentBubbleHeightConstraint.constant  = kValueAttachmentViewDocHeight;
            self.attachmentImageHeightConstraint.constant   = 30.f;
            self.attachmentImageWidthConstraint.constant    = 30.f;
        }
        //Audio
        else if ([sharedService isAudioFileMime:attachment.mediaFile.mimeType FileName:attachment.mediaFile.encryptedPath]){
            
            self.attachmentMainImage.hidden = YES;
            
            self.attachmentBubbleHeightConstraint.constant  = kValueAttachmentViewAudioHeight;
            self.attachmentImageHeightConstraint.constant   = 30.f;
            self.attachmentImageWidthConstraint.constant    = 30.f;
        }
        //Image
        else if ([sharedService isImageFileMime:attachment.mediaFile.mimeType FileName:attachment.mediaFile.encryptedPath]){
            
            self.attachmentMainImage.hidden = NO;
            self.attachmentMainImage.image = [UIImage imageNamed:@"imageFrame"];
            
            self.attachmentBubbleHeightConstraint.constant  = kValueAttachmentViewImageHeight;
            self.attachmentImageHeightConstraint.constant   = 65.f;
            self.attachmentImageWidthConstraint.constant    = 65.f;
        }
        //Video
        else if ([sharedService isVideoFileMime:attachment.mediaFile.mimeType FileName:attachment.mediaFile.encryptedPath]){
            
            self.attachmentMainImage.hidden = NO;
            self.attachmentMainImage.image = [UIImage imageNamed:@"videoFrame"];
            
            self.attachmentBubbleHeightConstraint.constant  = kValueAttachmentViewVideoHeight;
            self.attachmentImageHeightConstraint.constant   = 65.f;
            self.attachmentImageWidthConstraint.constant    = 65.f;
        }
        else {
            
            self.attachmentMainImage.hidden = YES;
            
            self.attachmentBubbleHeightConstraint.constant  = kValueAttachmentViewDocHeight;
            self.attachmentImageHeightConstraint.constant   = 30.f;
            self.attachmentImageWidthConstraint.constant    = 30.f;
        }
        
        self.attachmentView_Image.hidden = NO;
        
        self.attachmentImage.attachment = attachment;
        self.attachmentImage.delegate = self;
        
        self.attachmentNameLabel.text = attachment.mediaFile.fileName;
        
        if ([self.delegate respondsToSelector:@selector(downloadAttachments:)])
            [self.delegate downloadAttachments: self.attachmentImage.attachment];
    }
}


#pragma mark * QliqAssistedView

- (void)configureQliqAssistedView {
    
    self.qliqAssistedView.delegate = self;
    self.qliqAssistedView.hidden = [self.qliqAssistedView configureQliqAssistedViewWithMessage:self.chatMessage];
    
    CGSize qliqAssistedViewSize = [QliqAssistedView getQliqAssistedViewSizeWithMarginsVertical:kValueQliqAssistedViewLableMarginConstraint
                                                                                    horizontal:kValueQliqAssistedViewLableMarginConstraint
                                                                                  avatarOffset:self.isMyMessage ? kValueDifferenceShiftFromAvatarViewForMyAckView : kValueDifferenceShiftFromAvatarViewForContactAckView];
    
    self.heightQliqAssistedView.constant = qliqAssistedViewSize.height;
    
    if (self.qliqAssistedView.hidden)
    {
        CGFloat value = - qliqAssistedViewSize.height;
        
        if ([self.chatMessage hasAttachment]) {
            self.bottomAttachmentViewConstant.constant = value;
        }
        else
        {
            self.bottomMessageViewConstant.constant = value;
        }

    }
    else
    {
        CGFloat value = kValueQliqAssistedViewTop;
        if ([self.chatMessage hasAttachment]) {
            self.bottomAttachmentViewConstant.constant = value;
        }
        else
        {
            self.bottomMessageViewConstant.constant = value;
        }
        
        self.qliqAssitedWidthConstraint.constant = qliqAssistedViewSize.width;
    }
}

#pragma mark * AckView

- (void)configureAckView
{
    
    self.ackView.delegate = self;
    self.ackView.hidden = [self.ackView configureAckViewWithMessage:self.chatMessage isMyMessage:self.isMyMessage];
    
    self.heightAcknowledgedView.constant = kValueAckViewHeight;

    if (self.ackView.hidden)
    {
        self.qliqAssistedBottomConstraint.constant = - kValueAckViewHeight;
    }
    else
    {
        self.qliqAssistedBottomConstraint.constant = kValueQliqAssistedViewBottom;
    }
    
    self.ackTitleLabelWidthConstraint.constant = [self getWidthForLabel:self.ackView.ackTitleLabel];
    
//    [self layoutIfNeeded];
}

#pragma mark - Private -
#pragma mark * Set

- (void)setDefaultConstraints
{
    //Vertical & Height & AlignY constraint Value
    {
        //GradientView
        self.gradientViewHeightConstraint.constant = kValueGradientViewHeightConstraint;
        
        //AvatarView
        self.avatarViewTopConstraint.constant = kValueAvatarViewTopConstraint;
        
        //Attachment
        self.attachMentContentsTopOffsetConstraint.constant = -self.bottomMessageViewConstant.constant;
        
        //BottomInfoView
        self.botOffsetBottomInfoViewConstraint.constant = kValueBotOffsetBottomInfoViewConstraint;
        
        //TextLabel
        self.topTextLabelConstant.constant         = kValueTextLabelTop;
        self.bottomTextLabelConstant.constant      = [ConversationTableViewCell getBotTextLabelValue:self.isMyMessage withMessage:self.chatMessage];
        
        self.topMessageViewConstant.constant       = kValueMessageViewTop;
        
        self.topTimeLabelConstant.constant         = kValueTimeLabelTop;
        self.heightTimeLabelConstant.constant      = kValueTimeLabelHeight;
        
        self.bottomAttachmentViewConstant.constant = kValueAttachmentViewBottom;
    }
    
    //Horizontal & Width & AlignX constraint Value
    {
        //BottomInfoView
        self.leftOffsetCheckMark1Constraint.constant = kValueLeftOffsetCheckMark1Constraint;
        
        //TextLabel
        self.textLabelOffsetFromStartBubbleMessage.constant          = kValueTextLabelOffsetFromStartBubbleMessage;
        self.textLabelOffsetFromEndBubbleMessage.constant            = kValueTextLabelOffsetFromEndBubbleMessage;
        
        self.avatarViewOffsetConstraint.constant                     = kValueAvatarViewOffsetConstraint;
        self.offsetBetweenAvatarAndMessageViewConstraint.constant    = kValueOffsetBetweenAvatarAndMessageViewConstraint;
        
        if (self.isMyMessage) {
            self.offsetTimeLabelToClockImage.constant                    = kValueoffsetTimeLabelToClockImage;
        } else {
            self.offsetTimeLabelToClockImage.constant                    = - kValueoffsetTimeLabelToClockImage;
        }
        
        //ClockImage
        self.clockImageOffsetFromEndBubbleMessageConstraint.constant = kValueClockImageOffsetFromEndBubbleMessageConstraint ;
        self.clockImageWidthConstraint.constant                      = kValueClockImageWidthConstraint;
        
        //NameLabel
        self.nameLabelToOffsetConstraint.constant                    = kValueNameLabelToOffsetConstraint;
        self.nameLabelToStartBubbleMessageOffsetConstraint.constant  = kValueNameLabelToStartBubbleMessageOffsetConstraint;
        
        CGFloat offsetForAckAndAttachmentView = self.offsetBetweenAvatarAndMessageViewConstraint.constant + (self.isMyMessage ? kValueDifferenceShiftFromAvatarViewForMyAckView : kValueDifferenceShiftFromAvatarViewForContactAckView);
        
        //AckView
        self.ackViewToAvatarViewOffsetConstraint.constant            = offsetForAckAndAttachmentView;
        
        //QliqAssistedView
        self.qliqAssistedViewToAvatarViewOffsetConstraint.constant   = offsetForAckAndAttachmentView;
        
        self.qliqAssistedTitleLabelTopConstraint.constant = kValueQliqAssistedViewLableMarginConstraint;
        self.qliqAssistedTitleLabelBottomConstraint.constant = kValueQliqAssistedViewLableMarginConstraint;
        self.qliqAssistedTitleLabelLeadingConstraint.constant = kValueQliqAssistedViewLableMarginConstraint;
        self.qliqAssistedTitleLabelTrallingConstraint.constant = kValueQliqAssistedViewLableMarginConstraint;
        
        //AttachmentView
        self.attachmentViewToAvatarViewConstraint.constant           = offsetForAckAndAttachmentView;
    }
    
    [self layoutIfNeeded];
}

#pragma mark * Get

- (UIImage*)getBubbleImageWithModeForUser:(BOOL)isNormalMode
{
    NSString *imageName = @"";
    
    if (!self.isMyMessage) {
        imageName = [self.chatMessage isRead] ? @"ConversationBabbleGray" : @"ConversationBabbleBlue";
    }
    else {
        imageName = @"ConversationBabbleWhite";
    }
    
    if (!isNormalMode) {
        imageName = [imageName stringByAppendingString:@"WithoutArrow"];
    }
    
    return [[UIImage imageNamed:imageName] stretchableImageWithLeftCapWidth:10 topCapHeight:32];
}

+ (CGFloat)getMaxWidthBubbleMessage
{
    CGRect rect = CGRectZero;
    CGRect bounds = [UIScreen mainScreen].bounds;
    
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        rect = CGRectMake(0, 0, MAX(bounds.size.height, bounds.size.width), MIN(bounds.size.height, bounds.size.width));
    }
    else if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation))
    {
        rect = CGRectMake(0, 0, MIN(bounds.size.height, bounds.size.width), MAX(bounds.size.height, bounds.size.width));
    }
    
    CGFloat maxWidthBubbleMessage =
    rect.size.width                                     -
    kValueAvatarViewOffsetConstraint                    -
    kAvatarViewWidth                                    -
    kValueOffsetBetweenAvatarAndMessageViewConstraint   -
    kValueBubbleMessageEndOffset;
    
    return maxWidthBubbleMessage;
}

- (CGFloat)getMaxWidthForAdditionalView
{
    CGFloat maxWidthForAdditionalView = self.isMyMessage ? [ConversationTableViewCell getMaxWidthBubbleMessage] - kValueDifferenceShiftFromAvatarViewForMyAckView : [ConversationTableViewCell getMaxWidthBubbleMessage] - kValueDifferenceShiftFromAvatarViewForContactAckView;
    
    return maxWidthForAdditionalView;
}


- (CGFloat)getWidthForLabel:(UILabel*)label
{
    CGFloat width = 0;
    
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.alignment = label.textAlignment;
    paragraph.lineBreakMode = label.lineBreakMode;
    
    CGRect rect = [label.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, label.bounds.size.height)
                                           options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                        attributes:@{NSFontAttributeName : label.font,
                                                     NSParagraphStyleAttributeName : paragraph}
                                           context:nil];
    width = ceilf(rect.size.width);
    
    return  width;
}

- (CGSize)getSizeOfLabel:(UILabel*)labelGlobal
{
    CGSize size = CGSizeZero;
    
    if (labelGlobal) {
        NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
        paragraph.alignment = labelGlobal.textAlignment;
        paragraph.lineBreakMode = labelGlobal.lineBreakMode;
        
        CGRect rect = [labelGlobal.text boundingRectWithSize:CGSizeMake([ConversationTableViewCell getMaxWidthBubbleMessage], CGFLOAT_MAX)
                                                     options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                  attributes:@{NSFontAttributeName : labelGlobal.font,
                                                               NSParagraphStyleAttributeName : paragraph}
                                                     context:nil];
        
        size = CGSizeMake(ceilf(rect.size.width), ceilf(rect.size.height));
    }
    return size;
}

#pragma mark * Progress Observing

- (void)stopProgressObserving
{
    if (self.progressHandler.observer == self)
        self.progressHandler.observer = nil;
    
    self.progressHandler = nil;
}

- (void)setupProgressHandlers
{
    [self stopProgressObserving];
    
    MessageAttachment *attachment = self.attachmentImage.attachment;
    
    if (attachment)
    {
        self.progressHandler = [appDelegate.network.progressHandlers progressHandlerForKey:[NSString stringWithFormat:@"%ld",(long)attachment.attachmentId]];
        
        /* if progress handlers exists - then attachment in process */
        [self.attachmentImage setShowProgress: (self.progressHandler != nil) || self.showProgressBar ];
        
        if (self.progressHandler)
        {
            [self.attachmentImage setProgress:self.progressHandler.currentProgress * 0.75];
        }
        else if (self.showProgressBar)
        {
            [self.attachmentImage setProgress:0.75];
        }
        
        /* If status is downloading/uplading but no progress handler found - then error ocurred  */
        if ((attachment.status == AttachmentStatusDownloading || attachment.status == AttachmentStatusUploading) && !self.progressHandler)
        {
            attachment.status = (attachment.status == AttachmentStatusDownloading) ? AttachmentStatusDownloadFailed : AttachmentStatusUploadFailed;
            [attachment save];
        }
        
        [self.attachmentImage updateStatus];
        
        self.progressHandler.observer = self;
    }
}

#pragma mark - Actions

#pragma mark - * GestureRecognizer Action

- (void)onTapAttachmentImage:(UITapGestureRecognizer*)tapGesture
{
    MessageAttachment *attachment = [self.chatMessage.attachments firstObject];
    if ([self.delegate respondsToSelector:@selector(conversationTableViewCell:didTappedAttachment:)]) {
        [self.delegate conversationTableViewCell:self didTappedAttachment:attachment];
    }
}

- (void)onDoubleTapGestureRecognizer:(UITapGestureRecognizer *)tapGesture {
    if ([self.delegate respondsToSelector:@selector(conversationTableViewCellWasLongPressed:)]) {
        [self.delegate conversationTableViewCellWasLongPressed:self];
    }
}

- (void)onTapAvatarImage:(UITapGestureRecognizer*)tapGestureRecognizer
{
    if (self.canTapAvatar) {
        [self.delegate resendMessage:self.chatMessage];
    }
}

- (void)onLongPress:(UILongPressGestureRecognizer*)longGesture
{
    BOOL longPress = [longGesture isKindOfClass:[UILongPressGestureRecognizer class]];
    
    if(longPress && UIGestureRecognizerStateBegan == longGesture.state)
    {
        if ([self.delegate respondsToSelector:@selector(conversationTableViewCellWasLongPressed:)])
            [self.delegate conversationTableViewCellWasLongPressed:self];
    }
}

#pragma mark - Delegates -


#pragma mark * Text View Delegate

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    DDLogSupport(@"user pressed on URL: %@ in textView", URL);
    
    BOOL isDefaultBehaviorAllowed = YES;
    
    if ([URL.scheme isEqualToString:@"tel"]) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(phoneNumberWasPressedInCell:andPhoneNumber:)])
        {
//            NSString *phoneUrl = [URL absoluteString];
            NSString *phoneUrl = [self.qliqAssistedView getCorrectedPhoneNumberForPhoneUrl:[URL absoluteString]];
            NSString *phone = [phoneUrl stringByReplacingOccurrencesOfString:@"%20" withString:@""];
            
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^0-9]"
                                                                                   options:NSRegularExpressionCaseInsensitive
                                                                                     error:nil];
            phone = [regex stringByReplacingMatchesInString:phone
                                                    options:0
                                                      range:NSMakeRange(0, phone.length)
                                               withTemplate:@""];
            
            [self.delegate phoneNumberWasPressedInCell:self andPhoneNumber:phone];
            isDefaultBehaviorAllowed = NO;
        }
    }

    DDLogSupport(@"textView should interact With URL:%@", isDefaultBehaviorAllowed ? @"YES" : @"NO" );
    return isDefaultBehaviorAllowed;
}

#pragma mark * AckViewDelegate
- (void)ackGotForAckView:(AckView *)ackView
{
    if (!self.isMyMessage)
    {
        if ([self.delegate respondsToSelector:@selector(ackGotForConversationTableViewCell:)])
        {
            BOOL success = [self.delegate ackGotForConversationTableViewCell:self];
            if (success) {
                self.ackView.totalRecipientCount = self.chatMessage.totalRecipientCount;
                self.ackView.ackedRecipientCount = self.chatMessage.ackedRecipientCount;
                [self.ackView setAckViewWithState:AckViewStateAckGiven isMyMessage:self.isMyMessage isHaveAttachment:[self.chatMessage hasAttachment]];
                
            }
        }
    }
}

- (void)replaceAckViewWithString:(AckView *)ackView
{
    //    self.ackView.hidden = YES;
    if ([self.delegate respondsToSelector:@selector(conversationTableViewCellNeedUpdate:)])
        [self.delegate conversationTableViewCellNeedUpdate:self];
}
#pragma mark * QliqAssistedViewDelegate

- (void)tapDetectedForQliqAssistedView:(QliqAssistedView *)qliqAssistedView {
    
    if (self.checkmarkButton.hidden) {
        //oppen alert
        if ([qliqAssistedView.phoneNumbers count] > 1) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(cell:qliqAssistedViewWasTappedWithPhoneNumbers:)]) {
                [self.delegate cell:self qliqAssistedViewWasTappedWithPhoneNumbers:qliqAssistedView.phoneNumbers];
            }
        } else {
            if (self.delegate && [self.delegate respondsToSelector:@selector(phoneNumberWasPressedInCell:andPhoneNumber:)])
                [self.delegate phoneNumberWasPressedInCell:self andPhoneNumber:qliqAssistedView.phoneNumbers.firstObject];
        }    }
}

- (void)replaceQliqAssistedView:(QliqAssistedView *)qliqAssistedView {
    if ([self.delegate respondsToSelector:@selector(conversationTableViewCellNeedUpdate:)])
        [self.delegate conversationTableViewCellNeedUpdate:self];
}

#pragma mark * AttachmentViewDelegate

- (void)attachmentViewTaped:(AttachmentView *)attachmentView
{
    if ([self.delegate respondsToSelector:@selector(conversationTableViewCell:didTappedAttachment:)])
        [self.delegate conversationTableViewCell:self didTappedAttachment:attachmentView.attachment];
}

#pragma mark * ProgressObservingDelegate

- (void)progressHandler:(ProgressHandler *)progressHandler didChangeProgress:(CGFloat)progress
{
    if (self.showProgressBar)
        progress *= 0.75;
    
    [self.attachmentImage setProgress:progress];
}

- (void)progressHandler:(ProgressHandler *)progressHandler didChangeState:(ProgressState)state
{
    if (state != ProgressStateDownloading && state != ProgressStateUploading)
    {
        if ([self.delegate respondsToSelector:@selector(conversationTableViewCell:didChangedAttachmentState:)])
            [self.delegate conversationTableViewCell:self didChangedAttachmentState:state];
        
        if ([self.delegate respondsToSelector:@selector(reloadCellWithMessageUUID:)])
        {
            /* Reload ChatMessage from database and refresh cell with new one */
            [self.delegate reloadCellWithMessageUUID:self.chatMessage.uuid];
        }
    }
}

@end
