//
//  UIViewControllers+Additions.h
//  CCiPhoneApp
//
//  Created by Marcin Zbijowski on 28/04/2011.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "PatientHeaderView.h"

@class Patient_old, QliqButton;

@interface UIViewController (QliqAdditions)

// MZ: method to help style navigation bar with proper elements
- (void)setNavigationBarBackgroundImage;
- (void)setNavigationBarBackgroundOfflineImage;
- (UIBarButtonItem *)leftLogoItem;
- (UIButton*)leftLogoButton;

- (UIBarButtonItem *) itemWithTitle:(NSString * ) title button:(QliqButton *) button;
- (UIBarButtonItem *) itemWithTitle:(NSString * ) title subtitle:(NSString *) subtitle button:(QliqButton *) button;
- (UIBarButtonItem *) itemWithTitle:(NSString * )title subtitle:(NSString *)subtitle button:(QliqButton *)button leftView:(UIView *)leftView;

//- (PatientHeaderView *)patientHeader:(Census_old *)censusObj dateOfService:(NSTimeInterval)dos delegate:(id<PatientHeaderViewDelegate>)delegate;

- (UIButton *)icdCellChevronWithTag:(NSInteger)tag width:(CGFloat)width height:(CGFloat)height;
- (UIButton *)icdCellChevronWithTag:(NSInteger)tag;
- (UIButton *)cptCellChevronWithTag:(NSInteger)tag width:(CGFloat)width height:(CGFloat)height;
- (UIButton *)cptCellChevronWithTag:(NSInteger)tag;

@end
