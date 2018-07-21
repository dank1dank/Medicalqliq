//
//  QliqActionSheet.m
//  qliq
//
//  Created by Valerii Lider on 5/5/14.
//
//

#import "QliqActionSheet.h"

#import "AppDelegate.h"
#import "QliqNavigationController.h"

@interface QliqInactiveView : UIButton
@property (nonatomic, strong) NSArray *passThroughViews;
@property (nonatomic, assign) CGRect passThroughFrame;
@property (nonatomic, weak) QliqActionSheet *actionSheet;
@end

@implementation QliqInactiveView

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
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
        CGFloat width = screenBounds.size.height;
        screenBounds.size.height = screenBounds.size.width;
        screenBounds.size.width = width;
    }
    self.frame = screenBounds;
    [view addSubview:self];
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
@interface QliqActionSheet () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, copy) ActionSheetCompletionBlock completionBlock;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) NSMutableArray *otherButtons;
@property (nonatomic, strong) UIView *superView;
@property (nonatomic, assign) NSUInteger selectedButtonIndex;
@property (nonatomic, assign) NSUInteger cancelButtonIndex;
@property (nonatomic, strong) QliqInactiveView *inactiveView;
@property (nonatomic, assign) BOOL shouldSlideFromTop;
@property (nonatomic, strong) UIImageView *backgroundView;
@property (nonatomic, strong) UITableView *buttonsTable;
@property (nonatomic, weak) UIView *headerView;
@end

@implementation QliqActionSheet

- (void)dealloc {
    
    self.titleLabel = nil;
    self.cancelButton = nil;
    self.otherButtons = nil;
    self.superView = nil;
    self.inactiveView = nil;
    self.backgroundView = nil;
    self.buttonsTable = nil;
    self.headerView = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (id)initWithTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelButtonTitle destructiveButtonTitle:(NSString *)destructiveButtonTitle actionSheetHeader:(UIView *)sheetHeader otherButtonTitles:(NSArray *)otherButtonTitles{
    
    self = [super init];
    if (self) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onOrientationStateChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onOrientationStateChanged:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onOrientationStateChanged:) name:kDeviceLockStatusChangedNotificationName object:nil];
        
        self.backgroundColor = [UIColor whiteColor];
        self.layer.cornerRadius = 5.f;
        
        self.cancelButtonIndex = NSUIntegerMax;
        
        self.otherButtons = [@[] mutableCopy];
        
        if (title)
        {
            self.titleLabel = [[UILabel alloc] init];
            self.titleLabel.text = title;
            self.titleLabel.font = [UIFont boldSystemFontOfSize:18];
            self.titleLabel.textColor = [UIColor lightGrayColor];
            self.titleLabel.textAlignment = NSTextAlignmentCenter;
            self.titleLabel.backgroundColor = [UIColor clearColor];
            self.titleLabel.numberOfLines = NSIntegerMax;
            [self addSubview:self.titleLabel];
        }
        
        self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.cancelButton setTitle:cancelButtonTitle forState:UIControlStateNormal];
        [self.cancelButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18.f]];
        [self.cancelButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [self.cancelButton addTarget:self action:@selector(onCancelButton:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.cancelButton];
        
        CGRect screenBounds = [UIScreen mainScreen].bounds;
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
            CGFloat width = screenBounds.size.height;
            screenBounds.size.height = screenBounds.size.width;
            screenBounds.size.width = width;
        }
        self.backgroundView = [[UIImageView alloc] initWithFrame:screenBounds];
        self.backgroundView.image = [UIImage imageNamed:@"contactInfoView_header_background.png"];
        [self addSubview:self.backgroundView];
        self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.backgroundView.contentMode = UIViewContentModeScaleToFill;
        [self sendSubviewToBack:self.backgroundView];
        
        self.inactiveView = [[QliqInactiveView alloc] init];
        
        if (sheetHeader)
            self.headerView = sheetHeader;
        self.otherButtons = [otherButtonTitles mutableCopy];
        self.buttonsTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        self.buttonsTable.separatorColor = [UIColor grayColor];
        self.buttonsTable.dataSource = self;
        self.buttonsTable.delegate = self;
        if ([self.buttonsTable respondsToSelector:@selector(setSeparatorInset:)]) {
            [self.buttonsTable setSeparatorInset:UIEdgeInsetsZero];
        }
        [self addSubview:self.buttonsTable];
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
    [self showInView:((AppDelegate *)[UIApplication sharedApplication].delegate).navigationController.view];
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
    
    return self.otherButtons[index];
}

- (void)showInView:(UIView *)view {
    
    self.superView = view;
    [self layoutSubviews];
    
    self.inactiveView.passThroughViews = @[self];
    [self slideIn];
}

- (void)setPassthroughFrame:(CGRect)frame {
    
    self.inactiveView.passThroughFrame = frame;
}

#pragma mark -
#pragma mark Table Methods
#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.otherButtons.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40.f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *buttonCellID = @"buttonCellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:buttonCellID];
    if (nil == cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:buttonCellID];
    }
    NSString *title = self.otherButtons[indexPath.row];
    cell.textLabel.text = title;
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    [cell.textLabel setFont:[UIFont boldSystemFontOfSize:18.f]];
    [cell.textLabel setTextColor:[UIColor darkTextColor]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedButtonIndex = indexPath.row;
    
    [self slideOutAnimated:YES];
    
    [self.inactiveView hide];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark -
#pragma mark UIView overridings
#pragma mark -

- (void)layoutSubviews {
    
    if (self.titleLabel == nil) {
        self.titleLabel = [[UILabel alloc] init];
    }
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    BOOL isPortrait = YES;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
        isPortrait = NO;
        CGFloat width = screenBounds.size.height;
        screenBounds.size.height = screenBounds.size.width;
        screenBounds.size.width = width;
    }
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    
    CGRect textRect = [self.titleLabel.text boundingRectWithSize:CGSizeMake(screenBounds.size.width - 30.f, CGFLOAT_MAX)
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:@{NSFontAttributeName : self.titleLabel.font,
                                                   NSParagraphStyleAttributeName : paragraphStyle.copy}
                                         context:nil];
    CGSize titleSize = textRect.size;
    
    self.titleLabel.frame = CGRectMake(15.f, (self.shouldSlideFromTop ? 3.f : 15.f), screenBounds.size.width - 30.f, titleSize.height);
    CGFloat yOffset = self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + 3.f;
    if (!self.shouldSlideFromTop) {
        if (self.headerView)
        {
            yOffset += 2.f;
            CGRect headerViewFrame = self.headerView.frame;
            headerViewFrame.origin.y = yOffset;
            self.headerView.frame = headerViewFrame;
            [self addSubview:self.headerView];
            yOffset += self.headerView.frame.size.height;
        }
        self.backgroundView.frame = screenBounds;
        float tableMaxHeight = (isPortrait ? (200.f + yOffset + 50.f) : yOffset + 120.f + 50.f);//(isPortrait ? screenBounds.size.height : 480.f) - yOffset - 40.f - 200.f;
        CGFloat tableHeight = MIN(self.otherButtons.count * 40.f, tableMaxHeight);
        self.buttonsTable.frame = CGRectMake(0.f, yOffset, screenBounds.size.width, tableHeight);
        [self.buttonsTable reloadData];
        self.buttonsTable.scrollEnabled = (self.buttonsTable.contentSize.height > tableMaxHeight);
        yOffset += tableHeight;
        self.cancelButton.frame = CGRectMake(15.f, yOffset, screenBounds.size.width - 30.f, 40.f);
        
        self.bounds = CGRectMake(0.f, 0.f, screenBounds.size.width, yOffset + 50.f);
    } else {
        
        self.bounds = CGRectMake(0.f, 0.f, screenBounds.size.width, yOffset);
        
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

- (void)onOrientationStateChanged:(NSNotification *)notification {
    
    [self dismiss];
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
