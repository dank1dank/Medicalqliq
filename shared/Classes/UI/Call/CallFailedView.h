//
//  CallFailedView.h
//  qliq
//
//  Created by Paul Bar on 1/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CallFailedViewDelegate <NSObject>

-(void) tryAgainButtonPressed;

@end

@interface CallFailedView : UIView
{
    UIButton             * tryAgainButton;
    UILabel              * nameLabel;
    UILabel              * phoneLabel;
    UIImageView          * failedCallImageView;
}

@property (nonatomic, assign) id<CallFailedViewDelegate> delegate;
@property (nonatomic, readonly) UILabel *nameLabel;
@property (nonatomic, readonly) UILabel *phoneLabel;

@end
