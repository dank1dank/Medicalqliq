//
//  CallInProgressView.h
//  qliq
//
//  Created by Paul Bar on 1/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CellPhoneView.h"

@protocol CallInProgressViewDelegate <NSObject>

-(void) endCallButtonPressed;

@end

@interface CallInProgressView : UIView
{
    CellPhoneView *cellPhoneView;
    UIImageView *cellPhoneBackground;
    UIButton *endCallButton;
}

@property (nonatomic, assign) id<CallInProgressViewDelegate> delegate;

@end
