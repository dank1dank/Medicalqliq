//
//  RegisterUserWebViewViewController.m
//  qliq
//
//  Created by Valerii Lider on 1/20/15.
//
//

#import "RegisterUserWebViewViewController.h"
#import "UIDevice-Hardware.h"

@interface RegisterUserWebViewViewController () <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *backButtonView;
/*Constraint for iPhone X*/
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backgroundViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backgroundViewTopConstraint;


@end

@implementation RegisterUserWebViewViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        [self initialization];
    }
    return self;
}

- (void)dealloc {
    self.contentWebView = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /*Change constraint for iPhone X*/
    __block __weak typeof(self) weakSelf = self;
    dispatch_async_main(^{
        isIPhoneX {
            weakSelf.backgroundViewBottomConstraint.constant = weakSelf.backgroundViewBottomConstraint.constant -35.0f;
            weakSelf.backgroundViewTopConstraint.constant = weakSelf.backgroundViewTopConstraint.constant - 44.0f;
            [weakSelf.view layoutIfNeeded];
        }
    });
    
    [self loadLink:kLinkRegistration];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc]
                                             initWithTarget:self action:@selector(onBack:)];
    // Specify that the gesture must be a single tap
    tapRecognizer.numberOfTapsRequired = 1;
    
    // Add the tap gesture recognizer to the view
    [self.backButtonView  addGestureRecognizer:tapRecognizer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Public -

- (void)loadLink:(NSString*)link
{
    NSURL *url = [NSURL URLWithString:link];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [self.contentWebView loadRequest:requestObj];
}

#pragma mark - Private -

- (void)initialization
{
    self.contentWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.contentWebView.scalesPageToFit     = YES;
}

#pragma mark - Action -

- (IBAction)onBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
    
    /*
    NSURL    *currentURL  = [self.contentWebView.request URL];
    NSString *currentLink = [[currentURL absoluteString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    if ([currentLink isEqualToString:kLinkRegistration]) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    else {
        [self.contentWebView goBack];
    }
     */
}

#pragma mark - Delegate -

#pragma mark * UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    BOOL isLoading = self.contentWebView.isLoading;
    if (isLoading) {
        [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    __weak __block typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        BOOL isLoading = weakSelf.contentWebView.isLoading;
        if (!isLoading) {
            [SVProgressHUD dismiss];
        }
    });
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
//    NSURL    *currentURL  = [request URL];
//    NSString *currentLink = [ [currentURL absoluteString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding ];
    
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    DDLogSupport(@"Error loading document: %@",error);
    
    [SVProgressHUD dismiss];
    
    UIAlertView_Blocks *alertView = [[UIAlertView_Blocks alloc] initWithTitle:NSLocalizedString(@"1023-TextError", nil)
                                                                      message:[error localizedDescription]
                                                                     delegate:nil
                                                            cancelButtonTitle:NSLocalizedString(@"1-ButtonOK", nil)
                                                            otherButtonTitles:nil];
    [alertView showWithDissmissBlock:NULL];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
