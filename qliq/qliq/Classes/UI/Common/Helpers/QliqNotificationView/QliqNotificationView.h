//
//  QliqNotificationView.h
//  qliq
//
//  Created by Valerii Lider on 28/10/15.
//
//

#import <UIKit/UIKit.h>
#import "ACPDownloadView.h"

@interface QliqNotificationView : UIView

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (nonatomic, strong) ACPDownloadView *activityView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *avatarHeight;
@property (nonatomic, assign) NSInteger converationId;

- (void)present;
- (void)presentForOnCall;
- (void)removeNotificationView;
- (void)presentSendingMessageFailed;

@end
