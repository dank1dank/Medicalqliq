//
//  MainTabView.h
//  CCiPhoneApp
//
//  Created by Marcin Zbijowski on 27/04/2011.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MainTabView : UIView {

    UIImageView* meGroupSelectedBackground;
    UIImageView* roundsApptsSelectedBackground;
    
    UIButton *_meButton;
    UIButton *_groupButton;
    UIButton *_roundsButton;
    UIButton *_apptsButton;
    UIButton *_chatButton;
    UIButton *_settingsButton;
    
    UILabel *_meLabel;
    UILabel *_groupLabel;
    UILabel *_roundsLabel;
    UILabel *_apptsLabel;
    UILabel *_chatLabel;
    UILabel *_settingsLabel;
    
    NSInteger _badgeValue;
    UIView *_badgeView;
    UIView *_chatBadgeView;
	BOOL _canMeGroupMove;
    
}

@property (nonatomic, retain) UIButton *meButton;
@property (nonatomic, retain) UIButton *groupButton;
@property (nonatomic, retain) UIButton *roundsButton;
@property (nonatomic, retain) UIButton *apptsButton;
@property (nonatomic, retain) UIButton *chatButton;
@property (nonatomic, retain) UIButton *settingsButton;

@property (nonatomic, retain) UILabel *meLabel;
@property (nonatomic, retain) UILabel *groupLabel;
@property (nonatomic, retain) UILabel *roundsLabel;
@property (nonatomic, retain) UILabel *apptsLabel;

@property (nonatomic, assign) NSInteger badgeValue;
@property (nonatomic, assign) NSInteger chatBadgeValue;

@property (nonatomic, assign) BOOL canMeGroupMove;

@end
