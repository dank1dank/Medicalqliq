//
//  NavBarInCallStateView.h
//  qliq
//
//  Created by Paul Bar on 3/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol InCallStateViewDelegate

- (void)inCallStateViewPressed;

@end


@interface NavBarInCallStateView : UIView
{
    UIView *bg;
    UILabel *label;
    CAGradientLayer *gradient;
    
    UIGestureRecognizer *tapGestureRecognizer;
}

- (void)startPulsing;
- (void)stopPulsing;

@property (nonatomic, assign) id<InCallStateViewDelegate> delegate;

@end
