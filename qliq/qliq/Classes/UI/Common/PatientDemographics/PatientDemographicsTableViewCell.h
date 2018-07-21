//
//  PatientDemographicsTableViewCell.h
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/18/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PatientDemographicsTableCellLabelGroup.h"

@interface PatientDemographicsTableViewCell : UITableViewCell
{
    NSMutableArray *labelGroups;
}

-(PatientDemographicsTableCellLabelGroup*) labelGroupAtIndex:(NSInteger)index;

@end
