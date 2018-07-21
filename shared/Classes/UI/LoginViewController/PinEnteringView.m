//
//  PinEnteringView.m
//  qliq
//
//  Created by Paul Bar on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PinEnteringView.h"
#import "RoundedLightGreyGradientView.h"
#import "StretchableButton.h"
#import "DeviceInfo.h"

#define PIN_LEN 4

@interface PinEnteringView()

-(NSString *) getPin; 
-(void) switchToPasswordButtonPressed;

@property (nonatomic, strong) NSString *pinNumber;

@end

@implementation PinEnteringView {
    BOOL alreadyInEditing;
    BOOL isTextBegin;
}

@synthesize pinEnteringDelegate;
@synthesize enterPinLabel;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        isTextBegin = YES;
        // Initialization code
        self.backgroundColor = [UIColor colorWithRed:0.0 green:(65.0/255.0) blue:(106.0/255.0) alpha:1.0];
        
        enterPinLabel = [[UILabel alloc] init];
        enterPinLabel.backgroundColor = [UIColor clearColor];
        enterPinLabel.textColor = [UIColor whiteColor];
        enterPinLabel.font = [UIFont boldSystemFontOfSize:12.0];
        enterPinLabel.textAlignment = UITextAlignmentCenter;
        [self addSubview:enterPinLabel];
        
        backgrounds = [[NSMutableArray alloc] initWithCapacity:PIN_LEN];
        fields = [[NSMutableArray alloc] initWithCapacity:PIN_LEN];
        
        for(int i = 0; i<PIN_LEN; i++)
        {
            RoundedLightGreyGradientView *bckg = [[RoundedLightGreyGradientView alloc] init];
            [self addSubview:bckg];
            [backgrounds addObject:bckg];
            [bckg release];
            
            // M: changed UITextField to QliqTextField
            QliqTextfield *field = [[QliqTextfield alloc] initWithFrame:CGRectMake(50+60*i, 200 + ([DeviceInfo sharedInfo].iosVersionMajor <7 ? 10 : 2), 45, 45) style:QliqTextfieldStyleClear];
            field.borderStyle = UITextBorderStyleNone;
            field.textAlignment = UITextAlignmentCenter;
            field.returnKeyType = UIReturnKeyDefault;
            field.secureTextEntry = YES;
            field.font = [UIFont fontWithName:@"Helvetica-Bold" size:20.0];
            field.adjustsFontSizeToFitWidth = YES;
            field.delegate = self;
            field.tag = i;
            field.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            field.keyboardType = UIKeyboardTypeNumberPad;
            field.clearButtonMode = UITextFieldViewModeNever;
            [self addSubview:field];
            [fields addObject:field];
            [field release];
        }
        
        switchToPasswordButton = [[[StretchableButton alloc] init] autorelease];
        [switchToPasswordButton setTitle:@"Switch to Email & Password" forState:UIControlStateNormal];
        switchToPasswordButton.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14.0];
        switchToPasswordButton.titleLabel.textColor = [UIColor whiteColor];
        switchToPasswordButton.btnType = StretchableButton25;
        [switchToPasswordButton addTarget:self action:@selector(switchToPasswordButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:switchToPasswordButton];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotateFromInterfaceOrientation) name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    return self;
}


-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [enterPinLabel release];
    [backgrounds release];
    [fields release];
    [super dealloc];
}


- (void) applyContentInset
{
    UIEdgeInsets insets = UIEdgeInsetsZero;
    
    CGRect frame = [self convertRect:switchToPasswordButton.frame fromView:[switchToPasswordButton superview]];
    
    insets.top = MIN( (self.frame.size.height - kKeyboardHeight) - CGRectGetMaxY(frame), 0);
    insets.bottom = frame.size.height;
    
    [self setContentInset:insets];
}

- (void)textFieldDidBeginEditing:(QliqTextfield *)textField{

//    if (alreadyInEditing) {
//        [self applyContentInset];
//    } else {
//        [UIView animateWithDuration:0.3 animations:^{
//            [self applyContentInset];
//        }];
//        alreadyInEditing = YES;
//    }
    
    // M: Clear when focused
    if(isTextBegin) {
        isTextBegin = NO;
        textField.text = @"";
        textField.text = self.pinNumber;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.3 animations:^{
        [self setContentInset:UIEdgeInsetsZero];
    }];
}

- (void) didRotateFromInterfaceOrientation
{
    [UIView animateWithDuration:0.3 animations:^{
        [self textFieldDidBeginEditing:fields[0]];
    }];
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
    
    CGFloat viewsOffset = 10.0;
    CGFloat yOffset = viewsOffset + 57.0 + 25.0;
    
    if([enterPinLabel.text length] == 0)
    {
        enterPinLabel.frame = CGRectZero;
    }
    else
    {
        CGSize labelSize = [enterPinLabel.text sizeWithFont:enterPinLabel.font];
        enterPinLabel.frame = CGRectMake(0.0,
                                         yOffset,
                                         self.frame.size.width,
                                         labelSize.height);
    }
    
    yOffset += enterPinLabel.frame.size.height;
    yOffset += viewsOffset;
    
    CGFloat backgroundWidht = 45.0;
    CGFloat backgroundHeight = 45.0;
    
    CGFloat xOffset =roundf( ( self.frame.size.width - ((backgroundWidht * PIN_LEN) + (viewsOffset * PIN_LEN + 1)) ) / 2.0 );
    
    for(int i = 0; i<PIN_LEN; i++)
    {
        UIView *background = [backgrounds objectAtIndex:i];
        
        background.frame = CGRectMake(xOffset,
                                      yOffset,
                                      backgroundWidht,
                                      backgroundHeight);
        
        UIView *field = [fields objectAtIndex:i];
        
        field.frame = CGRectMake(background.frame.origin.x,
                                 background.frame.origin.y + ([DeviceInfo sharedInfo].iosVersionMajor < 7 ? 10.0 : 2.0),
                                 background.frame.size.width,
                                 42.0);
        
        xOffset += background.frame.size.width;
        xOffset += viewsOffset;
    }
    
    yOffset += backgroundHeight;
    yOffset += viewsOffset;
    
    switchToPasswordButton.frame = CGRectMake(viewsOffset,
                                              yOffset,
                                              self.frame.size.width - (viewsOffset * 2.0),
                                              44.0);
    
        [self applyContentInset];
}


-(void) reset
{
    for(int i=0; i<PIN_LEN; i++)
    {
        UITextField *textField = [fields objectAtIndex:i];
        textField.text = @"";
    }
    
    [[fields objectAtIndex:0] becomeFirstResponder];
}

-(void) hideKeyboard
{
    for(int i=0; i<PIN_LEN; i++)
    {
        UITextField *textField = [fields objectAtIndex:i];
        if([textField isFirstResponder])
        {
            [textField resignFirstResponder];
            break;
        }
    }
}

-(void) setHiddenForPasswordButton:(BOOL)hidden
{
    [switchToPasswordButton setHidden:hidden];
}

#pragma mark -
#pragma mark UITextFieldDelegate

// M: changed UITextField to QliqTextField
-(BOOL) textField:(QliqTextfield *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    self.pinNumber = string;
    NSString *result = [textField.text stringByReplacingCharactersInRange:range withString:string];
    int textFieldTag = textField.tag;
    
    if([result length] > 0)//moving cursor forward
    {
        isTextBegin = YES;
        if([result length] <= 1)
        {
            textField.text = result;
        }
        if(textFieldTag < (PIN_LEN -1))
        {
//            [[fields objectAtIndex:textFieldTag + 1] becomeFirstResponder];
            
            //Change that to fix the backspace button in ios 8
            if ([result length] > 1) {
                [[fields objectAtIndex:textFieldTag+1] becomeFirstResponder];
            }
            if (textFieldTag == (PIN_LEN -2)) {
                [self.pinEnteringDelegate didEnterPin:[self getPin]];
            }
        }
        else
        {
            [self.pinEnteringDelegate didEnterPin:[self getPin]];
        }
    }
    else if([result length] == 0)//moving cursor back
    {
        textField.text = result;
        if(textFieldTag > 0)
        {
            [[fields objectAtIndex:textFieldTag-1] becomeFirstResponder];
        }
        else
        {
            [self.pinEnteringDelegate didCanelEnteringPin];
        }
    }
    return NO;
}

// M: Added method to find backspace keystroke
- (void)textFieldDidDeleteBackward:(QliqTextfield *)textField{
    
    if(textField.tag > 0)
    {
        [[fields objectAtIndex:textField.tag-1] becomeFirstResponder];
    }
    else
    {
        [self.pinEnteringDelegate didCanelEnteringPin];
    }
    
}

#pragma mark -
#pragma mark Private

-(NSString*) getPin
{
    NSMutableString *rez = [NSMutableString stringWithCapacity:PIN_LEN];
    for(int i = 0; i<PIN_LEN; i++)
    {
        UITextField *textField = [fields objectAtIndex:i];
        [rez appendString:textField.text];
    }
    return rez;
}

-(void) switchToPasswordButtonPressed
{
    [self.pinEnteringDelegate switchToPasswordButtonPressed];
}

@end
