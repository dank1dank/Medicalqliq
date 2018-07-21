//
//  DetailOnCallViewController.h
//  qliq
//
//  Created by Valerii Lider on 07/09/15.
//
//

#import <UIKit/UIKit.h>

@class OnCallGroup;

@interface DetailOnCallViewController : UIViewController

@property (nonatomic, strong) OnCallGroup *onCallGroup;

@property (nonatomic, strong) NSString *backButtonTitleString;

@end
