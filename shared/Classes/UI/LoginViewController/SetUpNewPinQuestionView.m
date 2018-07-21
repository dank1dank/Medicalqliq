//
//  SetUpNewPinQuestionView.m
//  qliq
//
//  Created by Paul Bar on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SetUpNewPinQuestionView.h"
#import "StretchableButton.h"
#import "LightGreyGlassGradientView.h"

@interface SetUpNewPinQuestionView()

-(void) setUpNewPinButtonPressed;
-(void) laterButtonPressed;

@end

@implementation SetUpNewPinQuestionView
@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        self.backgroundColor = [UIColor colorWithRed:0.0 green:(65.0/255.0) blue:(106.0/255.0) alpha:1.0];
        
        quickLoginUsingPinLabel = [[UILabel alloc] init];
        quickLoginUsingPinLabel.backgroundColor = [UIColor clearColor];
        quickLoginUsingPinLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:16.0];
        quickLoginUsingPinLabel.numberOfLines = 2;
        quickLoginUsingPinLabel.text = @"Quickly log in to qliq by\nsetting a four-digit PIN.";
		quickLoginUsingPinLabel.accessibilityLabel=@"quickLoginUsingPinLabel";
        quickLoginUsingPinLabel.textAlignment = UITextAlignmentCenter;
        quickLoginUsingPinLabel.textColor = [UIColor whiteColor];
        [self addSubview:quickLoginUsingPinLabel];
        
        backToPasswordLabel = [[UILabel alloc] init];
        backToPasswordLabel.backgroundColor = [UIColor clearColor];
        backToPasswordLabel.font = [UIFont fontWithName:@"Helvetica" size:14.0];
        backToPasswordLabel.numberOfLines = 4;
        backToPasswordLabel.text = @"You can always log in with your\nemail and password by tapping the\n“Switch to Username & Password” \nbutton on the pin entry screen.";
        backToPasswordLabel.textAlignment = UITextAlignmentCenter;
        backToPasswordLabel.textColor = [UIColor whiteColor];
        [self addSubview:backToPasswordLabel];
        
		addPinInSettingsLabel = [[UILabel alloc] init];
        addPinInSettingsLabel.backgroundColor = [UIColor clearColor];
        addPinInSettingsLabel.font = [UIFont fontWithName:@"Helvetica" size:14.0];
        addPinInSettingsLabel.numberOfLines = 3;
        addPinInSettingsLabel.text = @"If you choose “Set PIN Later”, you\ncan add it in SETTINGS by clicking \nthe qliq logo in the top left corner.";
        addPinInSettingsLabel.textAlignment = UITextAlignmentCenter;
        addPinInSettingsLabel.textColor = [UIColor whiteColor];
        [self addSubview:addPinInSettingsLabel];
        
        buttonsBackground = [[LightGreyGlassGradientView alloc] init];
        [self addSubview:buttonsBackground];
        
        laterButton = [[StretchableButton alloc] init];
		laterButton.accessibilityLabel = @"Set PIN Later" ;
        [laterButton setTitle:@"Set PIN Later" forState:UIControlStateNormal];
        laterButton.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14.0];
        laterButton.titleLabel.textColor = [UIColor whiteColor];
        laterButton.btnType = StretchableButton25;
        [laterButton addTarget:self action:@selector(laterButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:laterButton];
        
        setUpPinButton = [[StretchableButton alloc] init];
		setUpPinButton.accessibilityLabel = @"Next";
        [setUpPinButton setTitle:@"Next" forState:UIControlStateNormal];
        setUpPinButton.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14.0];
        setUpPinButton.titleLabel.textColor = [UIColor whiteColor];
        setUpPinButton.btnType = StretchableButton25;
        [setUpPinButton addTarget:self action:@selector(setUpNewPinButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:setUpPinButton];
                             
    }
    return self;
}

- (void)setDelegate:(id<SetUpNewPinQuestionViewDelegate>)_delegate{
    delegate = _delegate;
    if ([delegate respondsToSelector:@selector(shouldEnforcePin)])
        laterButton.enabled = ![delegate shouldEnforcePin];
}

-(void) dealloc
{
    [quickLoginUsingPinLabel release];
	[addPinInSettingsLabel release];
    [backToPasswordLabel release];
    [buttonsBackground release];
    [laterButton release];
    [setUpPinButton release];
    [super dealloc];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(void) layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat yOffset = 40.0;
    //CGSize labelSize;
    
    //labelSize = [quickLoginUsingPinLabel.text sizeWithFont:quickLoginUsingPinLabel.font];
    
    quickLoginUsingPinLabel.frame = CGRectMake(0.0,
                                               yOffset,
                                               self.frame.size.width,
                                               40.0);
    yOffset += quickLoginUsingPinLabel.frame.size.height;
    yOffset += 20.0;
    
    backToPasswordLabel.frame = CGRectMake(0.0,
                                           yOffset,
                                           self.frame.size.width,
                                           80.0);
    
    yOffset += backToPasswordLabel.frame.size.height;
    yOffset += 20.0;
    
    addPinInSettingsLabel.frame = CGRectMake(0.0,
                                           yOffset,
                                           self.frame.size.width,
                                           80.0);
	
    buttonsBackground.frame = CGRectMake(0.0,
                                         self.frame.size.height - 55.0,
                                         self.frame.size.width,
                                         55.0);
    
    laterButton.frame = CGRectMake(5.0,
                                   self.frame.size.height - 5.0 - 45.0,
                                   roundf((self.frame.size.width - 20.0) / 2.0),
                                   45.0);
    
    setUpPinButton.frame = CGRectMake(laterButton.frame.origin.x + laterButton.frame.size.width + 10.0,
                                      laterButton.frame.origin.y,
                                      laterButton.frame.size.width,
                                      laterButton.frame.size.height);
}

#pragma mark -
#pragma mark Private

-(void) setUpNewPinButtonPressed
{
    [self.delegate setUpPin];
}

-(void) laterButtonPressed
{
    [self.delegate skipPinSetUp];
}

@end
