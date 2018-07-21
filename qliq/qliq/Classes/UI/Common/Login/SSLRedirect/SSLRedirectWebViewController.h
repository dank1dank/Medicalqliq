//
//  SSLRedirectWebViewController.h
//  qliq
//
//  Created by developer on 11/3/16.
//
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>


@interface SSLRedirectWebViewController : UIViewController 

@property (nonatomic, copy) VoidBlock onBackBlock;
@property (nonatomic, strong) NSString *redirectUrlString;

@end
