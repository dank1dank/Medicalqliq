//
//  CellPhoneView.h
//  qliq
//
//  Created by Vita on 1/26/12.
//  Copyright (c) 2012 Al Digit. All rights reserved.
//

#import <UIKit/UIKit.h>

#define CellButtonsWidth 94
#define CellButtonsHeight 55

@class CellPhoneView;

@protocol CellPhoneViewDelegate <NSObject>
@optional
-(void)cellPhoneView:(CellPhoneView*)cellPhoneView tapOnCell:(NSInteger)cell;
-(void)cellPhoneViewTapOnStar:(CellPhoneView *)cellPhoneView;
-(void)cellPhoneViewTapOnHash:(CellPhoneView *)cellPhoneView;
@end

@interface CellPhoneView : UIView

@property(nonatomic, assign)id<CellPhoneViewDelegate>delegate;

@end
