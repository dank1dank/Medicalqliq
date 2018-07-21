//
//  KeyboardAccessoryViewController.m
//  qliq
//
//  Created by Valeriy Lider on 8/7/14.
//
//

#import "KeyboardAccessoryViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>

//#import "ImagesSelectionIndicatorView.h"
#import "RecordAudioViewController.h"
#import "MediaGroupsListViewController.h"
#import "MessageAttachment.h"
#import "MediaFile.h"
#import "NSString+Filesize.h"
#import "AlertController.h"

#import "EGOTextView.h"
#import "AttachmentView.h"

#import "VideoAttachmentViewController.h"

#define kValueFlagViewHeight                32.f
#define kValueMinimumHeightTextView         36.f
#define kValueMinimumHeightKeyboardAccessoryViewWithAttachment    80.f
#define kMinimumHeightKeyboardAccessoryViewWithSelectAttachment   80.f
#define kMaxHeightOfTextViewResignedFirstResponder 100.f

#define kValueTextViewMaxHeightPortraitOnEditing     76.f
#define kValueTextViewMaxHeightLandscape             36.f

#define kValueDefaultCharactersLeft         240
#define kValueBlinkTimeInterval             2.0
#define kValueChangeAnimationTimeInterval   0.3


typedef NS_ENUM(NSInteger, AttachmentType) {
    AttachmentDocument = 1,
    AttachmentPictures,
    AttachmentPhoto,
    AttachmentAudio,
    AttachmentVideo
};

@interface KeyboardAccessoryViewController ()
<
RecordAudioViewControllerDelegate,
MediaGroupsListViewControllerDelegate,
HPGrowingTextViewDelegate,
UIImagePickerControllerDelegate,
UINavigationControllerDelegate,
UIGestureRecognizerDelegate
>

/**
 IBOutlet
 */
@property (nonatomic, weak, readwrite) IBOutlet UIView *selectAttachmentView;
@property (weak, nonatomic) IBOutlet UIView *textViewContainer;

@property (nonatomic, weak) IBOutlet UIScrollView *flagsScrollView;

@property (nonatomic, weak) IBOutlet UIButton *flagsButton;
@property (nonatomic, weak) IBOutlet UIButton *requestAck;
@property (weak, nonatomic) IBOutlet UIImageView *checkmarkForRequestAck;

@property (weak, nonatomic) IBOutlet UIView *textInputBackGroundView;


@property (nonatomic, weak) IBOutlet UIButton *quickMessage;
@property (nonatomic, weak) IBOutlet UIButton *send;
@property (nonatomic, weak) IBOutlet UIButton *attachmentsButton;

@property (nonatomic, weak) IBOutlet UIButton *FYIButton;
@property (weak, nonatomic) IBOutlet UIImageView *checkmarkForFYI;
@property (nonatomic, weak) IBOutlet UIButton *ASAPButton;
@property (weak, nonatomic) IBOutlet UIImageView *checkmarkForASAP;
@property (nonatomic, weak) IBOutlet UIButton *UrgentButton;
@property (weak, nonatomic) IBOutlet UIImageView *checkmarkForUrgent;
@property (weak, nonatomic) IBOutlet UIView *flagView;

@property (weak, nonatomic) IBOutlet UIView *pagerOnlyView;
@property (weak, nonatomic) IBOutlet UILabel *pagerUserWarning;
@property (weak, nonatomic) IBOutlet UILabel *doNotIncludePHI;
@property (weak, nonatomic) IBOutlet UILabel *pagerNumber;
@property (weak, nonatomic) IBOutlet UILabel *charactersLeft;
@property (weak, nonatomic) IBOutlet UIImageView *pagerIndicator;
@property (assign, nonatomic) BOOL isPagerUserLabelShowed;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *pagerUserLabelVerticalAlignConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *doNotIncludePHIVerticalAlignConstraint;

@property (nonatomic, assign) BOOL isPagerUserConversation;

/* Constraint */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *attachHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *attachViewBotConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *flagViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *flagViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *internalTextViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *internalTextViewTopConstraint;

@property (assign, nonatomic) BOOL flagOrPagerOnlyViewAppearing;
@property (assign, nonatomic) BOOL shouldShowFlagView;
@property (assign, nonatomic) BOOL isFirstAppearanceOfView;
@property (assign, nonatomic) BOOL resize;

@property (copy, nonatomic) VoidBlock heightChangeCompletion;

@end

@implementation KeyboardAccessoryViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.attachmentsList = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(blinkPagerUserWarningView) object:nil];
    self.heightChangeCompletion = nil;
    self.attachmentsButton = nil;
}

- (void)configureDefaultText {
    [self.flagsButton setTitle:QliqLocalizedString(@"54-ButtonFlag") forState:UIControlStateNormal];
    
    [self.requestAck setTitle:QliqLocalizedString(@"55-ButtonRequestAck") forState:UIControlStateNormal];
    
    [self.quickMessage setTitle:QliqLocalizedString(@"56-BUttonQuickMessage") forState:UIControlStateNormal];
    
    [self.send setTitle:QliqLocalizedString(@"10-ButtonSend") forState:UIControlStateNormal];
    
    self.placeholderLabel.text = QliqLocalizedString(@"2194-TitleTypeMessageHere");
    
    [self.FYIButton setTitle:QliqLocalizedString(@"2377-TitleFYI") forState:UIControlStateNormal];
//    [self.FYIButton setTitle:QliqLocalizedString(@"2377-TitleFYI") forState:UIControlStateHighlighted];
    [self.ASAPButton setTitle:QliqLocalizedString(@"2378-TitleASAP") forState:UIControlStateNormal];
//    [self.ASAPButton setTitle:QliqLocalizedString(@"2378-TitleASAP") forState:UIControlStateHighlighted];
    [self.UrgentButton setTitle:QliqLocalizedString(@"2379-TitleUrgent") forState:UIControlStateNormal];
//    [self.UrgentButton setTitle:QliqLocalizedString(@"2379-TitleUrgent") forState:UIControlStateHighlighted];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureDefaultText];
    
    self.flagOrPagerOnlyViewAppearing = NO;
    self.isFirstAppearanceOfView = YES;
    self.textViewWillResignFirstResponder = NO;
    self.isMessageSent = NO;
    self.resize = NO;
    //Notifications
    {
        [self addObserversForKeyboardNotifications];
    }
    
    //FlagsScrollView
    {
        [self.flagsScrollView setContentSize:CGSizeMake(self.flagsScrollView.frame.size.width, self.flagsScrollView.frame.size.height*2.f)];
    }
    
    //TextView
    {
        self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.textView.delegate = self;
        self.textView.minHeight = 20.f;
        self.textView.internalTextView.font = [UIFont systemFontOfSize:18.0];
        self.textView.internalTextView.autocorrectionType = UITextAutocorrectionTypeYes;
        self.textView.internalTextView.spellCheckingType = UITextSpellCheckingTypeYes;
        self.textView.internalTextView.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        [self.textView setBackgroundColor:[UIColor clearColor]];
        
        self.textInputBackGroundView.layer.cornerRadius = 3.f;
        
        if([self.textView.internalTextView respondsToSelector:@selector(setSpellCheckingType:)]){
            self.textView.internalTextView.spellCheckingType = UITextSpellCheckingTypeYes;
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
}

- (void)didRotate:(NSNotification *)notification {
    [self getMaxHeightForTextView];
    [self.textView.internalTextView textChanged];
    
    CGRect frame = [self.textView.internalTextView getFrameToScrollToTop:NO];
    [self.textView.internalTextView scrollRectToVisible:frame animated:self.textView.internalTextView.scrollEnabled];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!self.isFirstAppearanceOfView)
        [self setSizeForViews];
    else
        self.isFirstAppearanceOfView = NO;
    
    if (self.isPagerUserConversation) {
        [self setTextForPagerOnlyViewLabels];
    }
}

#pragma mark - Setter -

- (void)setIsRequestAck:(BOOL)isRequestAck
{
    _isRequestAck = isRequestAck;
    [self.checkmarkForRequestAck setImage:[UIImage imageNamed:isRequestAck ? @"ConversationCheckYes" : @"ConversationCheckNo"]];
}

- (void)setMessagePriority:(ChatMessagePriority)messagePriority
{
    _messagePriority = messagePriority;
    
    switch (messagePriority) {
            
        case ChatMessagePriorityForYourInformation: {
            [self.checkmarkForFYI     setImage:[UIImage imageNamed:@"ConversationCheckYes"]];
            [self.checkmarkForASAP    setImage:[UIImage imageNamed:@"ConversationCheckNo"]];
            [self.checkmarkForUrgent  setImage:[UIImage imageNamed:@"ConversationCheckNo"]];
            break;
        }
            
        case ChatMessagePriorityAsSoonAsPossible: {
            [self.checkmarkForFYI     setImage:[UIImage imageNamed:@"ConversationCheckNo"]];
            [self.checkmarkForASAP    setImage:[UIImage imageNamed:@"ConversationCheckYes"]];
            [self.checkmarkForUrgent  setImage:[UIImage imageNamed:@"ConversationCheckNo"]];
            break;
        }
            
        case ChatMessagePriorityUrgen: {
            [self.checkmarkForFYI     setImage:[UIImage imageNamed:@"ConversationCheckNo"]];
            [self.checkmarkForASAP    setImage:[UIImage imageNamed:@"ConversationCheckNo"]];
            [self.checkmarkForUrgent  setImage:[UIImage imageNamed:@"ConversationCheckYes"]];
            break;
        }
            
        default: {
            [self.checkmarkForFYI     setImage:[UIImage imageNamed:@"ConversationCheckNo"]];
            [self.checkmarkForASAP    setImage:[UIImage imageNamed:@"ConversationCheckNo"]];
            [self.checkmarkForUrgent  setImage:[UIImage imageNamed:@"ConversationCheckNo"]];
            break;
        }
    }
}

#pragma mark - Notifications -

- (void)addObserversForKeyboardNotifications
{
    /*
     NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
     [center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
     [center addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
     [center addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
     [center addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
     */
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviewSwitchToAudio:) name:@"MoviewSwitchToAudio" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviewSwitchToPhoto:) name:@"MoviewSwitchToPhoto" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addAttachmentToMessage:) name:@"AddAttachmentToMessage" object:nil];
}

#pragma mark * Notification Handling

- (void)moviewSwitchToAudio:(NSNotification*)aNotification
{
    [self openAudioRecorder];
}

- (void)moviewSwitchToPhoto:(NSNotification*)aNotification
{
    __block __weak typeof(self) weakSelf = self;
    [QliqHelper getPickerForMode:PickerModePhoto forViewController:self returnPicker:^(id picker, NSError *error) {
        if (error) {
            [AlertController showAlertWithTitle:nil
                                        message:[error.userInfo valueForKey:@"NSLocalizedDescription"]
                                    buttonTitle:nil
                              cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                     completion:NULL];
        } else if (picker) {
            dispatch_async_main(^{
                [weakSelf.parentViewController.navigationController presentViewController:picker animated:YES completion:nil];
            });
        }
    }];
}

- (void)addAttachmentToMessage:(NSNotification*)aNotification
{
    if ([[aNotification object] isKindOfClass:[MessageAttachment class]])
    {
        MessageAttachment *attachment = [aNotification object];
        [self addAttachment:attachment];
    }
}

#pragma mark * Keyboard Notifications

/*
 - (void)keyboardWillShow:(NSNotification*)notification {
 NSLog(@"%s\n%@\n\n",__PRETTY_FUNCTION__ ,notification.userInfo);
 
 CGRect r = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
 CGFloat t = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
 
 [UIView beginAnimations:nil context:NULL];
 [UIView setAnimationDuration:t];
 [UIView setAnimationBeginsFromCurrentState:YES];
 
 CGRect rect = self.view.superview.frame;
 rect.origin.y = r.origin.y - 64.f - self.view.frame.size.height;
 self.view.superview.frame = rect;
 
 [UIView commitAnimations];
 }
 
 - (void)keyboardDidShow:(NSNotification*)notification {
 NSLog(@"%s\n%@\n\n",__PRETTY_FUNCTION__ ,notification.userInfo);
 }
 
 - (void)keyboardWillHide:(NSNotification*)notification {
 NSLog(@"%s\n%@\n\n",__PRETTY_FUNCTION__ ,notification.userInfo);
 }
 
 - (void)keyboardDidHide:(NSNotification*)notification {
 NSLog(@"%s\n%@\n\n",__PRETTY_FUNCTION__ ,notification.userInfo);
 }
 */

#pragma mark - Public -

- (void)hideCharactersLeftCountLabel:(BOOL)hidden
{
    self.charactersLeft.hidden = hidden;
    self.pagerIndicator.hidden = !hidden;
}

- (void)hiddenAttachmentView:(BOOL)hidden
{
    [self.attachmentsButton setImage:[UIImage imageNamed: hidden? @"KeyboardAttachmentsDown" : @"KeyboardAttachments"] forState:UIControlStateNormal];
    self.selectAttachmentView.hidden = !hidden;
}

- (void)hiddenPagerOnlyView:(BOOL)hidden
{
    self.isPagerUserConversation = !hidden;
    self.flagsButton.hidden = !hidden;
    self.flagsScrollView.hidden = !hidden;
    self.pagerOnlyView.hidden = hidden;    
    self.attachmentsButton.hidden = !hidden;
    self.pagerIndicator.hidden = hidden;
    
    if (!hidden)
    {
        //Pager labels
        {
            self.pagerNumber.numberOfLines = 1;
            self.pagerNumber.adjustsFontSizeToFitWidth = YES;
            self.pagerNumber.minimumScaleFactor = 12.f / self.pagerNumber.font.pointSize;
            
            self.pagerUserWarning.numberOfLines = 1;
            self.pagerUserWarning.adjustsFontSizeToFitWidth = YES;
            self.pagerUserWarning.minimumScaleFactor = 12.f / self.pagerUserWarning.font.pointSize;
            
            self.doNotIncludePHI.numberOfLines = 1;
            self.doNotIncludePHI.adjustsFontSizeToFitWidth = YES;
            self.doNotIncludePHI.minimumScaleFactor = 12.f / self.doNotIncludePHI.font.pointSize;
            
            self.charactersLeft.numberOfLines = 1;
            self.charactersLeft.adjustsFontSizeToFitWidth = YES;
            self.charactersLeft.minimumScaleFactor = 9.f / self.charactersLeft.font.pointSize;
        }
        [self setTextForPagerOnlyViewLabels];
    }
}

#pragma mark * Public access to properties for configure input views

- (NSArray *)attachments {
    return [NSArray arrayWithArray:self.attachmentsList];
}

- (NSString*)currentMessage {
    return [self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

-(BOOL)needsAck {
    return self.isRequestAck;
}

-(void)clearNeedsAck {
    self.isRequestAck = NO;
}

-(void)clearPriority {
    self.messagePriority = nil;
}

- (void)clearAllWithCompletion:(VoidBlock)completion
{
    self.heightChangeCompletion = completion;
    [self removeAttachments];
    [self clearNeedsAck];
    [self clearPriority];
    [self clearMessageTextWithCompletion:completion];
    
    if ([self.textView.internalTextView hasOldTextBeforeSending]) {
        [self.textView.internalTextView removeOldText];
    }
}

- (void)clearMessageTextWithCompletion:(VoidBlock)completion
{
    self.heightChangeCompletion = completion;
    self.textView.text = @"";
    [self.attachmentsList removeAllObjects];
    
    self.textView.internalTextView.text = @"";
    self.textView.internalTextView.attributedString = [[NSAttributedString alloc] initWithString:@""];
}

- (void)appendMessageText:(NSString *)messageStr
{
    [self.textView appendText:messageStr];
}

- (void)removeAttachments
{
    [self cleanAttachmentsArray];
    [self.textView removeAttachments];
}


- (BOOL)hasAttachment {
    BOOL hasAttachment = self.attachmentsList && self.attachmentsList.count > 0;
    return hasAttachment;
}

- (void)setupKAVForSingleFieldModeWithFreeSpace:(CGFloat)freeSpace
{
    CGFloat newTextViewHeight = freeSpace;
    CGFloat flagViewHeight = [self needToShowFlagView] ? kValueFlagViewHeight : 0;
    newTextViewHeight = newTextViewHeight - flagViewHeight;
    self.textView.maxHeight = newTextViewHeight - self.internalTextViewTopConstraint.constant - self.internalTextViewBottomConstraint.constant;
    if ([self.delegate respondsToSelector:@selector(changeHeightAccessoryViewTo:)])
        [self.delegate changeHeightAccessoryViewTo:freeSpace];
    
    self.textViewHeightConstraint.constant = newTextViewHeight;
}

- (BOOL)needToTurnOffSingleFieldMode
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(getMaxHeightForKeyboardAccessoryView)])
    {
        CGFloat maxKAVHeight = [self.delegate getMaxHeightForKeyboardAccessoryView];
        CGFloat minKAVHeight = [self getMinimumHeightForKeyboardAccessoryView];
        
        if (minKAVHeight > maxKAVHeight)
        {
            return NO;
        }
        else
        {
            return YES;
        }
    }
    
    return YES;
}

#pragma mark - Private -

- (BOOL)isSingleFieldMode
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(isSingleFieldModeSetup)])
        return [self.delegate isSingleFieldModeSetup];
    
    return NO;
}

- (void)setTextForPagerOnlyViewLabels {
    
    NSString *pagerNumberStr = @"";
    if (self.delegate && [self.delegate respondsToSelector:@selector(getPagerNumber)]) {
        pagerNumberStr = [self.delegate getPagerNumber];
    }
    
    [self setPagerNumberLabelText:pagerNumberStr];
    [self setCharactersLeftLabelText:self.textView.internalTextView.text];
    
    [self setPagerUserWarningLabelText:QliqLocalizedString(@"2374-PagerUser")];
    [self setDoNotIncludePHILabelText:QliqLocalizedString(@"2372-DoNotIncludePHI")];
    
}

- (void)setCharactersLeftLabelText:(NSString *)text {
    NSInteger count = kValueDefaultCharactersLeft - text.length;
    self.charactersLeft.text = [NSString stringWithFormat:@"%ld", (long)count];
}

- (void)setPagerNumberLabelText:(NSString *)text {
    self.pagerNumber.text  = text;
}

- (void)setPagerUserWarningLabelText:(NSString *)text {
    self.pagerUserWarning.text  = text;
}

- (void)setDoNotIncludePHILabelText:(NSString *)text {
    self.doNotIncludePHI.text = text;
}

- (void)showAttachment:(MessageAttachment *)attachment
{
    AttachmentView *attachmentView = [[AttachmentView alloc] init];
    attachmentView.frame = CGRectMake(0.0, 0.0, 44.0, 44.0);
    [attachmentView setAttachment:attachment];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    tapRecognizer.delegate = self;
    [attachmentView addGestureRecognizer:tapRecognizer];
    [self getMaxHeightForTextView];
    
    [self.textView removeAttachments];
    [self.textView insertAttachment:(id)attachmentView];
    
}

- (void)showFlagView:(BOOL)show
           pagerMode:(BOOL)pagerMode
        withDuration:(NSTimeInterval)duration
               delay:(NSTimeInterval)delay
             options:(UIViewAnimationOptions)options
      withCompletion:(void (^)(void))completion
{
    self.flagOrPagerOnlyViewAppearing = YES;
    CGFloat constant = show ? 0.f : - kValueFlagViewHeight;
    self.shouldShowFlagView = show;
    
    if (show)
    {
        self.flagView.hidden = !show;
        if (pagerMode)
        {
            self.flagsButton.hidden = YES;
            self.flagsScrollView.hidden = YES;
            self.pagerOnlyView.hidden = NO;
        }
        else
        {
            self.flagsButton.hidden = NO;
            self.flagsScrollView.hidden = NO;
            self.pagerOnlyView.hidden = YES;
        }
    }

    __weak __block typeof(self) welf = self;
    void (^animationBlock)(void) = ^{
        welf.flagViewBottomConstraint.constant = constant;
        
        if (pagerMode) {
            if (show)
            {
                welf.isPagerUserLabelShowed = YES;
                welf.pagerUserLabelVerticalAlignConstraint.constant = 0.0f;
                welf.doNotIncludePHIVerticalAlignConstraint.constant = welf.flagViewHeightConstraint.constant;
                welf.pagerUserWarning.hidden = !welf.isPagerUserLabelShowed;
                welf.doNotIncludePHI.hidden = welf.isPagerUserLabelShowed;
            }
        }
        
        [welf setSizeForViews];
        [welf.view.superview layoutSubviews];
    };
    
    void (^animationCompletionBlock)(void) = ^{
        
        if (show)
        {
            if (pagerMode)
                [welf blinkPagerUserWarningView];
        }
        else
        {
            if (pagerMode)
            {
                [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(blinkPagerUserWarningView) object:nil];
                welf.pagerOnlyView.hidden = YES;
            }
            welf.flagView.hidden = YES;
        }
        
        welf.flagOrPagerOnlyViewAppearing = NO;
        if (completion) {
            completion();
        }
    };
    
    if (duration > 0.f)
    {
        [UIView animateWithDuration:duration delay:delay options:options animations:^{
            animationBlock();
        } completion:^(BOOL finished) {
            animationCompletionBlock();
        }];
    }
    else
    {
        animationBlock();
        animationCompletionBlock();
    }
    
    if (pagerMode)
        [self hideCharactersLeftCountLabel:!show];
}

- (void)blinkPagerUserWarningView {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(blinkPagerUserWarningView) object:nil];
    
    NSTimeInterval interval = kValueBlinkTimeInterval - kValueChangeAnimationTimeInterval;
    self.isPagerUserLabelShowed = !self.isPagerUserLabelShowed;
    
    __weak __block typeof(self) welf = self;
    dispatch_async_main(^{
        [UIView animateWithDuration:kValueChangeAnimationTimeInterval
                         animations:^{
                             if (welf.isPagerUserLabelShowed)
                             {
                                 welf.pagerUserWarning.hidden = !welf.isPagerUserLabelShowed;
                                 welf.pagerUserLabelVerticalAlignConstraint.constant = 0.0f;
                                 welf.doNotIncludePHIVerticalAlignConstraint.constant = welf.flagViewHeightConstraint.constant;
                             }
                             else
                             {
                                 welf.doNotIncludePHI.hidden = welf.isPagerUserLabelShowed;
                                 welf.doNotIncludePHIVerticalAlignConstraint.constant = 0.0f;
                                 welf.pagerUserLabelVerticalAlignConstraint.constant = - welf.flagViewHeightConstraint.constant;
                             }
                             [welf.pagerOnlyView layoutSubviews];
                         }
                         completion:^(BOOL finished) {
                             if (welf.isPagerUserLabelShowed)
                                 welf.doNotIncludePHI.hidden = welf.isPagerUserLabelShowed;
                             else
                                 welf.pagerUserWarning.hidden = !welf.isPagerUserLabelShowed;
                             [welf performSelector:@selector(blinkPagerUserWarningView) withObject:nil afterDelay:interval];
                         }];
    });
}


- (BOOL)needToShowFlagView {
    BOOL needToShowFlag = self.shouldShowFlagView || [self.textView.internalTextView isFirstResponder];
    return needToShowFlag;
}

#pragma mark * Calculation

- (CGFloat)getMinimumHeightForKeyboardAccessoryView
{
    CGFloat minimumHeight = kValueMinimumHeightTextView;
    
    if (!self.selectAttachmentView.hidden)
        minimumHeight = self.attachHeightConstraint.constant + self.attachViewBotConstraint.constant;
    else if (self.shouldShowFlagView)
        minimumHeight = kValueFlagViewHeight + kValueMinimumHeightTextView;
    
    return minimumHeight;
}

- (CGFloat)getMaxHeightForTextView
{
    CGFloat maxHeightForTextView = 0.f;
    if (self.delegate && [self.delegate respondsToSelector:@selector(getMaxHeightForKeyboardAccessoryView)])
    {
        CGFloat maxHeightForKeyboardAccessoryView =  [self.delegate getMaxHeightForKeyboardAccessoryView];
        maxHeightForTextView = [self maxHeightForTextViewWithMaxKAVHeight:maxHeightForKeyboardAccessoryView];
    }
    else
    {
        if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation))
        {
            if ([self needToShowFlagView])
                maxHeightForTextView = kValueTextViewMaxHeightPortraitOnEditing;
            else
                maxHeightForTextView = kValueMinimumHeightTextView;
        }
        else
            maxHeightForTextView = kValueTextViewMaxHeightLandscape;
        
        CGFloat maxHeightForInternalTextView = maxHeightForTextView - self.internalTextViewTopConstraint.constant - self.internalTextViewBottomConstraint.constant;
        
        self.textView.maxHeight = maxHeightForInternalTextView;
    }
    
    [self.textView performSelector:@selector(egoTextViewSetupScroll) withObject:nil];
    
    return maxHeightForTextView;
}

- (CGFloat)maxHeightForTextViewWithMaxKAVHeight:(CGFloat)maxKAVHeight
{
    return [self maxHeightForTextViewWithMaxKAVHeight:maxKAVHeight andFlagViewHeight:[self needToShowFlagView] ? kValueFlagViewHeight : 0.f];
}

- (CGFloat)maxHeightForTextViewWithMaxKAVHeight:(CGFloat)maxKAVHeight andFlagViewHeight:(CGFloat)flagViewHeight
{
    CGFloat maxHeightForTextView = 0.f;
    maxHeightForTextView = maxKAVHeight - flagViewHeight;
    if (flagViewHeight == 0.f && !self.selectAttachmentView.hidden)
    {
        if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation) && !(maxKAVHeight > kMaxHeightOfTextViewResignedFirstResponder))
        {
            maxHeightForTextView = kMaxHeightOfTextViewResignedFirstResponder;
        }
        else if (!(maxKAVHeight > kMinimumHeightKeyboardAccessoryViewWithSelectAttachment))
        {
            maxHeightForTextView = kMinimumHeightKeyboardAccessoryViewWithSelectAttachment;
        }
    }
    
    CGFloat maxHeightForInternalTextView = maxHeightForTextView - self.internalTextViewTopConstraint.constant - self.internalTextViewBottomConstraint.constant;
    self.textView.maxHeight = maxHeightForInternalTextView;
    return maxHeightForTextView;
}

- (CGFloat)minHeightForTextView
{
    CGFloat minHeightForTextView = kValueMinimumHeightTextView;
    
    if ([self hasAttachment])
        minHeightForTextView = kValueMinimumHeightKeyboardAccessoryViewWithAttachment;
    
    return minHeightForTextView;
}


- (void)setSizeForViews
{
    NSInteger newSizeH = self.textView.internalTextView.contentSize.height;
    [self growingTextView:self.textView willChangeHeight:newSizeH];
}

#pragma mark * The Walking Dead Code
- (void)didSelectQliqLibraryAttachment:(MessageAttachment *)attachment
{
    [self addAttachment:attachment];
}

#pragma mark - Attachments
- (void)addAttachment:(MessageAttachment *)attachment
{
    const unsigned long long maximumSize = 20 * 1024 * 1024;
    unsigned long long fileSize = 0;
    
    NSString *filePath = attachment.mediaFile.decryptedPath;
    if ([filePath length] == 0)
    {
        if (attachment.mediaFile.fileSizeString.length > 0) {
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            fileSize = [[formatter numberFromString:attachment.mediaFile.fileSizeString] unsignedLongValue];
        } else {
            fileSize = [[attachment.mediaFile encryptedFileSizeNumber] unsignedLongLongValue];
        }
    }
    else
    {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSError *error = nil;
        NSDictionary *attributes = [fm attributesOfItemAtPath:filePath error:&error];
        if (error != nil)
        {
            DDLogError(@"Error getting file attributes for: %@: %@", filePath, [error localizedDescription]);
        }
        else
        {
            NSNumber *fileSizeNum = [attributes objectForKey:NSFileSize];
            fileSize = [fileSizeNum unsignedLongLongValue];
        }
    }
    
    if (fileSize > maximumSize)
    {
        [AlertController showAlertWithTitle:nil
                                    message:NSLocalizedString(@"1107-TextThisFileTooBig", nil)
                                buttonTitle:nil
                          cancelButtonTitle:NSLocalizedString(@"1-ButtonOK", nil)
                                 completion:NULL];
    }
    else
    {
        if (![attachment isUploadedToServer])
            attachment.status = AttachmentStatusToBeUploaded;
        
        [self.attachmentsList removeAllObjects];
        [self.attachmentsList addObject:attachment];
        
        [self showAttachment:attachment];
    }
}

- (void)cleanAttachmentsArray
{
    for (MessageAttachment * attachment in self.attachmentsList)
    {
        [attachment removeAssociatedData];
    }
    
    [self.attachmentsList removeAllObjects];
}

#pragma mark * AttachmentDocument

- (void)openQliqMediaLibrary
{
    MediaGroupsListViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([MediaGroupsListViewController class])];
    controller.delegate = self;
    controller.isGetMediaForConversation = YES;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    [self.parentViewController.navigationController presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark * AttachmentAudio

- (void)openAudioRecorder
{
    RecordAudioViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([RecordAudioViewController class])];
    controller.delegate = self;
    controller.isShowShareButton = NO;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    [self.parentViewController.navigationController presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark * AttachmentPictures AttachmentPhoto AttachmentVideo

- (MessageAttachment *)attachmentFromImage:(UIImage *)image scale:(CGFloat)scale{
    
    __block NSDate * date = [NSDate date];
    
    MessageAttachment * attachment = [[MessageAttachment alloc] initWithImage:image scale:scale saved:^{
        DDLogInfo(@"Image saved for %g",-[date timeIntervalSinceNow]);
        date = [NSDate date];
    } encrypted:^{
        DDLogInfo(@"Image encrypted for %g",-[date timeIntervalSinceNow]);
    }];
    
    return attachment;
}


#pragma mark - Actions -

- (IBAction)onSend:(id)sender
{
    __block __weak typeof(self) weakSelf = self;
    [weakSelf hiddenAttachmentView:NO];
    
    if ([weakSelf.delegate respondsToSelector:@selector(keyboardInputAccessoryViewSendPressed:)])
        [weakSelf.delegate keyboardInputAccessoryViewSendPressed:weakSelf];
}

- (IBAction)onAttachment:(id)sender
{
    [self hiddenAttachmentView:self.selectAttachmentView.hidden];
    [self setSizeForViews];
}

- (IBAction)onQuickMessage:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(keyboardInputAccessoryViewQuickMessagePressed:)])
        [self.delegate keyboardInputAccessoryViewQuickMessagePressed:self];
}

- (IBAction)onFlag:(id)sender
{
    if (self.flagsScrollView.contentOffset.y == 0)
    {
        [self.flagsScrollView setContentOffset:CGPointMake(self.flagsScrollView.contentOffset.x, self.flagsScrollView.frame.size.height) animated:YES];
        [self.flagsButton setBackgroundColor:RGBa(0., 120., 174., 1.)];
        [self.flagsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    else
    {
        [self.flagsScrollView setContentOffset:CGPointMake(self.flagsScrollView.contentOffset.x, 0.f) animated:YES];
        [self.flagsButton setBackgroundColor:[UIColor whiteColor]];
        [self.flagsButton setTitleColor:RGBa(0., 120., 174., 1.) forState:UIControlStateNormal];
    }
}

- (IBAction)onRequestAck:(id)sender {
    self.isRequestAck = !self.isRequestAck;
}

- (IBAction)onFYI:(id)sender
{
    if (self.messagePriority == ChatMessagePriorityForYourInformation)
        self.messagePriority = ChatMessagePriorityNormal;
    else
        self.messagePriority = ChatMessagePriorityForYourInformation;
}

- (IBAction)onASAP:(id)sender
{
    if (self.messagePriority == ChatMessagePriorityAsSoonAsPossible)
        self.messagePriority = ChatMessagePriorityNormal;
    else
        self.messagePriority = ChatMessagePriorityAsSoonAsPossible;
}

- (IBAction)onUrgent:(id)sender
{
    if (self.messagePriority == ChatMessagePriorityUrgen)
        self.messagePriority = ChatMessagePriorityNormal;
    else
        self.messagePriority = ChatMessagePriorityUrgen;
}

- (void)showCameraRollBlockedAlert {
    
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                                 message:QliqLocalizedString(@"2361-TextCameraRollBlocked")
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:QliqLocalizedString(@"4-ButtonCancel")
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];
        [alertController addAction:cancelAction];
        [self.navigationController presentViewController:alertController animated:YES completion:nil];
}


- (IBAction)onAddDocument:(id)sender {
    [self onAddAttachment:@"MediaLibrary"];
    
    [self openQliqMediaLibrary];
}
- (IBAction)onAddPicture:(id)sender {
    [self onAddAttachment:@"PhotoLibrary"];
    
    BOOL isCameraRollBlocked = [UserSessionService currentUserSession].userSettings.securitySettings.blockCameraRoll;
    if (isCameraRollBlocked) {
        [self showCameraRollBlockedAlert];
    } else {
        __block __weak typeof(self) weakSelf = self;
        [QliqHelper getPickerForMode:PickerModeLibrary forViewController:self returnPicker:^(id picker, NSError *error) {
            if (error) {
                [AlertController showAlertWithTitle:nil
                                            message:[error.userInfo valueForKey:@"NSLocalizedDescription"]
                                        buttonTitle:nil
                                  cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                         completion:NULL];
            } else if (picker) {
                dispatch_async_main(^{
                    [weakSelf.parentViewController.navigationController presentViewController:picker animated:YES completion:nil];
                });
            }
        }];
    }
    
}
- (IBAction)onMakePhoto:(id)sender {
    [self onAddAttachment:@"Photo"];
    
    __block __weak typeof(self) weakSelf = self;
    [QliqHelper getPickerForMode:PickerModePhotoAndVideo forViewController:self returnPicker:^(id picker, NSError *error) {
        if (error) {
            [AlertController showAlertWithTitle:nil
                                        message:[error.userInfo valueForKey:@"NSLocalizedDescription"]
                                    buttonTitle:nil
                              cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                     completion:NULL];
        } else if (picker) {
            dispatch_async_main(^{
                [weakSelf.parentViewController.navigationController presentViewController:picker animated:YES completion:nil];
            });
        }
    }];
}
- (IBAction)onMakeRecord:(id)sender {
    [self onAddAttachment:@"Record"];
    [self openAudioRecorder];
    
}
- (IBAction)onMakeVideo:(id)sender {
    [self onAddAttachment:@"Video"];
    
    __block __weak typeof(self) weakSelf = self;
    [QliqHelper getPickerForMode:PickerModeVideo forViewController:self returnPicker:^(id picker, NSError *error) {
        if (error) {
            [AlertController showAlertWithTitle:nil
                                        message:[error.userInfo valueForKey:@"NSLocalizedDescription"]
                                    buttonTitle:nil
                              cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                     completion:NULL];
        } else if (picker) {
            dispatch_async_main(^{
                [weakSelf.parentViewController.navigationController presentViewController:picker animated:YES completion:nil];
            });
        }
    }];
}

- (void)onAddAttachment:(NSString *)type {
    DDLogSupport(@"Pressed attachment type %@", type);
    
    [self.view endEditing:YES];
    
    [self hiddenAttachmentView:NO];
}

#pragma mark - Delgates -

#pragma mark * HPGrowingTextView Delegate

- (BOOL)growingTextViewShouldBeginEditing:(HPGrowingTextView *)growingTextView {
    return YES;
}


- (void)growingTextViewDidChange:(HPGrowingTextView *)growingTextView
{
    self.placeholderLabel.hidden = [growingTextView.internalTextView hasText];
    if (self.isPagerUserConversation)
    {
        NSString *text = growingTextView.internalTextView.text;
        if (text.length > kValueDefaultCharactersLeft) {
            growingTextView.internalTextView.text = [text substringWithRange:NSMakeRange(0, kValueDefaultCharactersLeft)];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(showAlert:withBlock:)]) {
                
                UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:nil
                                                                              message:QliqFormatLocalizedString1(@"2371-TextYouCannotEnterMoreCharactersThan{count}", kValueDefaultCharactersLeft)
                                                                             delegate:nil
                                                                    cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                                                    otherButtonTitles:nil];
                
                [self.delegate showAlert:alert withBlock:nil];
            }
        }
        
        [self setCharactersLeftLabelText:growingTextView.internalTextView.text];
    }
}

- (void)growingTextViewDidBeginEditing:(HPGrowingTextView *)growingTextView
{    
    [self getMaxHeightForTextView];
    
    CGRect frame = [self.textView.internalTextView getFrameToScrollToTop:NO];
    [self.textView.internalTextView scrollRectToVisible:frame animated:self.textView.internalTextView.scrollEnabled];
}

- (void)growingTextViewDidEndEditing:(HPGrowingTextView *)growingTextView
{
    self.textView.internalTextView.contentOffset = CGPointZero;
    
    self.textViewWillResignFirstResponder = YES;
    [self getMaxHeightForTextView];
    self.textViewWillResignFirstResponder = NO;
    
    CGRect frame = [self.textView.internalTextView getFrameToScrollToTop:YES];
    [self.textView.internalTextView scrollRectToVisible:frame animated:self.textView.internalTextView.scrollEnabled];
}

- (void)setTextViewHeight:(CGFloat)textViewHeight withKAVHeight:(CGFloat)kavHeight
{
    self.textViewHeightConstraint.constant = textViewHeight;
    
    CGFloat tableViewBottom = 0.f;
    
    CGFloat textViewWithFlagViewHeight = textViewHeight + kValueFlagViewHeight;
    
    if (!self.selectAttachmentView.hidden)
    {
        
        CGFloat selectAttachmentViewHeight = self.attachHeightConstraint.constant + self.attachViewBotConstraint.constant;
        if(self.shouldShowFlagView || !self.flagView.hidden)
        {
            if (selectAttachmentViewHeight > textViewWithFlagViewHeight)
            {
                tableViewBottom = selectAttachmentViewHeight - textViewWithFlagViewHeight;
            }
        }
        else
        {
            if (selectAttachmentViewHeight > textViewHeight)
            {
                tableViewBottom = selectAttachmentViewHeight - textViewHeight;
            }
        }
    }
    
    
    if ([self.delegate respondsToSelector:@selector(changeBottomTableview:)])
        [self.delegate changeBottomTableview:tableViewBottom];
}

- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height
{
    
    if ((self.isMessageSent && self.resize) || !self.isMessageSent)
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(getMaxHeightForKeyboardAccessoryView)])
        {
            CGFloat maxKAVHeight = [self.delegate getMaxHeightForKeyboardAccessoryView];
            CGFloat minKAVHeight = [self getMinimumHeightForKeyboardAccessoryView];
            
            if (minKAVHeight > maxKAVHeight)
            {
                DDLogSupport(@"minKAVHeight > maxKAVHeight - Try to enable singleField mode");
                if (self.delegate && [self.delegate respondsToSelector:@selector(turnOnSingleFieldMode:)])
                {
                    BOOL success = [self.delegate turnOnSingleFieldMode:YES];
                    if (success){
                        DDLogSupport(@"SingleField mode is enabled. Do not layoutKAV ");
                        return;
                    }
                }
            }
            else if ([self isSingleFieldMode])
            {
                DDLogSupport(@"minKAVHeight <= maxKAVHeight - Try to disable singleField mode");
                if (self.delegate && [self.delegate respondsToSelector:@selector(turnOnSingleFieldMode:)])
                    [self.delegate turnOnSingleFieldMode:NO];
            }
            
            CGFloat newTextViewHeight = 0.f;
            CGFloat textViewContentHeight = height + self.internalTextViewBottomConstraint.constant + self.internalTextViewTopConstraint.constant;
            CGFloat flagViewHeight = [self needToShowFlagView] ? kValueFlagViewHeight : 0;
            CGFloat maxHeightForTextView = [self maxHeightForTextViewWithMaxKAVHeight:maxKAVHeight andFlagViewHeight:flagViewHeight];
            CGFloat minHeightForTextView = [self minHeightForTextView];
            
            //constrain TextViewHeight with top and bottom bounds
            newTextViewHeight = textViewContentHeight < minHeightForTextView ? minHeightForTextView : textViewContentHeight;
            newTextViewHeight = newTextViewHeight > maxHeightForTextView ? maxHeightForTextView : newTextViewHeight;
            
            //Calculate height of Keyboard Accessory View with textview height and flagView height
            CGFloat suggestedKAVHeight = newTextViewHeight + flagViewHeight;
            
            //Check if min height, needed for selectAttachmetView, is not bigger than calculated KeyboardAccessoryViewHeight
            CGFloat newKAVHeight = self.selectAttachmentView.hidden ? suggestedKAVHeight : MAX(suggestedKAVHeight, minKAVHeight);
            CGFloat oldKAVHeight = self.view.frame.size.height;
            
            __weak __block typeof(self) welf = self;
            VoidBlock sentMessageBlock = ^{
                if (welf.isMessageSent)
                {
                    welf.isMessageSent = NO;
                    welf.resize = NO;
                    if (welf.heightChangeCompletion)
                    {
                        welf.heightChangeCompletion();
                        welf.heightChangeCompletion = nil;
                    }
                }
            };
            
            if (oldKAVHeight != newKAVHeight || self.flagOrPagerOnlyViewAppearing)
            {
                if (self.flagOrPagerOnlyViewAppearing)
                {
                    if ([self.delegate respondsToSelector:@selector(changeHeightAccessoryViewTo:)])
                        [self.delegate changeHeightAccessoryViewTo:newKAVHeight];
                    
                    [self setTextViewHeight:newTextViewHeight withKAVHeight:newKAVHeight];
                    sentMessageBlock();
                }
                else
                {
                    [UIView animateWithDuration:0.25 delay:0.0 options:nil  animations:^{
                        if ([welf.delegate respondsToSelector:@selector(changeHeightAccessoryViewTo:)])
                            [welf.delegate changeHeightAccessoryViewTo:newKAVHeight];
                        
                        [welf setTextViewHeight:newTextViewHeight withKAVHeight:newKAVHeight];
                        [welf.view.superview layoutSubviews];
                        
                    } completion:^(BOOL finished) {
                        if (welf.delegate && [welf.delegate respondsToSelector:@selector(scrollUpChatTableDown:offset:isSentMessage:animated:)])
                        {
                            if (oldKAVHeight < newKAVHeight)
                                [welf.delegate scrollUpChatTableDown:YES offset:(newKAVHeight - oldKAVHeight) isSentMessage:welf.isMessageSent animated:YES];
                            else if (oldKAVHeight > newKAVHeight)
                                [welf.delegate scrollUpChatTableDown:NO offset:(oldKAVHeight - newKAVHeight) isSentMessage:welf.isMessageSent animated:YES];
                        }
                        sentMessageBlock();
                    }];
                }
            }
            else
            {
                sentMessageBlock();
            }
            //        }
        }
    }
    else
    {
        self.resize = YES;
    }
}

- (void)growingTextView:(HPGrowingTextView *)growingTextView willDeleteAttachment:(UIView *)attachment
{
    [self cleanAttachmentsArray];
}

#pragma mark * ImagePickerController Delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    DDLogSupport(@"didFinishPickingMediaWithInfo");
    
    __block __weak typeof(self) weakSelf = self;
    
    CFStringRef type = (__bridge CFStringRef)[info objectForKey:UIImagePickerControllerMediaType];
    
    if (UTTypeEqual(type, kUTTypeImage)) {
        
        UIImage *pickedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        
        [self chooseQualityForImage:pickedImage attachment:YES withCompletitionBlock:^(ImageQuality quality) {
            
            [SVProgressHUD showWithStatus:NSLocalizedString(@"1911-StatusProcessingImage", nil)];
            __block __weak typeof(weakSelf) strongSelf = weakSelf;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                
                CGFloat scale = [[QliqAvatar sharedInstance] scaleForQuality:quality];
                
                MessageAttachment *attachment = [strongSelf attachmentFromImage:pickedImage scale:scale];
                
                dispatch_async_main(^{
                    [SVProgressHUD dismiss];
                    [strongSelf addAttachment:attachment];
                });
            });
        }];
    }
    else
    {
        
        [self.navigationController dismissViewControllerAnimated:YES completion:^{
            /*
             For fixing of ConversationViewController bounds breaking
             */
            weakSelf.navigationController.view.frame = [[UIScreen mainScreen] bounds];
            [weakSelf.navigationController.view layoutIfNeeded];
        }];
        
        [[QliqAvatar sharedInstance] convertVideo:info[UIImagePickerControllerMediaURL] usingBlock:^(NSURL *convertedVideoUrl, BOOL completed, RemoveBlock block) {
            
            if (completed) {
                MessageAttachment *attachment = [[MessageAttachment alloc] initWithVideoAtURL:convertedVideoUrl];
                [weakSelf addAttachment:attachment];
            }
            block();
        }];
    }
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
    
    [AlertController showActionSheetAlertWithTitle:NSLocalizedString(@"1168-TextChooseImageQuality", nil)
                                           message:nil
                                  withTitleButtons:@[smallTitle, mediumTitle, largeTitle, originalTitle]
                                 cancelButtonTitle:NSLocalizedString(@"4-ButtonCancel", nil)
                                      inController:self
                                        completion:^(NSUInteger buttonIndex) {
                                            if (buttonIndex != 4) {
                                                if (completeBlock) {
                                                    completeBlock(buttonIndex);
                                                }
                                            }
                                        }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    
    __block __weak typeof(self) weakSelf = self;
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        /*
         For fixing of ConversationViewController bounds breaking
         */
        weakSelf.navigationController.view.frame = [[UIScreen mainScreen] bounds];
        [weakSelf.navigationController.view layoutIfNeeded];
        
    }];
}

#pragma mark * MediaGroupsListViewController Delegate

- (void)mediaGroupsListViewController:(MediaGroupsListViewController *)controller didSelectMediaFile:(MediaFile *)mediaFile
{
    MessageAttachment * attachment = [[MessageAttachment alloc] initWithMediaFile:mediaFile];
    [self addAttachment:attachment];
}

#pragma mark * RecordAudioViewController Delegate

- (void)recordAudioController:(RecordAudioViewController *)recordVC didRecordedMedaFile:(MediaFile *)mediaFile
{
    MessageAttachment *attachment = [[MessageAttachment alloc] initWithMediaFile:mediaFile];
    attachment.status = AttachmentStatusNotInDB;
    [self addAttachment:attachment];
}

#pragma mark * GestureRecognizer

- (void)tapAction:(UITapGestureRecognizer *)sender {
    
    AttachmentView *attachmentView = (AttachmentView *)sender.view;
    if (attachmentView && attachmentView.attachment) {
        if ([self.delegate respondsToSelector:@selector(keyboardInputAccessoryView:didPressAttachment:)]) {
            [self.delegate keyboardInputAccessoryView:self didPressAttachment:attachmentView.attachment];
        }
    } else {
        [AlertController showAlertWithTitle:nil
                                    message:QliqLocalizedString(@"1024-TextFileIncorrect")
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                 completion:nil];
    }
}

@end
