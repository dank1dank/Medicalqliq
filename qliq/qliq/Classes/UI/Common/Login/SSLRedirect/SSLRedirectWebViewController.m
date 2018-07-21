//
//  SSLRedirectWebViewController.m
//  qliq
//
//  Created by developer on 11/3/16.
//
//

#import "SSLRedirectWebViewController.h"


@interface SSLRedirectWebViewController () <WKNavigationDelegate, WKUIDelegate, UIWebViewDelegate>

/*
 UI
 */
@property (weak, nonatomic) IBOutlet UIWebView *contentUIWebView;
@property (weak, nonatomic) IBOutlet UIView *rightBarButtonItemView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *frowardButton;

@property (weak, nonatomic) IBOutlet UIImageView *backArrowImageView;

@property (strong, nonatomic) WKWebView *contentWKWebView;

@property (strong, nonatomic) NSLayoutConstraint *topWKWebViewConstraint;
@property (strong, nonatomic) NSLayoutConstraint *botWKWebViewConstraint;
@property (strong, nonatomic) NSLayoutConstraint *leadingWKWebViewConstraint;
@property (strong, nonatomic) NSLayoutConstraint *trailingWKWebViewConstraint;

/*
 Data
 */

@property (strong, nonatomic) NSURLRequest *redirectRequest;
@property (strong, nonatomic) NSURL *redirectURL;

@property (assign, nonatomic) BOOL isFirstLoad;

@end

@implementation SSLRedirectWebViewController

#pragma mark - Life Cycle -

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    self.contentWKWebView = nil;
    self.redirectUrlString = nil;
    self.redirectURL = nil;
    self.onBackBlock = nil;
    self.redirectRequest = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [self performSelector:@selector(showProgressHUD) withObject:nil afterDelay:0.3];
    self.isFirstLoad = YES;
    
    [self configureButtonsTitles];
    
    self.redirectUrlString = self.redirectUrlString ? : @"http://www.google.com";
    self.redirectURL = [NSURL URLWithString:self.redirectUrlString];
    self.redirectRequest = [NSURLRequest requestWithURL:self.redirectURL];
    
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    
    self.contentWKWebView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:configuration];
    
    self.contentWKWebView.navigationDelegate = self;
    self.contentWKWebView.UIDelegate = self;
    
    [self.contentWKWebView loadRequest:self.redirectRequest];
    [self.view addSubview:self.contentWKWebView];
    
    [self setupWKWebViewConstraints];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Util -

- (void)checkIfCurrentlyLoadRedirctedLinkWithCompletion:(void (^)(BOOL isRedirectLinkLoaded))completion
{
    BOOL isRedirectLinkLoaded = self.contentWKWebView.canGoBack;
    completion(isRedirectLinkLoaded);
}

- (void)configureButtonsTitles {
    __weak __block typeof(self) welf = self;
    [self checkIfCurrentlyLoadRedirctedLinkWithCompletion:^(BOOL isRedirectLinkLoaded) {
        if (isRedirectLinkLoaded)
            [welf.backButton setTitle:QliqLocalizedString(@"2399-TitleQliq") forState:UIControlStateNormal];
        else
            [welf.backButton setTitle:QliqLocalizedString(@"49-ButtonBack") forState:UIControlStateNormal];
    }];
}

#pragma mark - Layout -

- (void)setupWKWebViewConstraints {
    
    self.contentWKWebView.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.topWKWebViewConstraint = [NSLayoutConstraint constraintWithItem:self.contentWKWebView
                                                               attribute:NSLayoutAttributeTop
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.contentWKWebView.superview
                                                               attribute:NSLayoutAttributeTop
                                                              multiplier:1.0
                                                                constant:0.0];
    
    self.botWKWebViewConstraint = [NSLayoutConstraint constraintWithItem:self.contentWKWebView.superview
                                                               attribute:NSLayoutAttributeBottom
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.contentWKWebView
                                                               attribute:NSLayoutAttributeBottom
                                                              multiplier:1.0
                                                                constant:0.0];
    
    self.leadingWKWebViewConstraint = [NSLayoutConstraint constraintWithItem:self.contentWKWebView
                                                                   attribute:NSLayoutAttributeLeading
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.contentWKWebView.superview
                                                                   attribute:NSLayoutAttributeLeading
                                                                  multiplier:1.0
                                                                    constant:0.0];
    
    self.trailingWKWebViewConstraint = [NSLayoutConstraint constraintWithItem:self.contentWKWebView.superview
                                                                    attribute:NSLayoutAttributeTrailing
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.contentWKWebView
                                                                    attribute:NSLayoutAttributeTrailing
                                                                   multiplier:1.0
                                                                     constant:0.0];
    
    [NSLayoutConstraint activateConstraints:@[self.topWKWebViewConstraint, self.botWKWebViewConstraint, self.leadingWKWebViewConstraint, self.trailingWKWebViewConstraint]];
    [self.contentWKWebView updateConstraints];
}

#pragma mark - Alerts -

- (void)showAlertAboutErrorWithReason:( NSString * _Nonnull )localizedReason
{
    __weak __block typeof(self) welf = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:QliqLocalizedString(@"2396-TitleRequestFailed")
                                                                             message:localizedReason
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *backToQliq = [UIAlertAction actionWithTitle:QliqLocalizedString(@"2397-TitleBackToQliq")
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction * _Nonnull action) {
                                                           [welf onBack:nil];
                                                       }];
    
    UIAlertAction *reload = [UIAlertAction actionWithTitle:QliqLocalizedString(@"2398-TitleReload")
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * _Nonnull action) {
                                                       [welf scheduleProgressHUD];
                                                       [welf.contentWKWebView reload];
                                                   }];
    [alertController addAction:backToQliq];
    [alertController addAction:reload];
    
    [self.navigationController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - SVProgressHUD -

- (void)scheduleProgressHUD {
    if (!self.isFirstLoad)
        [self performSelector:@selector(showProgressHUD) withObject:nil afterDelay:0.3];
}


- (void)showProgressHUD {
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
}

- (void)skipProgressHUD {
    __weak __block typeof(self) welf = self;
    dispatch_async_main(^{
        if ([SVProgressHUD isVisible]){
            [SVProgressHUD dismiss];
        } else {
            [NSObject cancelPreviousPerformRequestsWithTarget:welf selector:@selector(showProgressHUD) object:nil];
        }
    });
}

#pragma mark - Actions -

- (IBAction)onBack:(id)sender
{
    __weak __block typeof(self) welf = self;
    VoidBlock backToQliqBlock = ^{
        if (welf.onBackBlock)
            welf.onBackBlock();
        else
            [welf.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    };
    
    if ([welf.contentWKWebView canGoBack])
        {
            if (![welf.contentWKWebView goBack])
                backToQliqBlock();
        }
        else
            backToQliqBlock();
}

#pragma mark - Delegates -

#pragma mark * UIWebView Delegate Methods
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    DDLogSupport(@"UIKit -> didFailLoadWithError: %@", [error localizedDescription]);
    if (self.isFirstLoad)
        self.isFirstLoad = NO;
    
    [self skipProgressHUD];
    [self showAlertAboutErrorWithReason:[error localizedDescription]];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    DDLogSupport(@"UIKit -> webViewDidStartLoad:");
    [self scheduleProgressHUD];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    DDLogSupport(@"UIKit -> webViewDidFinishLoad:");
    if (self.isFirstLoad)
        self.isFirstLoad = NO;
    
    [self configureButtonsTitles];
    [self skipProgressHUD];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    DDLogSupport(@"UIKit -> webView:shouldStartLoadWithRequest:navigationType: -> YES");
    return YES;
}

#pragma mark * WKWebView Delegate Methods

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    DDLogSupport(@"WebKit -> webView:decidePolicyForNavigationAction:decisionHandler:");
    decisionHandler(WKNavigationActionPolicyAllow);
    DDLogSupport(@"WebKit -> Allow");
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    DDLogSupport(@"WebKit -> webView:decidePolicyForNavigationResponse:decisionHandler:");
    decisionHandler(WKNavigationResponsePolicyAllow);
    DDLogSupport(@"WebKit -> Allow");
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
    DDLogSupport(@"WebKit -> webView:didStartProvisionalNavigation:");
    [self scheduleProgressHUD];
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
    DDLogSupport(@"WebKit -> webView:didReceiveServerRedirectForProvisionalNavigation:");
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    DDLogSupport(@"WebKit -> webView:didFailProvisionalNavigation:withError: %@", [error localizedDescription]);
    if (self.isFirstLoad)
        self.isFirstLoad = NO;
    [self skipProgressHUD];
    [self showAlertAboutErrorWithReason:[error localizedDescription]];
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation
{
    DDLogSupport(@"WebKit -> webView:didCommitNavigation:");
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
    DDLogSupport(@"WebKit -> webView:didFinishNavigation:");
    if (self.isFirstLoad)
        self.isFirstLoad = NO;
    
    [self configureButtonsTitles];
    [self skipProgressHUD];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    DDLogSupport(@"WebKit -> webView:didFailNavigation:withError: %@", [error localizedDescription]);
    if (self.isFirstLoad)
        self.isFirstLoad = NO;
    [self skipProgressHUD];
    [self showAlertAboutErrorWithReason:[error localizedDescription]];
}

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler
{
    DDLogSupport(@"WebKit -> webView:didReceiveAuthenticationChallenge:completionHandler:");
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    DDLogSupport(@"WebKit -> Default workflow");
}


@end
