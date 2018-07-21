//
//  FeedBackViewController.h
//  qliq
//
//  Created by Valeriy Lider on 24.11.14.
//
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ReportType) {
    ReportTypeError,
    ReportTypeFeedback
};

@interface FeedBackSupportViewController : UIViewController

@property (nonatomic, assign) ReportType reportType;

@end
