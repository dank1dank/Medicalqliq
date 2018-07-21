//
//  CustomActionSheet.m
//  qliq
//
//  Created by Valerii Lider on 17.02.14.
//
//

#import "CustomActionSheet.h"
#import "QliqNavigationController.h"

@interface InactiveView : UIButton
@property (nonatomic, strong) NSArray *passThroughViews;
@property (nonatomic, assign) CGRect passThroughFrame;
@property (nonatomic, weak) CustomActionSheet *actionSheet;
@end

@implementation InactiveView

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        self.passThroughViews = [@[] mutableCopy];
        
        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor colorWithWhite:0.f alpha:.35f];
    }
    return self;
}

- (void)hide {
    
    [self removeFromSuperview];
}

- (void)showInView:(UIView *)view {
    
    self.frame = [UIScreen mainScreen].bounds;
    [view addSubview:self];
}

- (void)setPassThroughViews:(NSArray *)passThroughViews {
    _passThroughViews = passThroughViews;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    
    if (CGRectContainsPoint(self.passThroughFrame, point)) {
        
        [self.actionSheet dismiss];
        self.actionSheet = nil;
        
        return nil;
    }
    
    for (UIView *item in self.passThroughViews) {
        
        CGPoint pt = [item convertPoint:point fromView:self];
        if (CGRectContainsPoint(item.frame, pt)) {
            
            [self.actionSheet dismiss];
            self.actionSheet = nil;
            
            return item;
        }
    }
    
    return self;
}

@end

typedef void (^ActionSheetCompletionBlock)(UIActionSheetAction action, NSUInteger buttonIndex);
@interface CustomActionSheet ()
@property (nonatomic, copy) ActionSheetCompletionBlock completionBlock;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) NSMutableArray *otherButtons;
@property (nonatomic, strong) UIView *superView;
@property (nonatomic, assign) NSUInteger selectedButtonIndex;
@property (nonatomic, assign) NSUInteger cancelButtonIndex;
@property (nonatomic, strong) InactiveView *inactiveView;
@property (nonatomic, assign) BOOL shouldSlideFromTop;
@property (nonatomic, strong) UIImageView *backgroundView;
@end

@implementation CustomActionSheet

- (void)dealloc {
    
    self.titleLabel = nil;
    self.cancelButton = nil;
    self.otherButtons = nil;
    self.superView = nil;
    self.inactiveView = nil;
    self.backgroundView = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (id)initWithTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSArray *)otherButtonTitles {
    
    self = [super init];
    if (self) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onOrientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        
        self.backgroundColor = [UIColor whiteColor];
        self.layer.cornerRadius = 5.f;
        
        self.cancelButtonIndex = NSUIntegerMax;
        
        self.otherButtons = [@[] mutableCopy];
        
        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.text = title;
        self.titleLabel.font = [UIFont boldSystemFontOfSize:18];
        self.titleLabel.textColor = [UIColor darkTextColor];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.backgroundColor = [UIColor clearColor];
        self.titleLabel.numberOfLines = NSIntegerMax;
        [self addSubview:self.titleLabel];
        
        self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.cancelButton setTitle:cancelButtonTitle forState:UIControlStateNormal];
        [self.cancelButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18.f]];
        [self.cancelButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [self.cancelButton addTarget:self action:@selector(onCancelButton:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.cancelButton];

        self.backgroundView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.backgroundView.image = [UIImage imageNamed:@"contactInfoView_header_background.png"];
        [self addSubview:self.backgroundView];
        self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self sendSubviewToBack:self.backgroundView];
        
        self.inactiveView = [[InactiveView alloc] init];
        self.inactiveView.actionSheet = self;
        
        for (NSString *title in otherButtonTitles) {
            
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            [button setTitle:title forState:UIControlStateNormal];
            [button.titleLabel setFont:[UIFont boldSystemFontOfSize:18.f]];
            [button setTitleColor:[UIColor darkTextColor] forState:UIControlStateNormal];
            [button addTarget:self action:@selector(onOtherButton:) forControlEvents:UIControlEventTouchUpInside];
            button.backgroundColor = [UIColor whiteColor];
            button.layer.cornerRadius = 5.f;
            
            [self addSubview:button];
            [self.otherButtons addObject:button];
        }
    }
    
    return self;
}

- (id)initWithTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelButtonTitle destructiveButtonTitle:(NSString *)destructiveButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...{
    
    self = [super init];
    if (self) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onOrientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        
        self.backgroundColor = [UIColor whiteColor];
        self.layer.cornerRadius = 5.f;
        
        self.cancelButtonIndex = NSUIntegerMax;
        
        self.otherButtons = [@[] mutableCopy];
        
        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.text = title;
        self.titleLabel.font = [UIFont boldSystemFontOfSize:18];
        self.titleLabel.textColor = [UIColor lightTextColor];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.backgroundColor = [UIColor clearColor];
        self.titleLabel.numberOfLines = NSIntegerMax;
        [self addSubview:self.titleLabel];
        
        self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.cancelButton setTitle:cancelButtonTitle forState:UIControlStateNormal];
        [self.cancelButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18.f]];
        [self.cancelButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [self.cancelButton addTarget:self action:@selector(onCancelButton:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.cancelButton];
        
        self.backgroundView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.backgroundView.image = [UIImage imageNamed:@"contactInfoView_header_background.png"];
        [self addSubview:self.backgroundView];
        self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self sendSubviewToBack:self.backgroundView];
        
        self.inactiveView = [[InactiveView alloc] init];
        
        va_list args;
        va_start(args, otherButtonTitles);
        for (NSString *title = otherButtonTitles; title != nil; title = va_arg(args, NSString *)) {
            
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            [button setTitle:title forState:UIControlStateNormal];
            [button.titleLabel setFont:[UIFont boldSystemFontOfSize:18.f]];
            [button setTitleColor:[UIColor darkTextColor] forState:UIControlStateNormal];
            [button addTarget:self action:@selector(onOtherButton:) forControlEvents:UIControlEventTouchUpInside];
            button.backgroundColor = [UIColor whiteColor];
            button.layer.cornerRadius = 5.f;
            
            [self addSubview:button];
            [self.otherButtons addObject:button];
        }
        va_end(args);
    }
    
    return self;
}

- (void)showAsHintFromView:(UIView *)view withPassthroughViews:(NSArray *)views actionBlock:(void(^)(UIActionSheetAction action, NSUInteger buttonIndex))dissmissBlock {
    
    self.shouldSlideFromTop = YES;
    
    self.titleLabel.font = [UIFont systemFontOfSize:16.f];
    
    self.completionBlock = dissmissBlock;
    
    self.inactiveView.passThroughViews = views;
    
    self.backgroundColor = [UIColor clearColor];
    self.inactiveView.backgroundColor = [UIColor clearColor];
    [self.inactiveView addTarget:self action:@selector(onBackgroundTap:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.inactiveView showInView:((AppDelegate *)[UIApplication sharedApplication].delegate).navigationController.view];
    [self showInView:((AppDelegate *)[UIApplication sharedApplication].delegate).window/*navigationController.view*/];
}

- (void)showAsHint:(UIView *)view withPassThroughFrame:(CGRect)passThroughFrame block:(void(^)(UIActionSheetAction action, NSUInteger buttonIndex))dissmissBlock {
    
    self.shouldSlideFromTop = YES;
    
    self.titleLabel.font = [UIFont systemFontOfSize:16.f];
    
    self.completionBlock = dissmissBlock;
    
    self.backgroundColor = [UIColor clearColor];
    self.inactiveView.backgroundColor = [UIColor clearColor];
    [self.inactiveView addTarget:self action:@selector(onBackgroundTap:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.inactiveView showInView:((AppDelegate *)[UIApplication sharedApplication].delegate).navigationController.view];
    [self showInView:((AppDelegate *)[UIApplication sharedApplication].delegate).navigationController.view];
    
    self.inactiveView.passThroughFrame = passThroughFrame;
}

- (void)showInView:(UIView *)view block:(void(^)(UIActionSheetAction action, NSUInteger buttonIndex))dissmissBlock {
    
    [self.backgroundView removeFromSuperview];
    
    self.completionBlock = dissmissBlock;
    
    [self.inactiveView showInView:((AppDelegate *)[UIApplication sharedApplication].delegate).navigationController.view];
    
    [self showInView:((AppDelegate *)[UIApplication sharedApplication].delegate).navigationController.view];
}

- (void)dismiss {
    
    self.selectedButtonIndex = self.cancelButtonIndex;
    
    [self slideOutAnimated:NO];
    
    [self.inactiveView hide];
}

- (NSString *)buttonTitleAtIndex:(NSInteger)index {
    
    if (index == self.cancelButtonIndex) {
        return self.cancelButton.titleLabel.text;
    }
    
    return ((UIButton *)self.otherButtons[index]).titleLabel.text;
}

- (void)showInView:(UIView *)view {
    
    self.superView = view;
    [self layoutSubviews];
    
    self.inactiveView.passThroughViews = @[view];//@[self];
    [self slideIn];
}

- (void)setPassthroughFrame:(CGRect)frame {

    self.inactiveView.passThroughFrame = frame;
}

#pragma mark -
#pragma mark UIView overridings
#pragma mark -

- (void)layoutSubviews {
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    
    CGRect textRect = [self.titleLabel.text boundingRectWithSize:CGSizeMake([UIScreen mainScreen].bounds.size.width - 30.f, CGFLOAT_MAX)
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                            attributes:@{NSFontAttributeName : self.titleLabel.font,
                                                         NSParagraphStyleAttributeName : paragraphStyle.copy}
                                               context:nil];
    CGSize titleSize = textRect.size;
    
    self.titleLabel.frame = CGRectMake(15.f, (self.shouldSlideFromTop ? 3.f : 15.f), [UIScreen mainScreen].bounds.size.width - 30.f, titleSize.height);
    
    CGFloat yOffset = self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + 3.f;
    
    if (!self.shouldSlideFromTop) {
        
        for (UIButton *button in self.otherButtons) {
            
            button.frame = CGRectMake(15.f, yOffset, [UIScreen mainScreen].bounds.size.width - 30.f, 40.f);
            yOffset += 40.f + 3.f;
            
            UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(5.f, button.frame.size.height - 2.f, button.frame.size.width - 10.f, 1.f)];
            separator.backgroundColor = [UIColor grayColor];
            [button addSubview:separator];
        }
        
        yOffset += 7.f;
        self.cancelButton.frame = CGRectMake(15.f, yOffset, [UIScreen mainScreen].bounds.size.width - 30.f, 40.f);
        
        self.bounds = CGRectMake(0.f, 0.f, [UIScreen mainScreen].bounds.size.width, yOffset + 50.f);
    } else {
        
        self.bounds = CGRectMake(0.f, 0.f, [UIScreen mainScreen].bounds.size.width, yOffset);
        
        self.cancelButton.backgroundColor = [UIColor clearColor];
        [self.cancelButton setTitle:@"" forState:UIControlStateNormal];
        self.cancelButton.frame = self.bounds;
    }
}

#pragma mark -
#pragma mark IBAction methods
#pragma mark -

- (void)onBackgroundTap:(UIButton *)button {
    
    [self onCancelButton:button];
}

- (void)onOtherButton:(UIButton *)button {
    
    self.selectedButtonIndex = [self.otherButtons indexOfObject:button];
    
    [self slideOutAnimated:YES];
    
    [self.inactiveView hide];
}

- (void)onCancelButton:(UIButton *)button {
    
    self.selectedButtonIndex = self.cancelButtonIndex;
    
    [self slideOutAnimated:YES];
    
    [self.inactiveView hide];
}

#pragma mark -
#pragma mark NSNotification observing
#pragma mark -

- (void)onOrientationChanged:(NSNotification *)notification {
    
    [self adjustViewsForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
}

#pragma mark -
#pragma mark private methods
#pragma mark -

- (void)adjustViewsForOrientation:(UIInterfaceOrientation) orientation {
    
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
      
        self.inactiveView.frame = [UIScreen mainScreen].bounds;
        
    } else if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
        
        CGRect frame = [UIScreen mainScreen].bounds;
        CGFloat width = frame.size.height;
        frame.size.height = frame.size.width;
        frame.size.width = width;
        self.inactiveView.frame = frame;
    }
    
    self.center = CGPointMake(self.inactiveView.center.x, self.center.y);
}

- (void)slideIn {
    
    if (self.shouldSlideFromTop) {
        
        //set initial location at bottom of view
        CGRect frame = self.frame;
        frame.origin = CGPointMake(0.0, -self.frame.size.height);
        self.frame = frame;
        [self.superView addSubview:self];
        
        //animate to new location, determined by height of the view in the NIB
        [UIView beginAnimations:@"presentWithSuperview" context:nil];
        [UIView setAnimationDuration:.65];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        frame.origin = CGPointMake(0.0,
                                   65.0);
        
        self.frame = frame;
        [UIView commitAnimations];
    } else {
        
        //set initial location at bottom of view
        CGRect frame = self.frame;
        frame.origin = CGPointMake(0.0, self.superView.bounds.size.height);
        self.frame = frame;
        [self.superView addSubview:self];
        
        //animate to new location, determined by height of the view in the NIB
        [UIView beginAnimations:@"presentWithSuperview" context:nil];
        [UIView setAnimationDuration:.35];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        frame.origin = CGPointMake(0.0,
                                   self.superView.bounds.size.height - self.bounds.size.height);
        
        self.frame = frame;
        [UIView commitAnimations];
    }
    
}

- (void) slideOutAnimated:(BOOL)animated {
    
    if (self.shouldSlideFromTop) {
        
        if (animated) {
            
            [UIView beginAnimations:@"removeFromSuperviewWithAnimation" context:nil];
            [UIView setAnimationDuration:.35];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
            
            // Set delegate and selector to remove from superview when animation completes
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
        }
        
        
        // Move this view to bottom of superview
        CGRect frame = self.frame;
        frame.origin = CGPointMake(0.0, -self.superView.bounds.size.height);
        self.frame = frame;
        
        if (animated) {
            
            [UIView commitAnimations];
        }
        
        if (self.completionBlock) {
            
            self.completionBlock(UIActionSheetActionWillDissmiss, self.selectedButtonIndex);
            if (!animated) {
                [self animationDidStop:@"removeFromSuperviewWithAnimation" finished:@YES context:nil];
            }
        }
    } else {
     
        if (animated) {
            
            [UIView beginAnimations:@"removeFromSuperviewWithAnimation" context:nil];
            [UIView setAnimationDuration:.35];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
            
            // Set delegate and selector to remove from superview when animation completes
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
        }
        
        // Move this view to bottom of superview
        CGRect frame = self.frame;
        frame.origin = CGPointMake(0.0, self.superView.bounds.size.height);
        self.frame = frame;
        
        if (animated) {
            
            [UIView commitAnimations];
        }
        
        if (self.completionBlock) {
            self.completionBlock(UIActionSheetActionWillDissmiss, self.selectedButtonIndex);
            if (!animated) {
                [self animationDidStop:@"removeFromSuperviewWithAnimation" finished:@YES context:nil];
            }
        }
    }
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    
    if ([animationID isEqualToString:@"removeFromSuperviewWithAnimation"]) {
        
        [self removeFromSuperview];
        
        if (self.completionBlock) {
            self.completionBlock(UIActionSheetActionDidDissmiss, self.selectedButtonIndex);
        }
        
        self.superView = nil;
    }
}

@end
