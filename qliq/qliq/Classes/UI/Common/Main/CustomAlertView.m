//
//  CustomalertView.m
//  qliq
//
//  Created by Valerii Lider on 5/17/16.
//
//

#import "CustomAlertView.h"
#import "JCPadButton.h"

#define animationLength 0.3
#define MAX_alertContentHeightLandscape 320.0


typedef void(^ActionBlock)(NSInteger buttonIndex, NSString *textFieldText);

@interface CustomAlertView () <UITextFieldDelegate>

@property (assign, nonatomic) CGRect selfViewFrame;
@property (assign, nonatomic) CGFloat keyboardOffset;
@property (assign, nonatomic) CGFloat alertContentHeight;
@property (assign, nonatomic) CGFloat alertContentWidth;
@property (assign, nonatomic) CGFloat alertHeightDelta;
@property (assign, nonatomic) CGFloat buttonsBorderWidth;
@property (assign, nonatomic) CGFloat buttonsHeight;
@property (assign, nonatomic) CGFloat spaceBeetweenElements;
@property (assign, nonatomic) CGFloat spaceBeetweenMsgScrollViewAndTextField;
@property (assign, nonatomic) CGFloat dialPadHeight;
@property (assign, nonatomic) CGFloat dialPadYPoint;
@property (assign, nonatomic) CGFloat dialPadDelta;


@property (strong, nonatomic) UIScrollView *alertView;
@property (strong, nonatomic) UIScrollView *msgScrollView;
@property (strong, nonatomic) UILabel *msgLabel;
@property (strong, nonatomic) UILabel *titleLable;
@property (strong, nonatomic) UITextField *textField;
@property (strong, nonatomic) UIButton *backSpaceButton;
@property (strong, nonatomic) UIButton *cancelButton;
@property (strong, nonatomic) UIButton *requestButton;
@property (strong, nonatomic) NSMutableArray *otherButtons;
@property (strong, nonatomic) UIImageView *phonePadImageView;


@property (assign, nonatomic) CGFloat cancelButtonYPoint;
@property (assign, nonatomic) CGFloat requestButtonYPoint;
@property (assign, nonatomic) CGFloat otherButtonYPoint;
@property (assign, nonatomic) CGFloat phonePadImageViewYPoint;


@property (assign, nonatomic) BOOL isKeyboardShown;

@property (strong, nonatomic) NSArray *dialPadButtons;

@property (strong, nonatomic) UIView *dialPadView;

@property (strong, nonatomic) ActionBlock actionBlock;

@property (nonatomic, strong) UITapGestureRecognizer *gestureRecognizerDialPadHide;

@end

@implementation CustomAlertView

#pragma mark - Life Cycle -

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.textField removeObserver:self forKeyPath:@"text"];

    self.dialPadButtons = nil;
    self.dialPadView = nil;
    self.actionBlock = nil;
    [self removeGestureRecognizer:self.gestureRecognizerDialPadHide];
    self.gestureRecognizerDialPadHide = nil;
    self.alertView = nil;
    self.msgScrollView = nil;
    self.msgLabel = nil;
    self.titleLable = nil;
    self.textField = nil;
    self.backSpaceButton = nil;
    self.cancelButton = nil;
    self.requestButton = nil;
    self.requestButton = nil;
    self.alertView = nil;
}

- (instancetype)initWithTitle:(NSString *)title
                      message:(NSString *)message
                     delegate:(id)alertDelegate
                    needTextField:(BOOL)needTextField
           requestButtonTitles:(NSArray *)otherButtonTitles
{
    CGRect frame;
    
    frame = CGRectMake(0.0, 0.0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
    
    self = [super initWithFrame:frame];
    
    if (self) {
        
        self.selfViewFrame = self.frame;
        self.delegate = alertDelegate;
        
        [self addNotifications];
        
        self.isKeyboardShown = NO;
        self.alpha = 0.0;
        self.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.4];
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.autoresizesSubviews = YES;
        
        self.gestureRecognizerDialPadHide = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hidePhonePad:)];
        self.gestureRecognizerDialPadHide.numberOfTapsRequired = 1;
        
        self.alertContentWidth = 260;
        self.alertContentHeight = 20.0;
        self.buttonsBorderWidth = 0.5f;
        self.buttonsHeight = 50.0;
        self.spaceBeetweenElements = 15.0;
        self.spaceBeetweenMsgScrollViewAndTextField = 5.0;
       
        self.alertHeightDelta = 0;
        self.dialPadHeight = 0;
        self.dialPadYPoint = 0;
        self.dialPadDelta = 0;
        self.cancelButtonYPoint = 0;
        self.requestButtonYPoint = 0;
        self.otherButtonYPoint = 0;
        self.phonePadImageViewYPoint = 0;
        
        [self initOnlyCancelButtonWithTitle];
        
        //add text
        if (title)
            [self initTitleWith:title];
        else
            self.alertContentHeight += self.spaceBeetweenElements;
        if (message)
            [self initMessageScrollViewWith:message isButtons:([otherButtonTitles count] > 1)];
        else
            self.alertContentHeight += self.spaceBeetweenElements;
        
        //add Text Field
        if (needTextField)
        {
            [self setupTextField];
            //add DialPad
            [self initDialPad];
        }
        else
            self.alertContentHeight += self.spaceBeetweenElements;
       
        //add buttons
        if ([otherButtonTitles count] == 1)
        {
            [self initOnlyRequestButtonWithTitle:otherButtonTitles.firstObject];
        }
        else if ([otherButtonTitles count] > 1)
        {
            [self initOtherButtonsWithTitles:otherButtonTitles];
        }
        else
            self.alertContentHeight += self.spaceBeetweenElements;
        
        //add background
        CGRect alertViewFrame;
        
        self.alertView = [[UIScrollView alloc] init];
        
        if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
            
            alertViewFrame = CGRectMake((int)((self.selfViewFrame.size.width - self.alertContentWidth) / 2.0),
                                        (int)((self.selfViewFrame.size.height - self.alertContentHeight) / 2.0),
                                        self.alertContentWidth,
                                        self.alertContentHeight);
            self.alertView.frame = alertViewFrame;
            self.alertView.scrollEnabled = NO;
            
        } else if(UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            
            if (self.dialPadView) {
               
                alertViewFrame = CGRectMake((int)((self.selfViewFrame.size.width - self.alertContentWidth) / 2.0),
                                            5,
                                            self.alertContentWidth,
                                            self.selfViewFrame.size.height - 10);
            
                self.alertView.scrollEnabled = YES;
            } else {
            
                alertViewFrame = CGRectMake((int)((self.selfViewFrame.size.width - self.alertContentWidth) / 2.0),
                                            (int)((self.selfViewFrame.size.height - self.alertContentHeight) / 2.0),
                                            self.alertContentWidth,
                                            self.alertContentHeight);
                self.alertView.scrollEnabled = NO;
            
            }
            
            self.alertView.frame = alertViewFrame;
            
        }
        
        self.alertView.contentSize = CGSizeMake(self.alertContentWidth, self.alertContentHeight);
        self.alertView.contentOffset = CGPointMake(0, 0);
        self.alertView.bounces = NO;
        
        self.alertView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        
        if (self.cancelButton)
        {
            [self.alertView addSubview:self.cancelButton];
        }
        
        if (self.titleLable)
        {
            [self.alertView addSubview:self.titleLable];
        }
        if (self.msgScrollView)
        {
            [self.alertView addSubview:self.msgScrollView];
        }
        
        if (self.textField) {
            [self.alertView addSubview:self.textField];
            [self.alertView addSubview:self.backSpaceButton];
            [self.alertView bringSubviewToFront:self.backSpaceButton];
           
            if (self.dialPadView) {
                [self.alertView addSubview:self.dialPadView];
            }
        }
       
        if ([otherButtonTitles count] == 1) {
            if (self.requestButton)
            {
                [self.alertView addSubview:self.requestButton];
                [self.alertView addSubview:self.phonePadImageView];
            }

        } else if ([otherButtonTitles count] > 1) {
            for (UIButton *button in self.otherButtons) {
                [self.alertView addSubview:button];
            }
        }
        
        self.alertView.alpha = 0.95;
        self.alertView.layer.cornerRadius = 8.0;
        self.alertView.backgroundColor = [UIColor groupTableViewBackgroundColor];
        self.alertView.clipsToBounds = YES;
        
        [self addSubview:self.alertView];
        
        if (self.dialPadView) {
            self.dialPadDelta = self.dialPadHeight + self.spaceBeetweenElements;
            self.dialPadView.hidden = NO;
        }
        self.alertHeightDelta = self.alertContentHeight - self.dialPadDelta;
    }
    return self;
}

#pragma mark - Init Elements -

- (void)initTitleWith:(NSString *)title {
    UILabel *titleLbl;
    
    titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(10.0, self.alertContentHeight, self.alertContentWidth-20.0, 30.0)];
    titleLbl.numberOfLines = 0;
    titleLbl.lineBreakMode = NSLineBreakByWordWrapping;
    titleLbl.textAlignment = NSTextAlignmentCenter;
    titleLbl.adjustsFontSizeToFitWidth = YES;
    titleLbl.font = [UIFont boldSystemFontOfSize:18.0];
    titleLbl.minimumScaleFactor = 10.f / titleLbl.font.pointSize;
    titleLbl.backgroundColor = [UIColor clearColor];
    titleLbl.textColor = [UIColor blackColor];
    titleLbl.text = title;
    
    [titleLbl sizeToFit];
    
    titleLbl.frame = CGRectMake(10.0, self.alertContentHeight, self.alertContentWidth-20.0, titleLbl.frame.size.height);
    
    self.alertContentHeight += titleLbl.frame.size.height + self.spaceBeetweenElements;
    
    self.titleLable = titleLbl;
}

- (void)initMessageScrollViewWith:(NSString *)message isButtons:(BOOL)isButtons {
    
    UIScrollView *msgScrollView;
    float max_msg_height = MAX_alertContentHeightLandscape - self.alertContentHeight - (self.buttonsHeight + self.spaceBeetweenElements);
    
    UILabel *messageLbl = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, self.alertContentWidth - 20.0, 0.0)];
    messageLbl.numberOfLines = 0;
    messageLbl.lineBreakMode = NSLineBreakByWordWrapping;
    messageLbl.font = [UIFont systemFontOfSize:16.0];
    
    if (isButtons) {
        messageLbl.textAlignment = NSTextAlignmentCenter;

    } else {
        messageLbl.textAlignment = NSTextAlignmentLeft;
    }
    
    messageLbl.backgroundColor = [UIColor clearColor];
    messageLbl.textColor = [UIColor blackColor];
    messageLbl.text = message;
    [messageLbl sizeToFit];
    
    messageLbl.frame = CGRectMake(0.0, 0.0, self.alertContentWidth-20.0, messageLbl.frame.size.height);
    
    while (messageLbl.frame.size.height > max_msg_height && messageLbl.font.pointSize > 12.0) {
        messageLbl.font = [UIFont systemFontOfSize:messageLbl.font.pointSize-1];
        [messageLbl sizeToFit];
        messageLbl.frame = CGRectMake(0.0, 0.0, self.alertContentWidth-20.0, messageLbl.frame.size.height);
    }
    
    msgScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(10.0,
                                                                   self.alertContentHeight,
                                                                   self.alertContentWidth - 20.0,
                                                                   (messageLbl.frame.size.height > max_msg_height) ? max_msg_height : messageLbl.frame.size.height)];
    msgScrollView.contentSize = messageLbl.frame.size;
    self.msgLabel = messageLbl;
    [msgScrollView addSubview:messageLbl];
    self.alertContentHeight += msgScrollView.frame.size.height + self.spaceBeetweenMsgScrollViewAndTextField;
    self.msgScrollView = msgScrollView;
    
}

- (void)setupTextField {
    
    
    // TextField
    self.textField = [[UITextField alloc] init];
    self.textField.borderStyle = UITextBorderStyleNone;
    self.textField.textAlignment = NSTextAlignmentCenter;
    self.textField.backgroundColor = [UIColor whiteColor];
    self.textField.clearButtonMode = UITextFieldViewModeNever;
    self.textField.keyboardType = UIKeyboardTypePhonePad;
    self.textField.userInteractionEnabled = YES;
    self.textField.delegate = self;
    self.textField.placeholder = QliqLocalizedString(@"1950-TextPlaceholderExYourMobileNumber");
    
    if ([UserSessionService currentUserSession].userSettings.usersCallbackNumber.length != 0)
    {
        self.textField.text = [UserSessionService currentUserSession].userSettings.usersCallbackNumber;
    } else {
        if ([UserSessionService currentUserSession].user.mobile.length != 0) {
            self.textField.text = [UserSessionService currentUserSession].user.mobile;
        } else {
            self.textField.text = nil;
        }
    }
    
    [self.textField addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];

    self.textField.frame = CGRectMake(20.0, self.alertContentHeight, self.alertContentWidth - 40, 25);
    self.alertContentHeight += self.textField.frame.size.height + self.spaceBeetweenElements;

    
    
    //BackSpace button
    CGFloat backSpaceButtonHeight = 15;
    CGFloat backSpaceButtonWidth = 20;
    
    self.backSpaceButton = [[UIButton alloc] initWithFrame:CGRectMake(self.textField.frame.size.width + 20 - backSpaceButtonWidth - 3,
                                                                      self.textField.frame.origin.y + (self.textField.frame.size.height - backSpaceButtonHeight) / 2.0,
                                                                      backSpaceButtonWidth,
                                                                      backSpaceButtonHeight)];
    [self.backSpaceButton setTag:1003];
    
    [self.backSpaceButton setBackgroundImage:[UIImage imageNamed:@"backspace_default_blue.png" ] forState:UIControlStateNormal];
    [self.backSpaceButton setBackgroundImage:[UIImage imageNamed:@"backspace_default_blue_light.png"] forState:UIControlStateHighlighted];
    
    [self.backSpaceButton setBackgroundColor:[UIColor whiteColor]];
    
    [self.backSpaceButton addTarget:self action:@selector(onBackSpaceButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
}

- (void)initDialPad {
    self.dialPadView = [[UIView alloc] initWithFrame:CGRectMake(20, self.alertContentHeight, self.alertContentWidth - 40, JCPadButtonHeight * 4 + 6)];
    self.dialPadView.backgroundColor = [UIColor clearColor];
    
    self.dialPadButtons  = [self defaultButtons];
    
    [self layoutButtons];
    
    self.dialPadHeight = self.dialPadView.frame.size.height;
    self.dialPadYPoint = self.dialPadView.frame.origin.y;
    self.alertContentHeight += self.dialPadView.frame.size.height + self.spaceBeetweenElements;
}

- (void)initOnlyCancelButtonWithTitle {
    UIButton *cancelBtn;
    
    {
        cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.alertContentWidth - 25,
                                                               5,
                                                               20,
                                                               20)];
        [cancelBtn setTag:1000];
        
        [cancelBtn setBackgroundImage:[UIImage imageNamed:@"Close_button_default_blue.png" ] forState:UIControlStateNormal];
        [cancelBtn setBackgroundImage:[UIImage imageNamed:@"Close_button_default_blue_light.png"] forState:UIControlStateHighlighted];
        
        [cancelBtn addTarget:self action:@selector(onBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        self.cancelButtonYPoint = cancelBtn.frame.origin.y;
        self.cancelButton = cancelBtn;
    }
    
}

- (void)initOtherButtonsWithTitles:(NSArray *)otherButtonTitles {
    
    self.otherButtons = [NSMutableArray new];
    
    NSInteger index = 1001;
    NSInteger buttonsCount = [otherButtonTitles count];
    CGFloat xPointForNextButton;
    CGFloat yPointForNextButton;
    CGFloat otherButtonHeight;
    CGFloat buttonWidth = self.alertContentWidth / buttonsCount + 2 * self.buttonsBorderWidth;
    
    xPointForNextButton = 0 - self.buttonsBorderWidth;
    yPointForNextButton = self.alertContentHeight + self.buttonsBorderWidth;
    
    for (NSString *title in otherButtonTitles) {
        
        UIButton *otherButton;
        CGRect buttonFrame;

        otherButton = [[UIButton alloc] init];
        
        [otherButton setTag:index];
        index++;

        otherButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        
        buttonFrame = CGRectMake(xPointForNextButton,
                                 yPointForNextButton,
                                buttonWidth,
                                 self.buttonsHeight);
        
        otherButton.frame = buttonFrame;
        
        xPointForNextButton = buttonFrame.origin.x + buttonWidth - self.buttonsBorderWidth;
        
        [self setupButton:otherButton withTitle:title];
        
        [self.otherButtons addObject:otherButton];
        
        self.requestButtonYPoint = otherButton.frame.origin.y;
        
        otherButtonHeight = otherButton.frame.size.height;
    }
    
    self.alertContentHeight += otherButtonHeight;
    
}

- (void)setupButton:(UIButton *)otherButton withTitle:(NSString *)title {
 
    [otherButton setTitle:title forState:UIControlStateNormal];
    [otherButton setTitle:title forState:UIControlStateDisabled];
    [otherButton.titleLabel setFont:[UIFont systemFontOfSize:18.0]];
    
    [otherButton setBackgroundColor:[UIColor clearColor]];
    
    [[otherButton layer] setBorderWidth:self.buttonsBorderWidth];
    [[otherButton layer] setBorderColor:[UIColor grayColor].CGColor];
    
    [otherButton setTitleColor:[UIColor colorWithRed:0.0 green:122.0 / 255.0 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    [otherButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    
    otherButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    [otherButton.titleLabel sizeToFit];
    
    otherButton.titleLabel.frame = CGRectMake(([otherButton.titleLabel superview].frame.size.width - otherButton.titleLabel.frame.size.width) / 2.0,
                                              otherButton.titleLabel.frame.origin.y,
                                              otherButton.titleLabel.frame.size.width,
                                              otherButton.titleLabel.frame.size.height);

    [otherButton addTarget:self action:@selector(onBtnPressed:) forControlEvents:UIControlEventTouchUpInside];

}

- (void)initOnlyRequestButtonWithTitle:(NSString *)requestButtonTitle {
    {
        self.requestButton = [[UIButton alloc] initWithFrame:CGRectMake(0 - self.buttonsBorderWidth,
                                                                   self.alertContentHeight + self.buttonsBorderWidth,
                                                                   self.alertContentWidth + (2 * self.buttonsBorderWidth),
                                                                   self.buttonsHeight)];
        [self.requestButton setTag:1001];
                
        self.requestButton.titleLabel.textAlignment = NSTextAlignmentLeft;
        
        [self setupButton:self.requestButton withTitle:requestButtonTitle];
        
        self.requestButtonYPoint = self.requestButton.frame.origin.y;
        
        self.phonePadImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.requestButton.frame.origin.x + 20.0,
                                                                               (self.requestButton.frame.origin.y + ((self.requestButton.frame.size.height - 22.0) / 2.0)),
                                                                               22.0,
                                                                               22.0)];
        self.phonePadImageViewYPoint = self.phonePadImageView.frame.origin.y;
        self.phonePadImageView.image = [UIImage imageNamed:@"DetailContactInfoPhone_lightGray.png"];
    
        [self checkForRequestEnabling:self.textField.text];
    }
    self.alertContentHeight += self.requestButton.frame.size.height;
}

#pragma mark - Dial Pad -

- (NSArray *)defaultButtons
{
    NSArray *mains = @[@"1", @"2",   @"3",   @"4",   @"5",   @"6",   @"7",    @"8",   @"9",    @"✳︎", @"0", @"＃"];
    NSArray *subs  = @[@"",  @"ABC", @"DEF", @"GHI", @"JKL", @"MNO", @"PQRS", @"TUV", @"WXYZ", @"",  @"+", @""];
    NSMutableArray *ret = [NSMutableArray array];
    
    [mains enumerateObjectsUsingBlock:^(NSString *main, NSUInteger idx, BOOL *stop) {
        
        JCPadButton *button = [[JCPadButton alloc] initWithMainLabel:main subLabel:subs[idx]];
        
        button.borderColor = [UIColor colorWithRed:0.0 green:122.0 / 255.0 blue:1.0 alpha:1.0];
        button.layer.borderWidth = 2.0f;
        button.textColor = nil;
        
        button.mainLabel.textColor = [UIColor blackColor];
        button.mainLabel.font = [UIFont systemFontOfSize:20.0];
        button.mainLabel.text = main;
        
        button.subLabel.textColor = [UIColor lightGrayColor];
        button.subLabel.font = [UIFont systemFontOfSize:10.0];
        button.subLabel.attributedText = nil;
        button.subLabel.text = subs[idx];
        
        if ([main isEqualToString:@"✳︎"]) {
            button.input = @"*";
            button.mainLabel.font = [UIFont systemFontOfSize:10.0];
        } else if ([main isEqualToString:@"＃"]) {
            button.input = @"#";
        } else if ([main isEqualToString:@"0"]) {
            button.longPressInput = @"+";
        }
        
        [ret addObject:button];
    }];
    
    return ret;
}

- (void)layoutButtons
{
    NSInteger count                       = self.dialPadButtons.count;
    const CGFloat horizontalButtonPadding = 30;
    CGFloat verticalButtonPadding         = 2;
    CGFloat topRowTop                     = 0;
    CGFloat cellWidth                     = JCPadButtonWidth + horizontalButtonPadding;
    CGFloat center                        = [self correctWidth] / 2.0;
    
    [self.dialPadButtons enumerateObjectsUsingBlock:^(JCPadButton *btn, NSUInteger idx, BOOL *stop) {
        NSInteger row = idx / 3;
        NSInteger btnsInRow = MIN(3, count - (row * 3));
        NSInteger col = idx % 3;
        
        CGFloat top = topRowTop + (row * (btn.height + verticalButtonPadding));
        CGFloat rowWidth = (btn.width * btnsInRow) + (horizontalButtonPadding * (btnsInRow - 1));
        
        CGFloat left = center - (rowWidth / 2.0) + (cellWidth * col);
        [self setUpButton:btn left:left top:top];
    }];
}

- (void)setUpButton:(UIButton *)button left:(CGFloat)left top:(CGFloat)top
{
    button.frame = CGRectMake(left, top, JCPadButtonWidth, JCPadButtonHeight);
    
    [button addTarget:self action:@selector(didTapPhoneButton:) forControlEvents:UIControlEventTouchUpInside];
    
    UIGestureRecognizer *rec = [[UILongPressGestureRecognizer alloc]
                                initWithTarget:self
                                action:@selector(didHoldPhoneButton:)];
    
    [button addGestureRecognizer:rec];
    
    button.clipsToBounds = YES;
    button.layer.cornerRadius = JCPadButtonHeight / 2.0 - 2;
    
    [self.dialPadView addSubview:button];
}

- (CGFloat)correctWidth
{
    return self.dialPadView.bounds.size.width;
}

- (CGFloat)correctHeight
{
    return self.dialPadView.bounds.size.height;
}

#pragma mark - Actions -

- (void)didTapPhoneButton:(UIButton *)sender
{
    if (self.textField.text.length == 0 && self.backSpaceButton.hidden) {
        self.backSpaceButton.hidden = NO;
    }
    
    if ([sender isKindOfClass:[JCPadButton class]]) {
        JCPadButton *button = (JCPadButton *)sender;
        
        NSString *enteredNumber = self.textField.text;
        self.textField.text = [enteredNumber stringByAppendingString:button.input];
    }
}

-(void)didHoldPhoneButton:(UILongPressGestureRecognizer *)recognizer
{
    
    if (self.textField.text.length == 0 && self.backSpaceButton.hidden) {
        self.backSpaceButton.hidden = NO;
    }
    
    if (recognizer.state != UIGestureRecognizerStateBegan)
        return;
    
    JCPadButton *button = (JCPadButton *)recognizer.view;
    
    NSString *enteredNumber = self.textField.text;
    self.textField.text = [enteredNumber stringByAppendingString:button.longPressInput];
    
}

- (void)onBackSpaceButtonPressed:(UIButton *)button {
    if (self.textField.text.length >= 1) {
        self.textField.text = [self.textField.text substringToIndex:self.textField.text.length - 1];
        if (self.textField.text.length == 0) {
            button.hidden = YES;
        }
    }
}

- (void)onBtnPressed:(id)sender
{
    UIButton *button = (UIButton *)sender;
    
    NSInteger buttonIndex = button.tag - 1000;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(customalertView:clickedButtonAtIndex:)])
        [self.delegate customAlertView:self clickedButtonAtIndex:buttonIndex];
    
    self.actionBlock(buttonIndex, self.textField.text);
    
    [self animateAlertHide];
}

#pragma mark - Appearance -

- (void)showInView:(UIView*)view withDismissBlock:(void(^)(NSInteger buttonIndex, NSString *textFieldText))block
{
    //layout Alert
    {
        if (!self.textField || self.textField.text.length == 0) {
            self.backSpaceButton.hidden = YES;
            self.dialPadView.hidden = YES;
            self.dialPadView.alpha = 0.0;
            
        } else {
            self.backSpaceButton.hidden = NO;
            self.dialPadView.hidden = NO;
            [self addGestureRecognizer:self.gestureRecognizerDialPadHide];
        }
        
         BOOL isDialPadHidden = self.dialPadView ? self.dialPadView.hidden : YES;
        
        if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
            
            [self layoutAlertForPortraitDialPadHidden:isDialPadHidden];
            
        } else if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)){
            
            [self layoutAlertForLandscapeDialPadHidden:isDialPadHidden];
        }
    }
    
    self.actionBlock = block;
    
    if ([view isKindOfClass:[UIView class]])
    {
        [view addSubview:self];
        [self animateAlertShow];
    }
}

- (void)animateAlertShow
{
    __weak __block typeof(self) welf = self;
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionShowHideTransitionViews animations:^{
        welf.alpha = 1.0;
    } completion:nil];
}

- (void)animateAlertHide
{
    __weak __block typeof(self) welf = self;
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionShowHideTransitionViews animations:^{
        welf.alpha = 0.0;
    } completion:^(BOOL finished) {
        [[NSNotificationCenter defaultCenter] removeObserver:welf];
        [welf performSelector:@selector(removeFromSuperview) withObject:welf afterDelay:0.105];
    }];
}

- (void)hidePhonePad:(UITapGestureRecognizer *)tap {
    
    if (!self.dialPadView.hidden) {
        __weak __block typeof(self) welf = self;
        [self animateLayoutWithPreAnimationBlock:^{
            welf.dialPadView.alpha = 0.0;
        }
                              mainAnimationBlock:^{
                                  if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
                                      
                                      [welf layoutAlertForPortraitDialPadHidden:YES];
                                      
                                  } else if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)){
                                      
                                      [welf layoutAlertForLandscapeDialPadHidden:YES];
                                  }
                                  
                              }
                        mainAnimationsCompletion:^(BOOL finished) {
                            
                            welf.dialPadView.hidden = YES;
                            
                        }
                          postMainAnimationBlock:nil
                                  lastCompletion:^(BOOL finished) {
                                      [welf removeGestureRecognizer:welf.gestureRecognizerDialPadHide];
                                  }];
    }
}

- (void)showPhonePad:(UITextField *)textField {
    
    if (self.dialPadView.hidden) {
        __weak __block typeof(self) welf = self;
        
        [self animateLayoutWithPreAnimationBlock:nil
                              mainAnimationBlock:^{
                                  
                                  if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
                                      [welf layoutAlertForPortraitDialPadHidden:NO];
                                  } else if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)){
                                      [welf layoutAlertForLandscapeDialPadHidden:NO];
                                  }
                                  
                              }
                        mainAnimationsCompletion:nil
                          postMainAnimationBlock:nil
                                  lastCompletion:^(BOOL finished) {
                                      
                                      [welf animateLayoutWithPreAnimationBlock:nil
                                                            mainAnimationBlock:^{
                                                                welf.dialPadView.alpha = 1.0;
                                                            }
                                                      mainAnimationsCompletion:nil
                                                        postMainAnimationBlock:nil
                                                                lastCompletion:^(BOOL finished) {
                                                                    welf.dialPadView.hidden = NO;
                                                                }];
                                      [welf addGestureRecognizer:welf.gestureRecognizerDialPadHide];
                                  }];
    }
}

#pragma mark * Alert Layout

- (void)layoutAlertWithAlertHeight:(CGFloat)alertHeight
                       alertYPoint:(CGFloat)alertYPoint
                     dialPadHeight:(CGFloat)dialPadHeight
               requestButtonYPoint:(CGFloat)requestButtonYPoint
           phonePadImageViewYPoint:(CGFloat)phonePadImageViewYPoint
                     scrollEnabled:(BOOL)scrollEnabled
                 dialPadViewHidden:(BOOL)dialPadViewHidden
{
    
    if (dialPadViewHidden) {
        self.alertView.contentSize = CGSizeMake(self.alertContentWidth, self.alertHeightDelta);
    } else {
        self.alertView.contentSize = CGSizeMake(self.alertContentWidth, self.alertContentHeight);
    }
    
    self.alertView.scrollEnabled = scrollEnabled;
    
    
    self.alertView.frame = CGRectMake(((self.selfViewFrame.size.width - self.alertContentWidth) / 2.0),
                                      alertYPoint,
                                      self.alertContentWidth,
                                      alertHeight);
    if (self.dialPadView) {
        
        self.dialPadView.frame = CGRectMake( self.dialPadView.frame.origin.x,
                                        self.dialPadYPoint,
                                        self.dialPadView.frame.size.width,
                                        dialPadHeight);
    
    }
    
    if (self.otherButtons) {
        
        for (UIButton *button in self.otherButtons) {
            button.frame = CGRectMake(button.frame.origin.x,
                                      requestButtonYPoint,
                                      button.frame.size.width,
                                      button.frame.size.height);
        }
        
    } else {
        
        self.requestButton.frame = CGRectMake(self.requestButton.frame.origin.x,
                                              requestButtonYPoint,
                                              self.requestButton.frame.size.width,
                                              self.requestButton.frame.size.height);
    
        self.phonePadImageView.frame = CGRectMake(self.phonePadImageView.frame.origin.x,
                                                  phonePadImageViewYPoint,
                                                  self.phonePadImageView.frame.size.width,
                                                  self.phonePadImageView.frame.size.height);
    }
    
    [[self superview] layoutSubviews];
}


- (void)layoutAlertForPortraitDialPadHidden:(BOOL)isDialPadHidden {
    
    if (isDialPadHidden) {
        [self layoutAlertWithAlertHeight:self.alertHeightDelta
                             alertYPoint:((self.selfViewFrame.size.height - self.alertHeightDelta) / 2.0)
                           dialPadHeight:0
                     requestButtonYPoint:self.requestButtonYPoint - self.dialPadDelta
                 phonePadImageViewYPoint:self.phonePadImageViewYPoint - self.dialPadDelta
                           scrollEnabled:NO
                       dialPadViewHidden:isDialPadHidden];
    } else {
        
        [self layoutAlertWithAlertHeight:self.alertContentHeight
                             alertYPoint:((self.selfViewFrame.size.height - self.alertContentHeight) / 2.0)
                           dialPadHeight:self.dialPadHeight
                     requestButtonYPoint:self.requestButtonYPoint
                 phonePadImageViewYPoint:self.phonePadImageViewYPoint
                           scrollEnabled:NO
                       dialPadViewHidden:isDialPadHidden];
    }
}

- (void)layoutAlertForLandscapeDialPadHidden:(BOOL)isDialPadHidden {
    
    
    if (isDialPadHidden) {
        
        [self layoutAlertWithAlertHeight:self.alertHeightDelta
                             alertYPoint:((self.selfViewFrame.size.height - self.alertHeightDelta) / 2.0)
                           dialPadHeight:0
                     requestButtonYPoint:self.requestButtonYPoint - self.dialPadDelta
                 phonePadImageViewYPoint:self.phonePadImageViewYPoint - self.dialPadDelta
                           scrollEnabled:YES
                       dialPadViewHidden:isDialPadHidden];
    } else {
        
        CGFloat alertMargin = 5;
        
        [self layoutAlertWithAlertHeight:(self.selfViewFrame.size.height - (2 * alertMargin))
                             alertYPoint:alertMargin
                           dialPadHeight:self.dialPadHeight
                     requestButtonYPoint:self.requestButtonYPoint
                 phonePadImageViewYPoint:self.phonePadImageViewYPoint
                           scrollEnabled:YES
                       dialPadViewHidden:isDialPadHidden];
    }
}


#pragma mark * Animation

- (void)animateLayoutWithPreAnimationBlock:(VoidBlock)preAnimations
                        mainAnimationBlock:(VoidBlock)mainAnimations
                  mainAnimationsCompletion:(void (^ __nullable)(BOOL finished))mainAnimationsCompletion
                    postMainAnimationBlock:(VoidBlock)postMainAnimations
                            lastCompletion:(void (^ __nullable)(BOOL finished))lastCompletion {
    
    NSTimeInterval duration = 0.4;
    
    [UIView animateKeyframesWithDuration:duration delay:0.0 options:UIViewKeyframeAnimationOptionAllowUserInteraction | UIViewKeyframeAnimationOptionLayoutSubviews | UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
        
        if (preAnimations) {
            preAnimations();
        }
        
        [UIView addKeyframeWithRelativeStartTime:0.25 relativeDuration:duration animations:^{
            [UIView animateWithDuration:duration delay:0.2 usingSpringWithDamping:1.0 initialSpringVelocity:1.0 options:0 animations:^{
                
                if (mainAnimations) {
                    mainAnimations();
                }
                
            } completion:^(BOOL finished) {
                if (mainAnimationsCompletion) {
                    mainAnimationsCompletion(finished);
                }
            }];
        }];
        
        if (postMainAnimations) {
            postMainAnimations();
        }
        
    } completion:^(BOOL finished) {
        
        if (lastCompletion) {
            lastCompletion(finished);
        }
    }];
}

#pragma mark - Public -

- (void)setRequestButtonEnabled:(BOOL)enabled {
    
    if (enabled) {
        self.phonePadImageView.image = [UIImage imageNamed:@"DetailContactInfoPhone.png"];
    } else {
        self.phonePadImageView.image = [UIImage imageNamed:@"DetailContactInfoPhone_lightGray.png"];
    }
    
    self.requestButton.enabled = enabled;
}

#pragma mark - KVO -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"text"]) {
        [self checkForRequestEnabling:change[@"new"]];
    }
}

- (void)checkForRequestEnabling:(NSString *)textFieldText {
    if (isValidPhone(textFieldText)) {
        [self setRequestButtonEnabled:YES];
    } else {
        [self setRequestButtonEnabled:NO];
    }
}

#pragma mark - Notifications -

- (void)addNotifications {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didRotate:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    
}

- (void) didRotate:(NSNotification *)notification
{
    __block CGRect selfViewframe;
    selfViewframe = CGRectMake(0.0, 0.0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
    
    BOOL isDialPadHidden = self.dialPadView ? self.dialPadView.hidden : YES;
    
    [self animateLayoutWithPreAnimationBlock:nil
                          mainAnimationBlock:^{
                              self.selfViewFrame = selfViewframe;
                              
                              if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
                                  
                                  [self layoutAlertForPortraitDialPadHidden:isDialPadHidden];
                                  
                              } else if(UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)){
                                  
                                  [self layoutAlertForLandscapeDialPadHidden:isDialPadHidden];
                                  
                              }
                          }
                    mainAnimationsCompletion:nil
                      postMainAnimationBlock:nil
                              lastCompletion:^(BOOL finished) {
                              }];
}

#pragma mark - TextField Delegate -

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    [self showPhonePad:nil];
    return NO;
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

@end

