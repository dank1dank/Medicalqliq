//
//  RegisterUserWebViewViewController.h
//  qliq
//
//  Created by Valerii Lider on 1/20/15.
//
//

#import <UIKit/UIKit.h>

@interface RegisterUserWebViewViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIWebView *contentWebView;

- (void)loadLink:(NSString*)link;

@end
