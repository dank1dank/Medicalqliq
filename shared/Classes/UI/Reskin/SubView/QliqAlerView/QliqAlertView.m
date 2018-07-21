//
//  CustomIOSAlertView.m
//  CustomIOSAlertView
//
//  Created by Richard on 20/09/2013.
//  Copyright (c) 2013-2015 Wimagguc.
//
//  Lincesed under The MIT License (MIT)
//  http://opensource.org/licenses/MIT
//

#import "QliqAlertView.h"
#import <QuartzCore/QuartzCore.h>

typedef enum {
    SwitchQliqSTOR = 0,
    SwitchSaveDefault = 1,
} SwitchAction;

#define kValueMaxAlertViewWidth 240.f

#define RGBa(r,g,b,a) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]

#define kColorBackroundButtonGray RGBa(235.0f, 235.0f, 235.0f, 1.0f)
#define kColorBackroundButtonBlue RGBa(24.0f,  122.0f, 181.0f, 1.0f)

#define kUploadToQliqSTORKey @"uploadToQliqSTORKey"

const static CGFloat kCustomIOSAlertViewDefaultButtonHeight       = 40.f;
const static CGFloat kCustomIOSAlertViewDefaultButtonSpacerHeight = 1.f;
const static CGFloat kCustomIOSAlertViewCornerRadius              = 5.f;
const static CGFloat kCustomIOS7MotionEffectExtent                = 10.0f;

@interface QliqAlertView () <UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView       *buttonsView;
@property (nonatomic, strong) UITextField *savingTextField;

@property (nonatomic, assign) CGFloat buttonHeight;
@property (nonatomic, assign) CGFloat buttonSpacerHeight;

@property (nonatomic, strong) UIColor *colorBlue;
@property (nonatomic, strong) UIColor *colorWhite;
@property (nonatomic, assign) BOOL *inverseColors;
@property (nonatomic, assign) BOOL isUploadToQliqSTOR;
@property (nonatomic, assign) BOOL isUploadToEMR;
@property (nonatomic, assign) BOOL isSaveDefault;
@property (nonatomic, assign) float keyboardHeight;

//Multiple QliqSTORs Avialable
@property (nonatomic, strong) NSArray *multipleGroups;
@property (nonatomic, strong) UIPickerView *typePicker;
@property (nonatomic, strong) QliqStorPerGroup *selectedQliqSTORGroup;

@end

@implementation QliqAlertView

- (id)initWithInverseColor:(BOOL)inverseColors
{
    self = [super init];
    if (self) {
        self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);

        self.delegate           = self;
        self.useMotionEffects   = NO;
        self.buttonTitles       = @[@"OK"];
        self.buttonHeight       = 0;
        self.buttonSpacerHeight = 0;

        self.inverseColors = inverseColors;
        self.colorWhite = inverseColors ? RGBa(3, 120, 173, 1) : [UIColor whiteColor];
        self.colorBlue = inverseColors ? [UIColor whiteColor] : RGBa(3, 120, 173, 1);
        
//        
//        UITapGestureRecognizer* tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeAlert)];
//        [self addGestureRecognizer:tapGestureRecognizer];
        
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}

- (void)closeAlert
{
    [self close];
}

// Create the dialog view, and animate opening the dialog
- (void)show
{
    self.dialogView = [self createContainerView];
  
    self.dialogView.layer.shouldRasterize = YES;
    self.dialogView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
 
    self.layer.shouldRasterize = YES;
    self.layer.rasterizationScale = [[UIScreen mainScreen] scale];

#if (defined(__IPHONE_7_0))
    if (self.useMotionEffects) {
        [self applyMotionEffects];
    }
#endif

    self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];

    [self addSubview:self.dialogView];

    // Can be attached to a view or to the top most window
    // Attached to a view:
    if (self.parentView != NULL) {
        [self.parentView addSubview:self];

    // Attached to the top most window
    } else {

        // On iOS7, calculate with orientation
        if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
            
            UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
            switch (interfaceOrientation) {
                case UIInterfaceOrientationLandscapeLeft:
                    self.transform = CGAffineTransformMakeRotation(M_PI * 270.0 / 180.0);
                    break;
                    
                case UIInterfaceOrientationLandscapeRight:
                    self.transform = CGAffineTransformMakeRotation(M_PI * 90.0 / 180.0);
                    break;
                    
                case UIInterfaceOrientationPortraitUpsideDown:
                    self.transform = CGAffineTransformMakeRotation(M_PI * 180.0 / 180.0);
                    break;
                    
                default:
                    break;
            }
            
            [self setFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];

        // On iOS8, just place the dialog in the middle
        } else {

            CGSize screenSize = [self countScreenSize];
            CGSize dialogSize = [self countDialogSize];
            CGSize keyboardSize = CGSizeMake(0, 0);

            self.dialogView.frame = CGRectMake((screenSize.width - dialogSize.width) / 2, (screenSize.height - keyboardSize.height - dialogSize.height) / 2, dialogSize.width, dialogSize.height);
        }

        [[[[UIApplication sharedApplication] windows] firstObject] addSubview:self];
    }

    self.dialogView.layer.opacity = 0.5f;
    self.dialogView.layer.transform = CATransform3DMakeScale(1.3f, 1.3f, 1.0);

    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4f];
                         self.dialogView.layer.opacity = 1.0f;
                         self.dialogView.layer.transform = CATransform3DMakeScale(1, 1, 1);
					 }
					 completion:NULL
     ];

}

// Button has been touched
- (IBAction)customIOS7dialogButtonTouchUpInside:(UIButton*)sender
{
    if (self.delegate != NULL) {
//        [self.delegate customIOS7dialogButtonTouchUpInside:self clickedButtonAtIndex:[sender tag]];
    }

    if (self.onButtonTouchUpInside != NULL) {
        self.onButtonTouchUpInside(self, (int)[sender tag]);
    }
    
    [self close];
}

// Default button behaviour
- (void)customIOS7dialogButtonTouchUpInside: (QliqAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"Button Clicked! %d, %d", (int)buttonIndex, (int)[alertView tag]);
    [self close];
}

// Dialog close animation then cleaning and removing the view from the parent
- (void)close
{
    CATransform3D currentTransform = self.dialogView.layer.transform;

    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
        CGFloat startRotation = [[self.dialogView valueForKeyPath:@"layer.transform.rotation.z"] floatValue];
        CATransform3D rotation = CATransform3DMakeRotation(-startRotation + M_PI * 270.0 / 180.0, 0.0f, 0.0f, 0.0f);

        self.dialogView.layer.transform = CATransform3DConcat(rotation, CATransform3DMakeScale(1, 1, 1));
    }

    self.dialogView.layer.opacity = 1.0f;

    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
					 animations:^{
						 self.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.0f];
                         self.dialogView.layer.transform = CATransform3DConcat(currentTransform, CATransform3DMakeScale(0.6f, 0.6f, 1.0));
                         self.dialogView.layer.opacity = 0.0f;
					 }
					 completion:^(BOOL finished) {
                         for (UIView *v in [self subviews]) {
                             [v removeFromSuperview];
                         }
                         [self removeFromSuperview];
					 }
	 ];
}

- (void)setSubView: (UIView *)subView
{
    self.containerView = subView;
}

// Creates the container view here: create the dialog, then add the custom content and buttons
- (UIView *)createContainerView
{
    if (self.containerView == NULL) {
        self.containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kValueMaxAlertViewWidth, 150)];
    }

    CGSize screenSize = [self countScreenSize];
    CGSize dialogSize = [self countDialogSize];

    // For the black background
    [self setFrame:CGRectMake(0, 0, screenSize.width, screenSize.height)];

    // This is the dialog's container; we attach the custom content and the buttons to this one
    UIView *dialogContainer = [[UIView alloc] initWithFrame:CGRectMake((screenSize.width - dialogSize.width) / 2,
                                                                       (screenSize.height - dialogSize.height) / 2,
                                                                       dialogSize.width,
                                                                       dialogSize.height)];
    // First, we style the dialog to match the iOS7 UIAlertView >>>
    {
        CGFloat cornerRadius = kCustomIOSAlertViewCornerRadius;
        /*
         CAGradientLayer *gradient = [CAGradientLayer layer];
         gradient.frame = dialogContainer.bounds;
         gradient.colors = [NSArray arrayWithObjects:
         (id)[[UIColor colorWithRed:218.0/255.0 green:218.0/255.0 blue:218.0/255.0 alpha:1.0f] CGColor],
         (id)[[UIColor colorWithRed:233.0/255.0 green:233.0/255.0 blue:233.0/255.0 alpha:1.0f] CGColor],
         (id)[[UIColor colorWithRed:218.0/255.0 green:218.0/255.0 blue:218.0/255.0 alpha:1.0f] CGColor],
         nil];
         
         gradient.cornerRadius = cornerRadius;
         [dialogContainer.layer insertSublayer:gradient atIndex:0];
         */
        
        dialogContainer.backgroundColor     = self.colorWhite;
        dialogContainer.clipsToBounds       = YES;
        dialogContainer.layer.cornerRadius  = cornerRadius;
        dialogContainer.layer.borderColor   = [[UIColor clearColor]/* [UIColor colorWithRed:198.0/255.0 green:198.0/255.0 blue:198.0/255.0 alpha:1.0f]*/ CGColor];
        dialogContainer.layer.borderWidth   = 1;
        dialogContainer.layer.shadowRadius  = cornerRadius + 5;
        dialogContainer.layer.shadowOpacity = 0.1f;
        dialogContainer.layer.shadowOffset  = CGSizeMake(0 - (cornerRadius+5)/2, 0 - (cornerRadius+5)/2);
        dialogContainer.layer.shadowColor   = [UIColor blackColor].CGColor;
        dialogContainer.layer.shadowPath    = [UIBezierPath bezierPathWithRoundedRect:dialogContainer.bounds cornerRadius:dialogContainer.layer.cornerRadius].CGPath;
    }
    
    // There is a line above the button
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                dialogContainer.bounds.size.height - self.buttonHeight - self.buttonSpacerHeight,
                                                                dialogContainer.bounds.size.width,
                                                                self.buttonSpacerHeight)];
    {
        lineView.backgroundColor = [UIColor colorWithRed:198.0/255.0 green:198.0/255.0 blue:198.0/255.0 alpha:1.0f];
        //[dialogContainer addSubview:lineView];
    }
    // ^^^
    
    // Add the custom container if there is any
    [dialogContainer addSubview:self.containerView];

    // Add the buttons too
    [self addButtonsToView:dialogContainer];

    return dialogContainer;
}

//#define kColorTitleButtonGray

// Helper function: add buttons to container
- (void)addButtonsToView: (UIView *)container
{
    if (self.buttonTitles == NULL) { return; }

    if (self.buttonsView)
    {
        [self.buttonsView removeFromSuperview];
        self.buttonsView = nil;
    }
    
    self.buttonsView = [[ UIView alloc ] initWithFrame:CGRectMake(0,
                                                                  container.bounds.size.height - self.buttonHeight,
                                                                  container.bounds.size.width,
                                                                  self.buttonHeight)];
    [container addSubview:self.buttonsView];
    
    
    CGFloat buttonWidth = container.bounds.size.width / [self.buttonTitles count];

    for (NSInteger index = 0; index < [self.buttonTitles count]; index++)
    {
        BOOL isGrayButton = self.buttonTitles.count > 1 && index == 0;
        
        UIColor *backgroundColor = isGrayButton ? kColorBackroundButtonGray
                                                : self.inverseColors ? [UIColor whiteColor]
                                                                     : kColorBackroundButtonBlue;
        UIColor *titleColor      = isGrayButton ? [UIColor darkGrayColor] : self.inverseColors ? kColorBackroundButtonBlue
                                                                                               : [UIColor whiteColor];
        
        UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];

//        [closeButton setFrame:CGRectMake(index * buttonWidth, container.bounds.size.height - self.buttonHeight, buttonWidth, self.buttonHeight)];
        [closeButton setFrame:CGRectMake(index * buttonWidth, 0, buttonWidth, self.buttonHeight)];
        
        [closeButton addTarget:self action:@selector(customIOS7dialogButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
        [closeButton setTag:index];

        [closeButton setTitle:[self.buttonTitles objectAtIndex:index] forState:UIControlStateNormal];
        [closeButton setTitleColor:titleColor forState:UIControlStateNormal];
//        [closeButton setTitleColor:[UIColor colorWithRed:0.2f green:0.2f blue:0.2f alpha:0.5f] forState:UIControlStateHighlighted];
        [closeButton setBackgroundColor:backgroundColor];
        [closeButton.titleLabel setFont:[UIFont boldSystemFontOfSize:14.0f]];
//        [closeButton.layer setCornerRadius:kCustomIOSAlertViewCornerRadius];

//        [container addSubview:closeButton];
        [self.buttonsView addSubview:closeButton];
    }
}

// Helper function: count and return the dialog's size
- (CGSize)countDialogSize
{
    CGFloat dialogWidth     = self.containerView.frame.size.width;
    CGFloat dialogHeight    = self.containerView.frame.size.height + self.buttonHeight + self.buttonSpacerHeight;

    return CGSizeMake(dialogWidth, dialogHeight);
}

- (CGSize)countMaxSizeContainerView
{
    CGSize maxHeightContainerView = CGSizeZero;
    
    CGSize screenSize = [self countScreenSize];
    maxHeightContainerView = CGSizeMake(kValueMaxAlertViewWidth, screenSize.height - (40.f + self.buttonHeight + self.buttonSpacerHeight) );
    
    return maxHeightContainerView;
}

// Helper function: count and return the screen's size
- (CGSize)countScreenSize
{
    if (self.buttonTitles!=NULL && [self.buttonTitles count] > 0) {
        self.buttonHeight       = kCustomIOSAlertViewDefaultButtonHeight;
        self.buttonSpacerHeight = kCustomIOSAlertViewDefaultButtonSpacerHeight;
    } else {
        self.buttonHeight = 0;
        self.buttonSpacerHeight = 0;
    }

    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;

    // On iOS7, screen width and height doesn't automatically follow orientation
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
        UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
            CGFloat tmp = screenWidth;
            screenWidth = screenHeight;
            screenHeight = tmp;
        }
    }
    
    return CGSizeMake(screenWidth, screenHeight);
}

#if (defined(__IPHONE_7_0))
// Add motion effects
- (void)applyMotionEffects {

    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        return;
    }

    UIInterpolatingMotionEffect *horizontalEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
                                                                                                    type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    horizontalEffect.minimumRelativeValue = @(-kCustomIOS7MotionEffectExtent);
    horizontalEffect.maximumRelativeValue = @( kCustomIOS7MotionEffectExtent);

    UIInterpolatingMotionEffect *verticalEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
                                                                                                  type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    verticalEffect.minimumRelativeValue = @(-kCustomIOS7MotionEffectExtent);
    verticalEffect.maximumRelativeValue = @( kCustomIOS7MotionEffectExtent);

    UIMotionEffectGroup *motionEffectGroup = [[UIMotionEffectGroup alloc] init];
    motionEffectGroup.motionEffects = @[horizontalEffect, verticalEffect];

    [self.dialogView addMotionEffect:motionEffectGroup];
}
#endif

- (void)dealloc
{
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    
    self.buttonsView = nil;
    self.dialogView = nil;
    self.parentView = nil;
    self.containerView = nil;
    self.scrollView = nil;
    self.buttonTitles = nil;
}

#pragma mark - Set... -

- (void)setContainerViewWithImage:(UIImage*)image
                        withTitle:(NSString*)title
                         withText:(NSString*)text
                     withDelegate:(id)delegate
                 useMotionEffects:(BOOL)useMotionEffects
{
    self.delegate         = delegate;
    self.useMotionEffects = useMotionEffects;
    
    CGSize maxSize = [self countMaxSizeContainerView];
    
    self.scrollView        = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, maxSize.width, maxSize.height)];
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator   = NO;
    UIImageView *imageView = nil;
    UILabel *titleLabel    = nil;
    UILabel *textLabel     = nil;
    
    CGFloat globalOffset = 0;
    CGFloat offsetY = 15.f;
    
    if (image)
    {
        CGFloat imageViewWidth = maxSize.width - 4.f;
        CGFloat imageViewHeight = imageViewWidth * 0.4f;
        
        imageView = [[UIImageView alloc] initWithImage:image];
        imageView.frame              = CGRectMake(0, 2, imageViewWidth, imageViewHeight);
        imageView.center             = CGPointMake(CGRectGetMidX(self.scrollView.frame), imageView.center.y);
        imageView.layer.cornerRadius = 10;
        [self.scrollView addSubview:imageView];
        
        globalOffset = CGRectGetMaxY(imageView.frame);
    }
    
    if (title)
    {
        titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, maxSize.width - offsetY, CGFLOAT_MAX)];
        titleLabel.text          = title;
        titleLabel.font          = [UIFont boldSystemFontOfSize:20.f];
        titleLabel.textColor     = self.colorBlue;
        titleLabel.numberOfLines = NSIntegerMax;
        titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        titleLabel.opaque        = NO;
        [titleLabel sizeToFit];
        titleLabel.center        = CGPointMake(CGRectGetMidX(self.scrollView.frame), titleLabel.center.y);
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.frame         = CGRectMake(titleLabel.frame.origin.x,
                                              offsetY + globalOffset,
                                              titleLabel.frame.size.width,
                                              titleLabel.frame.size.height);
        [self.scrollView addSubview:titleLabel];
        
        globalOffset = CGRectGetMaxY(titleLabel.frame);
    }
    
    if (text)
    {
        textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, maxSize.width - offsetY, CGFLOAT_MAX)];
        textLabel.numberOfLines = NSIntegerMax;
        textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        textLabel.opaque        = NO;
        textLabel.text          = text;
        textLabel.textColor     = self.colorBlue;
        textLabel.font          = [UIFont systemFontOfSize:15.f];
        [textLabel sizeToFit];
        textLabel.center        = CGPointMake(CGRectGetMidX(self.scrollView.frame), textLabel.center.y);
        textLabel.textAlignment = NSTextAlignmentCenter;
        textLabel.frame = CGRectMake(textLabel.frame.origin.x, offsetY + globalOffset, textLabel.frame.size.width, textLabel.frame.size.height);
        [self.scrollView addSubview:textLabel];
        
        globalOffset = CGRectGetMaxY(textLabel.frame);
    }

    UISwitch *switchOption = [[UISwitch alloc] initWithFrame:CGRectMake(0.f, 0.f, 0.f, 0.f)];
    
    if (self.hideSwitch) {
        switchOption.hidden = YES;
    } else {
        switchOption.hidden = self.useUploadOption ? ![QliqGroupDBService hasAnyQliqStor] : !self.useMultipleQliqSTORsAvialable;
    }
    
    UILabel *titleOptionLabel = nil;
    NSInteger switchWidth = 50.f;
    NSInteger switchHeight = 31.f;

    if (!switchOption.hidden) {

        switchOption.onTintColor = self.colorBlue;
        switchOption.backgroundColor = [UIColor clearColor];
        switchOption.tintColor = self.colorBlue;
        switchOption.tag = self.useUploadOption ? SwitchQliqSTOR : SwitchSaveDefault;
        [switchOption addTarget:self action:@selector(didChangeValueInSwitch:) forControlEvents:UIControlEventValueChanged];
        [switchOption setOn:NO animated:NO];

        if (self.useMultipleQliqSTORsAvialable) {
            self.isSaveDefault = switchOption.isOn;
        }
        else {
            self.isUploadToQliqSTOR = switchOption.isOn;
        }

        titleOptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.f, 0.f, 0.f, 0.f)];
        titleOptionLabel.textColor = [UIColor grayColor];
    }

    if (self.useUploadOption) {

        self.savingTextField = [[UITextField alloc] initWithFrame:CGRectMake(0.f + 10.f, titleLabel.frame.origin.y + titleLabel.frame.size.height + 15.f, self.scrollView.frame.size.width - 20.f, 25.f)];
        self.savingTextField.borderStyle = UITextBorderStyleLine;
        self.savingTextField.text = self.fileName;
        self.savingTextField.placeholder = QliqLocalizedString(@"2405-EnterFileName");
        self.savingTextField.textAlignment = NSTextAlignmentCenter;
        self.savingTextField.backgroundColor = [UIColor whiteColor];
        self.savingTextField.keyboardType = UIKeyboardTypeDefault;
        [self.savingTextField becomeFirstResponder];
        [self.scrollView addSubview:self.savingTextField];
        globalOffset += self.savingTextField.frame.size.height + 15.f;


        if ([QliqGroupDBService hasAnyQliqStor]) {
            
            [titleOptionLabel setFrame:CGRectMake(0.f + 10.f, self.savingTextField.frame.origin.y + self.savingTextField.frame.size.height + 15.f, self.scrollView.frame.size.width - 20.f - switchWidth - 5.f, 20.f)];
            titleOptionLabel.text = QliqLocalizedString(@"1229-TitleUploadToQliqStor");
            [switchOption setFrame:CGRectMake(self.savingTextField.frame.origin.x + titleOptionLabel.frame.size.width + 5.f, titleOptionLabel.frame.origin.y - 5.f, switchWidth, switchHeight)];

            if ([[NSUserDefaults standardUserDefaults] boolForKey:kUploadToQliqSTORKey] == YES) {
                [switchOption setOn:YES animated:NO];
            }
            else {
                [switchOption setOn:NO animated:NO];
            }
            self.isUploadToQliqSTOR = switchOption.isOn;

        } else {
            self.isUploadToQliqSTOR = NO;
        }
        
        /*
        UILabel *uploadToEMRLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.f + 10.f, uploadToQliqSTORLabel.frame.origin.y + switchHeight + 10.f, self.scrollView.frame.size.width - 20.f - switchWidth - 5.f, 20.f)];
        uploadToEMRLabel.text = QliqLocalizedString(@"2189-TitleUploadToEMR");
        uploadToEMRLabel.textColor = [UIColor grayColor];
        [self.scrollView addSubview:uploadToEMRLabel];
        globalOffset += switchHeight + 15.f;

        UISwitch *switchOptionUploadToEMR = [[UISwitch alloc] initWithFrame:CGRectMake(uploadToEMRLabel.frame.origin.x + uploadToEMRLabel.frame.size.width + 5.f, uploadToEMRLabel.frame.origin.y - 5.f, switchWidth, switchHeight)];
        switchOptionUploadToEMR.onTintColor = self.colorBlue;
        switchOptionUploadToEMR.backgroundColor = [UIColor clearColor];
        switchOptionUploadToEMR.tintColor = self.colorBlue;
        switchOptionUploadToEMR.tag = SwitchQliqSTOR2+2;
        [switchOptionUploadToEMR addTarget:self action:@selector(didChangeValue2InSwitch:) forControlEvents:UIControlEventValueChanged];
        [switchOptionUploadToEMR setOn:YES animated:NO];
        self.isUploadToEMR = switchOptionUploadToEMR.isOn;
        [self.scrollView addSubview:switchOptionUploadToEMR];
         */
    }
    
    if (self.useMultipleQliqSTORsAvialable) {

        self.destinationGroupTextField = [[UITextField alloc] initWithFrame:CGRectMake(0.f + 10.f, textLabel.frame.origin.y + textLabel.frame.size.height + 15.f, self.scrollView.frame.size.width - 20.f, 25.f)];
        self.destinationGroupTextField.borderStyle = UITextBorderStyleLine;

//        self.destinationGroupTextField.text = @"test";
        self.destinationGroupTextField.placeholder = QliqLocalizedString(@"3036-TitleDestinationGroup");
        self.destinationGroupTextField.textAlignment = NSTextAlignmentCenter;
        self.destinationGroupTextField.backgroundColor = [UIColor whiteColor];
        self.destinationGroupTextField.keyboardType = UIKeyboardTypeDefault;
        [self.destinationGroupTextField becomeFirstResponder];
        [self.scrollView addSubview:self.destinationGroupTextField];
        globalOffset += self.destinationGroupTextField.frame.size.height + 15.f;

        self.multipleGroups = [QxQliqStorClient qliqStors];

        self.typePicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0.f, 0.f, [UIScreen mainScreen].bounds.size.width, 120.f)];
        self.typePicker.dataSource = self;
        self.typePicker.delegate = self;
        self.typePicker.showsSelectionIndicator = YES;
        self.destinationGroupTextField.inputView = self.typePicker;

        [titleOptionLabel setFrame:CGRectMake(0.f + 10.f, self.destinationGroupTextField.frame.origin.y + self.destinationGroupTextField.frame.size.height + 15.f, self.scrollView.frame.size.width - 20.f - switchWidth - 5.f, 20.f)];
        titleOptionLabel.text = QliqLocalizedString(@"3038-TextDefaulsSave");
        [switchOption setFrame:CGRectMake(self.destinationGroupTextField.frame.origin.x + titleOptionLabel.frame.size.width + 5.f, titleOptionLabel.frame.origin.y - 5.f, switchWidth, switchHeight)];
    }

    if (!switchOption.hidden) {
        [self.scrollView addSubview:titleOptionLabel];
        [self.scrollView addSubview:switchOption];

        globalOffset += titleOptionLabel.frame.size.height + 20.f;
    }

    globalOffset = globalOffset + offsetY;
    
    self.scrollView.frame = CGRectMake(self.scrollView.frame.origin.x,
                                       self.scrollView.frame.origin.y,
                                       self.scrollView.frame.size.width,
                                       MIN(maxSize.height, globalOffset) );
    self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width, globalOffset);
 
    UIView *containerView = [[UIView alloc] initWithFrame:self.scrollView.frame];
    [containerView addSubview:self.scrollView];

    self.containerView = containerView;
}

- (void)changeSizeContentView
{
    CGSize maxSize = [self countMaxSizeContainerView];
    
    CGRect scrollRect = self.scrollView.frame;
    scrollRect.size.height        = MIN(maxSize.height, self.scrollView.contentSize.height);
    self.scrollView.frame         = scrollRect;
    self.scrollView.contentOffset = CGPointMake(0, 0);
    
    self.containerView.frame = self.scrollView.frame;

    CGRect dialogRect = self.dialogView.frame;
    dialogRect.size.height = self.containerView.frame.size.height + self.buttonHeight + self.buttonSpacerHeight;
    self.dialogView.frame  = dialogRect;

    [self addButtonsToView:self.dialogView];
}

- (void)didChangeValueInSwitch:(UISwitch *)switchOption
{
    switch (switchOption.tag) {
        case SwitchQliqSTOR: {

            DDLogSupport(@"Tapped on uploadToQliqSTOR switch option. QliqSTOR is %d", switchOption.isOn);
            self.isUploadToQliqSTOR = switchOption.isOn;
            break;
        }
        case SwitchSaveDefault: {

            DDLogSupport(@"Tapped on 'save as default' switch option. Save as default is %d", switchOption.isOn);
            self.isSaveDefault = switchOption.isOn;
            break;
        }
        default:
            break;
    }
}

- (void)didChangeValue2InSwitch:(UISwitch *)switchOption
{
    DDLogSupport(@"Tapped on upload to EMR switch option. EMROption is %d", switchOption.isOn);
    self.isUploadToEMR = switchOption.isOn;
}

- (BOOL)isQliqSTOROption {
    return self.isUploadToQliqSTOR;
}

- (BOOL)isEMROption {
    return self.isUploadToEMR;
}

- (BOOL)isSaveDefaultOption {
    return self.isSaveDefault;
}

- (NSString *)savingTextFiledFileName {
    return self.savingTextField.text;
}

- (QliqStorPerGroup *)selectedTypeQliqSTORGroup {
    return self.selectedQliqSTORGroup;
}
#pragma mark - Orientation -

// Rotation changed, on iOS7
- (void)changeOrientationForIOS7 {

    if (self.useUploadOption) {

        UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];

        CGFloat startRotation = [[self valueForKeyPath:@"layer.transform.rotation.z"] floatValue];
        CGAffineTransform rotation;

        switch (interfaceOrientation) {
            case UIInterfaceOrientationLandscapeLeft:
                rotation = CGAffineTransformMakeRotation(-startRotation + M_PI * 270.0 / 180.0);
                break;

            case UIInterfaceOrientationLandscapeRight:
                rotation = CGAffineTransformMakeRotation(-startRotation + M_PI * 90.0 / 180.0);
                break;

            case UIInterfaceOrientationPortraitUpsideDown:
                rotation = CGAffineTransformMakeRotation(-startRotation + M_PI * 180.0 / 180.0);
                break;

            default:
                rotation = CGAffineTransformMakeRotation(-startRotation + 0.0);
                break;
        }

        [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
                         animations:^{
                             self.dialogView.transform = rotation;
                             
                         }
                         completion:nil
         ];
    }
}

// Rotation changed, on iOS8
- (void)changeOrientationForIOS8: (NSNotification *)notification {

    if (!self.useUploadOption) {

        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;

        [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
                         animations:^{
                             CGSize dialogSize = [self countDialogSize];
//                             CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
                             self.frame = CGRectMake(0, 0, screenWidth, screenHeight);
                             //                         self.dialogView.center = self.center;
                             //
                             self.dialogView.frame = CGRectMake((screenWidth - dialogSize.width) / 2,
                                                                (screenHeight - self.keyboardHeight - dialogSize.height) / 2,
                                                                dialogSize.width,
                                                                dialogSize.height);
                         }
                         completion:nil
         ];
    }
}

// Handle device orientation changes
- (void)deviceOrientationDidChange: (NSNotification *)notification
{
    // If dialog is attached to the parent view, it probably wants to handle the orientation change itself
    if (self.parentView != NULL) {
        return;
    }

    [self changeSizeContentView];
    
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
        [self changeOrientationForIOS7];
    } else {
        [self changeOrientationForIOS8:notification];
    }
}

#pragma mark - Keyboard -

// Handle keyboard show/hide changes
- (void)keyboardWillShow: (NSNotification *)notification
{
    
    CGSize screenSize = [self countScreenSize];
    CGSize dialogSize = [self countDialogSize];
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    if (keyboardSize.height!=0) {
        self.keyboardHeight=keyboardSize.height;
    }
    
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation) && NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1) {
        CGFloat tmp = self.keyboardHeight;
        self.keyboardHeight = keyboardSize.width;
        keyboardSize.width = tmp;
    }

    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
					 animations:^{
                         self.dialogView.frame = CGRectMake((screenSize.width - dialogSize.width) / 2, (screenSize.height - self.keyboardHeight - dialogSize.height) / 2, dialogSize.width, dialogSize.height);
					 }
					 completion:nil
	 ];
}

- (void)keyboardWillHide: (NSNotification *)notification
{
    CGSize screenSize = [self countScreenSize];
    CGSize dialogSize = [self countDialogSize];

    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
					 animations:^{
                         self.dialogView.frame = CGRectMake((screenSize.width - dialogSize.width) / 2, (screenSize.height - dialogSize.height) / 2, dialogSize.width, dialogSize.height);
					 }
					 completion:nil
	 ];
}

#pragma mark - UIPickerViewDataSource/UIPickerViewDelegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.multipleGroups.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    QliqStorPerGroup *qg = [self.multipleGroups objectAtIndex:row];
    return [qg displayName];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {

    QliqStorPerGroup *qg = self.multipleGroups[[self.typePicker selectedRowInComponent:0]];
    self.selectedQliqSTORGroup = qg;
    self.destinationGroupTextField.text = [qg displayName];
}

- (void)didPressTypePickerCancelButton:(UIBarButtonItem *)sender {
    [self.destinationGroupTextField resignFirstResponder];
}

- (void)didPressTypePickerDoneButton:(UIBarButtonItem *)sender {

    if (![self.multipleGroups[[self.typePicker selectedRowInComponent:0]] isEqualToString:@""]) {
        self.destinationGroupTextField.text = self.multipleGroups[[self.typePicker selectedRowInComponent:0]];
    }
    else {
        self.destinationGroupTextField.text = nil;
    }

    QliqStorPerGroup *qg = self.multipleGroups[[self.typePicker selectedRowInComponent:0]];
    self.destinationGroupTextField.text =  [qg displayName];
    self.selectedQliqSTORGroup = qg;
    [self.destinationGroupTextField resignFirstResponder];
}

@end
