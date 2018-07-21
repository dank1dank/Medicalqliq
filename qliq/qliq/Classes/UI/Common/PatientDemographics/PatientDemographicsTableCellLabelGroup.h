//
//  PatientDemographicsTableCellLabelGroup.h
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/18/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PatientDemographicsTableCellLabelGroup : UIView
{
    UILabel *key_;
    UILabel *value_;
}

@property(nonatomic, readonly) UILabel *key;
@property(nonatomic, readonly) UILabel *value;

@end
