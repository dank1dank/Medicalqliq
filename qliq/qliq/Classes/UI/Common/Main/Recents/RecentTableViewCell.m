//
//  RecentTableViewCell.m
//  qliq
//
//  Created by Valerii Lider on 7/29/14.
//
//

#import "RecentTableViewCell.h"

//Helpers
#import "NSDate-Utilities.h"

//Objects
#import "Conversation.h"
#import "Recipients.h"
#import "FhirResources.h"
#import "ResizeBadge.h"

//Services
#import "QliqConnectModule.h"
#import "ConversationDBService.h"
#import "QliqGroupDBService.h"

#import "QliqUserDBService.h"
#import "ChatMessageService.h"

#import "QliqAssistedView.h"

//Constraints Defines
#define kMessageViewLeftConstraint 5.f
#define kBadgeMargin 2.f
#define kTotalFreeSpaceBadgeValueForPortraitOrientation 30.f
#define kTotalFreeSpaceBadgeValueForLandscapeOrientation 80.f
#define kValueSubjectWithTextHeight 21.f
#define kValueSubjectWithoutTextHeight 5.f

@interface RecentTableViewCell()

//AvatarView
@property (weak, nonatomic) IBOutlet UIView *avatarView;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;

//MessageView
@property (weak, nonatomic) IBOutlet UIView *messageView;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *subject;
@property (weak, nonatomic) IBOutlet UILabel *message;
@property (weak, nonatomic) IBOutlet UILabel *badgeValue;

//TimeView
@property (weak, nonatomic) IBOutlet UIView *timeView;
@property (weak, nonatomic) IBOutlet UITextView *time;

@property (weak, nonatomic) IBOutlet UIImageView *mutedView;

////StatusView
@property (weak, nonatomic) IBOutlet UIView *groupIndicatorsView;
@property (weak, nonatomic) IBOutlet UIImageView *eyeImageView;
@property (weak, nonatomic) IBOutlet UILabel *eyeNumber;
@property (weak, nonatomic) IBOutlet UIImageView*planeImageView;
@property (weak, nonatomic) IBOutlet UILabel *planeNumber;
@property (weak, nonatomic) IBOutlet UIImageView *flag;

//OptionsView
@property (weak, nonatomic) IBOutlet UIView *optionsView;
@property (weak, nonatomic) IBOutlet UIButton *optionCall;
@property (weak, nonatomic) IBOutlet UIButton *optionFlag;
@property (weak, nonatomic) IBOutlet UIButton *optionSave;
@property (weak, nonatomic) IBOutlet UIButton *optionDelete;

//Constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *badgeValueWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *badgeValueLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *badgeValueTopConstraint;

// Used for clearing the empty space if there is no subject for the conversation
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *subjectHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *optionsViewLeftConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *optionsWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageHorizontalSpaceContraint;

//Data
@property (nonatomic, strong) Conversation *conversation;

@end

@implementation RecentTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self layoutIfNeeded];
    //Add Gesture Recognizers
    {
        UISwipeGestureRecognizer *swipeRecognizerLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(leftSwipe:)];
        [swipeRecognizerLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
        [self addGestureRecognizer:swipeRecognizerLeft];
        
        UISwipeGestureRecognizer *swipeRecognizerRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(rightSwipe:)];
        [swipeRecognizerRight setDirection:UISwipeGestureRecognizerDirectionRight];
        [self addGestureRecognizer:swipeRecognizerRight];
    }
    
    self.subject.numberOfLines = 1;
    self.subject.minimumScaleFactor = 10.f / self.subject.font.pointSize;
    self.subject.adjustsFontSizeToFitWidth = YES;
    
    self.badgeValue.layer.cornerRadius = 7.f;
    self.badgeValue.clipsToBounds = YES;
    
    [self prepareForReuse];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.badgeValue.hidden = YES;
    self.badgeValue.text = @"";
    
    self.eyeImageView.hidden = YES;
    self.eyeNumber.text = @"";
    
    self.planeImageView.hidden = YES;
    self.planeNumber.text = @"";
    
    self.timeView.hidden = YES;
    self.groupIndicatorsView.hidden = YES;
    
    self.subject.text = @"";
    self.name.text = @"";
    self.message.text = @"";
    
    self.conversation = nil;
    
    [self configureBackroundColor:[UIColor whiteColor]];
}

#pragma mark - Public -

- (void)configureCellWithConversation:(Conversation *)conversation withSelectedCell:(Conversation *)selectedConversation
{
    if (conversation.conversationId == selectedConversation.conversationId) {
        __block __weak typeof(self) weakSelf = self;
            [weakSelf showOptions];
    }
    else {
        [self hideOptions];
    }
    
    [self configureCellWithConversation:conversation];
}

- (void)configureCellWithConversation:(Conversation *)conversation
{
    if (!conversation) {
        return;
    }
    
    self.conversation = conversation;
    
    
    FhirEncounter *encounter = nil;
    if (conversation.isCareChannel) {
        if (conversation.encounter)
            encounter = conversation.encounter;
        else {
            encounter = [FhirEncounterDao findOneWithUuid:conversation.uuid];
            self.conversation.encounter = encounter;
        }
    }
    
    NSString *careChannelParticipants = nil;
    NSArray *recipients = [self.conversation.recipients allRecipientsWithoutCurrentUser];
    id user = [recipients lastObject];
    
    //Set Name
    {
        NSString *name = @"";
        
        if (conversation.isCareChannel) {
            
            name = encounter.patient.fullName;
            
            if ([user isKindOfClass:[QliqUser class]] && [self.conversation.recipients isMultiparty]) {
                NSArray *users = [self.conversation.recipients allRecipients];
                careChannelParticipants = [[users valueForKeyPath:@"firstName"] componentsJoinedByString:@", "];
#ifdef DEBUG
                // Adam Sowa: when testing I prefer to see last names to identify MPs
                careChannelParticipants = [[users valueForKeyPath:@"lastName"] componentsJoinedByString:@"; "];
#endif
            }
            else if ([user isKindOfClass:[QliqUser class]] ) {
                careChannelParticipants = [user recipientTitle];
            }
            
        } else {
            
            if ([user isKindOfClass:[QliqGroup class]]) {
                
                if (!conversation.isBroadcast) {
                    ChatMessage * lastMessage = [[ChatMessageService sharedService] getLatestMessageInConversation:conversation.conversationId];
                    conversation.lastMsg = lastMessage.text;
                    name = [[[QliqUserDBService sharedService] getUserWithId:lastMessage.fromQliqId] recipientTitle];
                }
                
                if (name.length == 0) {
                    name = ((QliqGroup*)user).name;
                }
            }
            else if ([user isKindOfClass:[QliqUser class]] && [self.conversation.recipients isMultipartyWithoutCurrentUser]) {
                NSArray *users = recipients;
                name = [[users valueForKeyPath:@"firstName"] componentsJoinedByString:@", "];
#ifdef DEBUG
                // Adam Sowa: when testing I prefer to see last names to identify MPs
                name = [[users valueForKeyPath:@"lastName"] componentsJoinedByString:@"; "];
#endif
            }
            else if ([user isKindOfClass:[QliqUser class]] ) {
                name = [user recipientTitle];
            }
        }
        
        if ([name isEqualToString:@""] || !name) {
            name = @"<null>";
        }
        
        name = [name stringByReplacingOccurrencesOfString:@"<null>" withString:QliqLocalizedString(@"2391-TitleUnknownContact")];
        //self.name.text = [conversation.recipients displayNameWrappedToWidth:self.name.frame.size.width font:self.name.font];
        //to
        self.name.text = name;
    }
    //Set Conversation Subject
    {
        if (conversation.isCareChannel)
        {
            if (encounter.location.floor.length != 0 && encounter.location.room.length != 0) {
                self.subject.text = encounter.summaryTextForRecentsList;
            }
            else
            {
                self.subject.text = encounter.patient.demographicsText;
            }
        }
        else if([user isKindOfClass:[QliqGroup class]])
        {
            if (conversation.isBroadcast)
            {
                self.subject.text = [NSString stringWithFormat:@"[%@]", QliqLocalizedString(@"2108-TitleBroadcast")];
            }
            else
            {
                self.subject.text = [NSString stringWithFormat:@"%@ [%@]", ((QliqGroup *)user).name, QliqLocalizedString(@"2330-TitleGroup")];
            }

            if (conversation.subject.length > 0) {
                self.subject.text = [self.subject.text stringByAppendingString:[NSString stringWithFormat:@" %@", conversation.subject]];
            }
        }
        else
        {
            if (conversation.isBroadcast)
            {
                self.subject.text = [NSString stringWithFormat:@"[%@]", QliqLocalizedString(@"2108-TitleBroadcast")];
            }
            
            if (conversation.subject.length != 0) // Used for clearing the empty space if there is no subject for the conversation
            {
                if (conversation.isBroadcast)
                {
                    self.subject.text = [self.subject.text stringByAppendingString:@" "];
                }
                
                self.subject.text = [self.subject.text stringByAppendingString:conversation.subject];
                
                if (conversation.broadcastType == NotBroadcastType) {
                    
                    NSString *presenseStatusText = [[UserSessionService currentUserSession].userSettings.presenceSettings convertPresenceStatusForSubjectType:conversation.subject];
                    if (presenseStatusText) {
                        self.subject.text = presenseStatusText;
                    }
                }
                self.subjectHeightConstraint.constant = 21.f;
            }
        }
        self.subjectHeightConstraint.constant = self.subject.text.length != 0 ? kValueSubjectWithTextHeight : kValueSubjectWithoutTextHeight;
        self.subject.hidden = self.subject.text.length == 0;
    }
    //Set Text Last message
    {
        if (!conversation.isCareChannel) {

            NSString *correctedMessage = [QliqAssistedView getCorrectedPhoneNumberForMessage:[[ChatMessageService sharedService] getLatestMessageInConversation:conversation.conversationId]];
            if (correctedMessage.length > 0) {
                conversation.lastMsg = correctedMessage;
            }
            ChatMessage * lastMessage = [[ChatMessageService sharedService] getLatestMessageInConversation:conversation.conversationId];
            self.message.text = lastMessage.text;
        } else {
            self.message.text = careChannelParticipants;
        }
    }
    //SetBadge
    {
        self.badgeValue.text = [NSString stringWithFormat:@"%ld", (long)conversation.numberUnreadMessages];
        self.badgeValue.hidden = conversation.numberUnreadMessages == 0;
        if (!self.badgeValue.hidden)
        {
            UIApplication *application = [UIApplication sharedApplication];
            NSInteger orientation = [application statusBarOrientation];
            //Calculating the totalFreeSpace for width of badge depending from UIInterfaceOrientation
            CGFloat totalFreeSpace = orientation == UIInterfaceOrientationPortrait ? kTotalFreeSpaceBadgeValueForPortraitOrientation : kTotalFreeSpaceBadgeValueForLandscapeOrientation;
            //Configure badge with for new text (calculating width badge, changing value of `badgeValue.text` if needed).
            __weak __block typeof(self) welf = self;
            [ResizeBadge resizeBadge:welf.badgeValue
                                    totalFreeSpace:totalFreeSpace
                                   canTextBeScaled:NO
                           setBadgeWidthCompletion:^(CGFloat calculatedWidth) {
                               //Method for setting width of badge and calculating shift for badgeValue.
                               [welf setBadgeWidth:calculatedWidth withTotalFreeSpace:totalFreeSpace configureShiftConstraint:welf.badgeValueLeadingConstraint];
                           }];
        }
    }
    
    //Status Conversation
    {
        self.eyeNumber.text = [NSString stringWithFormat:@"%ld", (long)conversation.numberUnreadMessages];
        self.planeNumber.text = [NSString stringWithFormat:@"%ld", (long)conversation.numberUndeliveredMessages];
    }
    //Set Avatar
    {
        if (encounter.patient) {
            self.avatarImageView.image = [[QliqAvatar sharedInstance] getAvatarForItem:encounter.patient withTitle:encounter.patient.fullName];;
        } else {
            self.avatarImageView.image = [[QliqAvatar sharedInstance] getAvatarForItem:recipients withTitle:self.name.text];
        }
    }
    
    //Set Time
    { //1425071277
        self.timeView.hidden = NO;
        
        NSDate *conversationDate = [NSDate dateWithTimeIntervalSince1970:conversation.lastUpdated];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.timeStyle = NSDateFormatterShortStyle;
        formatter.doesRelativeDateFormatting = YES;
        NSString *time = [formatter stringFromDate:conversationDate];
        
        formatter = nil;
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateStyle = NSDateFormatterMediumStyle;
        formatter.doesRelativeDateFormatting = YES;
        NSString *date = [formatter stringFromDate:conversationDate];
        
        NSString *timeString = @"";
        if ([conversationDate isToday]) {
            timeString = [NSString stringWithFormat:@"%@",time];
        }
        else {
            timeString = [NSString stringWithFormat:@"%@\n%@", date ,time];
        }
        
        self.time.text = timeString;
    }
    
    //Set Muted
    {
        self.mutedView.hidden = !self.conversation.isMuted;
    }
}

- (void)configureBackroundColor:(UIColor *)color {
    self.backgroundColor = color;
    self.avatarView.backgroundColor = color;
}

- (void)showOptions
{
    if (self.optionsViewLeftConstraint.constant == 0.f) {
        self.optionsView.hidden = NO;
        __weak __block typeof(self) welf = self;
        [UIView animateWithDuration:0.5 animations:^{
            welf.optionsViewLeftConstraint.constant = -welf.optionsWidthConstraint.constant;
            [welf layoutIfNeeded];
        } completion:nil];
    }
}

- (void)hideOptions
{
    if (self.optionsViewLeftConstraint.constant == -self.optionsWidthConstraint.constant)
    {
        __weak __block typeof(self) welf = self;
        [UIView animateWithDuration:0.5 animations:^{
            welf.optionsViewLeftConstraint.constant = 0;
            [welf layoutIfNeeded];
        } completion:^(BOOL finished) {
            welf.optionsView.hidden = YES;
        }];
    }
    else if (self.optionsView.hidden == NO)
    {
        self.optionsView.hidden = YES;
    }
}

- (void)setBadgeWidth:(CGFloat)calculatedWidth
    withTotalFreeSpace:(CGFloat)totalFreeSpace
configureShiftConstraint:(NSLayoutConstraint *)shiftConstraint {
    
    CGFloat sumBadgeWidthWithBadgeShift = calculatedWidth + kBadgeMargin;
    CGFloat badgeTrailingDistance = totalFreeSpace - sumBadgeWidthWithBadgeShift;
    
    if (badgeTrailingDistance >= kBadgeMargin)
    {
        shiftConstraint.constant = kBadgeMargin;
    }
    else
    {
        CGFloat badgeLeadingDistance = (totalFreeSpace - calculatedWidth)/2;
        shiftConstraint.constant = badgeLeadingDistance;
    }
    self.badgeValueWidthConstraint.constant = calculatedWidth;
    [self.badgeValue layoutIfNeeded];
}

#pragma mark - Actions -

#pragma mark * IBActions

- (IBAction)onCall:(id)sender {
    if (!self.conversation) {
        return;
    }
    
    UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:NSLocalizedString(@"1042-TextCall", @"Call phone number")
                                                                  message:NSLocalizedString(@"1180-TextCallConversation", nil)
                                                                 delegate:nil
                                                        cancelButtonTitle:NSLocalizedString(@"2-ButtonNO", nil)
                                                        otherButtonTitles:NSLocalizedString(@"3-ButtonYES", nil), nil];
    __block __weak typeof(self) weakSelf = self;
    [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
        
        if (buttonIndex != alert.cancelButtonIndex) {
            
            Contact *user = nil;
            
            //Get User From Conversation
            for (id recipient in weakSelf.conversation.recipients.allRecipients)
            {
                if ([recipient isKindOfClass:[Contact class]] || [recipient isKindOfClass:[QliqUser class]]) {
                    
                    if ( ((Contact*)recipient).mobile.length) {
                        user = recipient;
                        break;
                    }
                }
            }
            
            if (!user) {
                UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:NSLocalizedString(@"1042-TextCall", @"Call phone number")
                                                                              message:NSLocalizedString(@"1057-TextPhoneNumberMissing", nil)
                                                                             delegate:nil
                                                                    cancelButtonTitle:NSLocalizedString(@"1-ButtonOK", nil)
                                                                    otherButtonTitles:nil];
                [alert showWithDissmissBlock:^(NSInteger buttonIndex) {}];
                return;
            }
            
            
            //Ring Number
            NSString *phoneUrl = [NSString stringWithFormat:@"tel://%@", user.mobile];
            phoneUrl = [phoneUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSURL *url = [NSURL URLWithString:phoneUrl];
            [[UIApplication sharedApplication] openURL:url];
            
            if ([weakSelf.delegate respondsToSelector:@selector(pressCallButton:)]) {
                [weakSelf.delegate pressCallButton:weakSelf.conversation];
            }
        }
    }];
}

- (IBAction)onFlag:(id)sender
{
    if (!self.conversation) {
        return;
    }
    
    UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:NSLocalizedString(@"1181-TextFlag", nil)
                                                                  message:NSLocalizedString(@"1182-TextAskCheckFlag?", nil)
                                                                 delegate:nil
                                                        cancelButtonTitle:NSLocalizedString(@"2-ButtonNO", nil)
                                                        otherButtonTitles:NSLocalizedString(@"3-ButtonYES", nil), nil];
    __block __weak typeof(self) weakSelf = self;
    [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
        
        if (buttonIndex != alert.cancelButtonIndex) {
            
            if ([weakSelf.delegate respondsToSelector:@selector(pressFlagButton:)]) {
                [weakSelf.delegate pressFlagButton:weakSelf.conversation];
            }
        }
    }];
}

- (IBAction)onSave:(id)sender
{
    if (!self.conversation) {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(pressSaveButton:)]) {
        [self.delegate pressSaveButton:self.conversation];
    }
}

- (IBAction)onDelete:(id)sender
{
    if (!self.conversation) {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(pressDeleteButton:)]) {
        [self.delegate pressDeleteButton:self.conversation];
    }
}

#pragma mark * GestureRecognizer Action

- (void)leftSwipe:(UISwipeGestureRecognizer *)sender {
    
    if (!self.conversation) {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(cellLeftSwipe:)]) {
        [self.delegate cellLeftSwipe:self.conversation];
    }
}

- (void)rightSwipe:(UISwipeGestureRecognizer *)sender {
    
    if ([self.delegate respondsToSelector:@selector(cellRightSwipe)]) {
        [self.delegate cellRightSwipe];
    }
}

@end
