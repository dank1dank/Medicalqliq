//
//  QliqNavigationController.m
//  qliq
//
//  Created by Aleksey Garbarev on 20.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
//#import "UIToolbar+Background.h"

#import "QliqNavigationController.h"

//#import "UIView_LayoutCallback.h"

#import "QliqBaseViewController.h"

#import <QuartzCore/QuartzCore.h>
#import "QliqSip.h"

#define kStatusBarHeight [self statusbarFrame].size.height

@interface PushAnimator : NSObject <UIViewControllerAnimatedTransitioning>
@end

@interface PopAnimator : NSObject <UIViewControllerAnimatedTransitioning>
@end

@implementation PushAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.25;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController* toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController* fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    [[transitionContext containerView] addSubview:toViewController.view];
    __block CGRect frame = toViewController.view.frame;
    frame.origin.x = [UIScreen mainScreen].bounds.size.width;
    toViewController.view.frame = frame;
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        frame.origin.x = 0;
        toViewController.view.frame = frame;
        frame.origin.x = -[UIScreen mainScreen].bounds.size.width;
        fromViewController.view.frame = frame;
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
    
}

@end

@implementation PopAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.25;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController* toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController* fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    [[transitionContext containerView] addSubview:toViewController.view];
    __block CGRect frame = toViewController.view.frame;
    frame.origin.x = -[UIScreen mainScreen].bounds.size.width;
    toViewController.view.frame = frame;
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        frame.origin.x = 0;
        toViewController.view.frame = frame;
        
        frame = [UIScreen mainScreen].applicationFrame;
        frame.origin.y = 64;
        frame.origin.x += frame.size.width;
        fromViewController.view.frame = frame;
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
    
}

@end

@interface QliqNavigationController ()<UINavigationControllerDelegate>

@property (nonatomic, strong) PushAnimator *pushAnimator;
@property (nonatomic, strong) PopAnimator *popAnimator;

- (void) layoutToolbar;

@end

@implementation QliqNavigationController{
    __unsafe_unretained id <QliqTabbarProtocol> tabbar;
    
    __unsafe_unretained UIViewController * rootViewController;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)setTabbarController:(id<QliqTabbarProtocol>) _tabbar{
    tabbar = _tabbar;
}

- (void) applicationBecomeActive{
    
    //This is a kind of hack. I assume that dispatch_async adds new task at end of main_queue. So layout called after all UI tasks on main_queue
    dispatch_async(dispatch_get_main_queue(), ^{
        [self layoutToolbar];   
    });
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)contex{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self layoutToolbar];
    });
}


- (void) dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIApplication sharedApplication] removeObserver:self forKeyPath:@"statusBarHidden"];
}

- (id) initWithRootViewController:(UIViewController *)_rootViewController andToolbarHidden:(BOOL) toolbarHidden{
    UIViewController * tmpRootViewController = [[UIViewController alloc] init];
    
    self = [super initWithRootViewController:tmpRootViewController];
    if (self){
        self.toolbarHidden = toolbarHidden;
        [self pushViewController:_rootViewController animated:NO];
        rootViewController = _rootViewController;
        
//        self.popAnimator = [[PopAnimator alloc] init];
        self.pushAnimator = [[PushAnimator alloc] init];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.toolbarHidden = NO;
        // Custom initialization
//        [self.toolbar setBackgroundImage:[UIImage imageNamed:@"toolbarBackground"]];
        
        //Add events listening
        self.delegate = self;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[UIApplication sharedApplication] addObserver:self forKeyPath:@"statusBarHidden" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (id) initWithRootViewController:(UIViewController *)_rootViewController{
    return [self initWithRootViewController:_rootViewController andToolbarHidden:NO];
}

//- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated{
//    
//    return [self popToRootViewControllerAnimated:animated]; //[self popToViewController:rootViewController animated:animated];
//}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
//        [self.toolbar setBackgroundImage:[UIImage imageNamed:@"toolbarBackground"]];

        
        //Add events listening
        self.delegate = self;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[UIApplication sharedApplication] addObserver:self forKeyPath:@"statusBarHidden" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (CGRect) statusbarFrame
{
    UIView *rootView = self.view;
    CGRect statusBarFrame = [rootView convertRect:[[UIApplication sharedApplication] statusBarFrame] fromView:rootView.window];
    statusBarFrame.size.height = 20.f;
    return statusBarFrame;
}

- (void) layoutToolbar{

    [UIView setAnimationsEnabled:NO];
    if ([tabbar respondsToSelector:@selector(heightForTabbarInNavigationController:)]){
        
        CGFloat tabbarHeight = [tabbar heightForTabbarInNavigationController:self];
        
        /* Layout wrapper view */
        UIView *wrapperView = [self.visibleViewController.view superview];
        CGRect wrapperFrame = wrapperView.frame;
        wrapperFrame.size.height = [wrapperView superview].bounds.size.height - wrapperFrame.origin.y;
        wrapperFrame.size.height -= self.toolbarHidden ? 0 : tabbarHeight - 64.f;
        wrapperView.frame = wrapperFrame;
        
        /* Layout toolbar */
        CGRect frame = self.toolbar.frame;
        frame.origin.y = [wrapperView superview].bounds.size.height - tabbarHeight;
        frame.size.height = tabbarHeight;
        self.toolbar.frame = frame;
        
        [self.visibleViewController.view layoutSubviews];
    }
    
    CGRect navigationBarFrame = self.navigationBar.frame;
    navigationBarFrame.origin.y = kStatusBarHeight;
    self.navigationBar.frame = navigationBarFrame;
    [UIView setAnimationsEnabled:YES];
}


- (void)viewDidLayoutSubviews{
    [self layoutToolbar];
}


#pragma mark - Instance methods

- (void) switchToViewControllerByClass:(Class) _class andTitle:(NSString *) title animated:(BOOL) _animated initializationBlock:(UIViewController *(^)(void))initBlock additionSetups:(void(^)(UIViewController *))setupsBlock{

    if ([self.visibleViewController isKindOfClass:_class]) {
        return;
    }
    
    UIViewController * selectedViewController = nil;
    for (UIViewController * viewcontroller in [self viewControllers]) {
        if ([viewcontroller isKindOfClass:_class]){
            
            if (title && [viewcontroller respondsToSelector:@selector(controllerName)]){
                if ([[viewcontroller valueForKey:@"controllerName"] isEqualToString:title]){
                    selectedViewController =  viewcontroller;
                    break;
                }
            }else{
                selectedViewController =  viewcontroller;
                break;
            }

        }
    }
    if (!selectedViewController){
        if (initBlock){
            selectedViewController = initBlock();
        }else{
            selectedViewController = [[_class alloc] initWithNibName:nil bundle:nil];
        }
        if (title &&  [selectedViewController respondsToSelector:@selector(setControllerName:)]){
            [selectedViewController setValue:title forKey:@"controllerName"];
        }
        if (setupsBlock) setupsBlock(selectedViewController);
        [self pushViewController:selectedViewController animated:_animated];
    }else{
        if (setupsBlock) setupsBlock(selectedViewController);
        [self popToViewController:selectedViewController animated:_animated];
    }
    
}

- (void) switchToViewControllerByClass:(Class) _class animated:(BOOL) _animated initializationBlock:(UIViewController *(^)(void))initBlock additionSetups:(void(^)(UIViewController *))setupsBlock{
    [self switchToViewControllerByClass:_class andTitle:nil animated:_animated initializationBlock:initBlock additionSetups:setupsBlock];
}

- (void) switchToViewControllerByClass:(Class) _class animated:(BOOL) _animated initializationBlock:(UIViewController *(^)(void))initBlock{
    [self switchToViewControllerByClass:_class animated:_animated initializationBlock:initBlock additionSetups:nil];
}

- (void) switchToViewControllerByClass:(Class) _class animated:(BOOL) _animated{
    [self switchToViewControllerByClass:_class animated:_animated initializationBlock:nil];    
}

#pragma mark - UINavigationController Delegate

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController*)fromViewController
                                                 toViewController:(UIViewController*)toViewController
{
    if (operation == UINavigationControllerOperationPush) {
        return self.pushAnimator;
    } else if (operation == UINavigationControllerOperationPop) {
        return self.popAnimator;
    }
    return nil;
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
    DDLogSupport(@"%@ did appear",[viewController class]);
    [self layoutToolbar];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
    
    DDLogSupport(@"%@ will appear",[viewController class]);
    if ([tabbar respondsToSelector:@selector(qliqNavigationController:didChangeVisibleController:)]){
        [tabbar qliqNavigationController:self didChangeVisibleController:viewController];        
    }
    
    [self layoutToolbar];
}

#pragma mark -


- (void)viewDidLoad{
    
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}


- (void) setToolbarHidden:(BOOL)hidden animated:(BOOL)animated{
    
    [super setToolbarHidden:hidden animated:animated];

    [self layoutToolbar];
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    if ([self.topViewController respondsToSelector:@selector(shouldAutorotateToInterfaceOrientation:)]) {
        return [self.visibleViewController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
    } else {
        return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown; \
    }
}


-(BOOL)shouldAutorotate{
    
    BOOL shouldAutorotate = YES;
    
    if ([self.visibleViewController respondsToSelector:@selector(shouldAutorotate)]) {
        shouldAutorotate = [self.visibleViewController shouldAutorotate];
    }
    
    return shouldAutorotate;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    UIInterfaceOrientationMask supportedInterfaceOrientations = UIInterfaceOrientationMaskAll;
    
    if ([self.visibleViewController respondsToSelector:@selector(supportedInterfaceOrientations)]) {
        supportedInterfaceOrientations = [self.visibleViewController supportedInterfaceOrientations];
    }
    
    return supportedInterfaceOrientations;
}


@end
