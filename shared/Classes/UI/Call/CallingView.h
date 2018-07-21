//
//  CallingView.h
//  qliq
//
//  Created by Paul Bar on 1/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CallingViewDelegate <NSObject>

-(void) endCallButtonPressed;

@end

@interface CallingView : UIView
{
    UILabel              * nameLabel;
    UILabel              * phoneLabel;
    UIImageView          * callingImageView;
    UIButton             * endCallButton;
}

@property (nonatomic, assign) id<CallingViewDelegate> delegate;
@property (nonatomic, readonly) UILabel *nameLabel;
@property (nonatomic, readonly) UILabel *phoneLabel;


@end
