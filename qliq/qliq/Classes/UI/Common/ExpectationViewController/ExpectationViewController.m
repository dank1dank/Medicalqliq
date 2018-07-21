//
//  ExpectationViewController.m
//  qliq
//
//  Created by Aleksey Garbarev on 12.09.13.
//
//

#import "ExpectationViewController.h"
//#import "ConversationListViewController.h"
#import "QliqSip.h"
#import "NotificationUtils.h"


//static const NSInteger kExpectationMinPendingMessages = 10;

@interface ExpectationViewController ()

@end

@implementation ExpectationViewController {
    UIProgressView *progressView;
    NSTimer *updateTimer;
    QliqSip *sip;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
       // DDLogSupport(@"Downloading messages created. Callstack: %@",[NSThread callStackSymbols]);
        sip = [QliqSip sharedQliqSip];
    }
    return self;
}

- (void)dealloc
{
    [self removeNotifications];
}

- (void) viewWillAppear:(BOOL)animated
{
    DDLogSupport(@"downloading messages view appears");
    DDLogSupport(@"navigationstack: %@",self.navigationController.viewControllers);
    
    [self installNotificationsIfNeeded];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self removeNotifications];
    [super viewWillDisappear:animated];
}

- (void) didReceiveAllMessages
{
    progressView.progress = 1.0f;

    [self stopUpdating];
    [self onSkip];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithRed:0.0 green:(65.0/255.0) blue:(106.0/255.0) alpha:1.0];
    
    QliqLabel *label = [[QliqLabel alloc] initWithFrame:CGRectMake(20, 100, self.view.bounds.size.width - 40, 35) style:QliqLabelStyleBold];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"Downloading messages. Please wait";
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:label];
    
    progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    progressView.frame = CGRectMake(label.frame.origin.x, CGRectGetMaxY(label.frame) + 15, label.frame.size.width, 20);
    progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:progressView];
    
    [self setupSkipButton];
    
    [self startUpdating];
}


- (void) setupSkipButton
{
    CGFloat buttonWidth = 100;
    CGFloat buttonHeight = 44;
    CGRect buttonFrame = CGRectMake((self.view.bounds.size.width - buttonWidth)/2, CGRectGetMaxY(progressView.frame) + 15, buttonWidth, buttonHeight);
    QliqButton *skipButton = [[QliqButton alloc] initWithFrame:buttonFrame style:QliqButtonStyleRoundedBlue];
    [skipButton setTitle:@"Skip" forState:UIControlStateNormal];
    [skipButton addTarget:self action:@selector(onSkip) forControlEvents:UIControlEventTouchUpInside];
    skipButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.view addSubview:skipButton];
}

- (void) updateProgress
{
    CGFloat progress = 0;

    if (sip.pendingMessagesCount > 0) {
        progress = sip.receivedMessagesCount /(CGFloat)sip.pendingMessagesCount;
    }
    
    progressView.progress = progress;
    
    if (progress >= 1) {
        [self didReceiveAllMessages];
    }
}

- (void) startUpdating
{
    updateTimer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:0.1f target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:updateTimer forMode:NSDefaultRunLoopMode];
}

- (void) stopUpdating
{
    [updateTimer invalidate];
    updateTimer = nil;
}

- (void) onSkip
{
    /*
    [self.navigationController switchToViewControllerByClass:[ConversationListViewController class] animated:YES];
 
    __weak ExpectationViewController *weakSelf = self;
    
    double delayInSeconds = .35;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        NSMutableArray *controllers = [weakSelf.navigationController.viewControllers mutableCopy];
        
        [controllers removeObjectIdenticalTo:weakSelf];
        [weakSelf.navigationController setViewControllers:controllers animated:NO];
        
        [weakSelf stopUpdating];
        [weakSelf removeNotifications];
    });
     */
}

#pragma mark - Notifications logic

+ (BOOL) isNeedWaitForMessages
{
//    return [[QliqSip sharedQliqSip] pendingMessagesCount] >= kExpectationMinPendingMessages;
    // KK: Don't show expectation view controller
    return FALSE;
}

- (void) installNotificationsIfNeeded
{
    if ([[self class] isNeedWaitForMessages]) {
        [self registerForNotification:SipMessageDumpFinishedNotification selector:@selector(didReceiveAllMessages)];
    }
}

- (void) removeNotifications
{
    [self unregisterForNotifications];
}


@end
