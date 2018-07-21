//
//  FloorPatientsTableSectionHeader.h
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/17/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FloorPatientsTableSectionHeader : UIView
{
    UIImageView *accessoryView;
    NSInteger sectionIndex_;
    UILabel *titleLabel_;
    
    UITapGestureRecognizer *tapGestureRecognizer;
}

@property (nonatomic, assign) NSInteger sectionIndex;
@property (nonatomic, readonly) UILabel *titleLabel;

@end
