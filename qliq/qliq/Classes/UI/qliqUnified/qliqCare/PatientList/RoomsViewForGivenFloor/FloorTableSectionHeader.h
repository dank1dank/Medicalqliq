//
//  FloorTableSectionHeader.h
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/16/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FloorTableSectionHeader;

@protocol FloorTableSectionHeaderDelegate <NSObject>

-(void) selectedSectionHeader:(FloorTableSectionHeader*)header;

@end

@interface FloorTableSectionHeader : UIView
{
    UIImageView *accessoryView;
    NSInteger sectionIndex_;
    UILabel *titleLabel_;
    
    UITapGestureRecognizer *tapGestureRecognizer;
    
    id<FloorTableSectionHeaderDelegate> delegate_;
}

@property (nonatomic, assign) NSInteger sectionIndex;
@property (nonatomic, readonly) UILabel *titleLabel;
@property (nonatomic, assign) id<FloorTableSectionHeaderDelegate> delegate;

@end
