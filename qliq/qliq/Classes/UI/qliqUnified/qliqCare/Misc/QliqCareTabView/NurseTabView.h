//
//  NurseTabView.h
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/11/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NurseTabViewDelegate <NSObject>

@optional

-(void) patientsButtonPressed;
-(void) roomsButtonPressed;
-(void) nurseButtonPressed;
-(void) chatButtonPressed;
-(void) alertButtonPressed;
@end

@interface NurseTabView : UIView
{
    UIImageView *buttonGroupBackground;
    UIImageView *buttonHighlightingView;
    UIButton *patientsButton;
    UIButton *roomsButton;
    UIButton *nurseButton;
    
    UIImageView *buttonGroupAlertSeparator;
    
    UIButton *alertButton;
    
    UIImageView *alertChatSeparator;
    
    UIButton *chatButton;
    
    id<NurseTabViewDelegate> delegate_;
    
    NSInteger initialSelectedItem;
}

@property (nonatomic, assign) id<NurseTabViewDelegate> delegate;

-(id) initWithSelectedItem:(NSInteger)selectedItemIndex;

@end
