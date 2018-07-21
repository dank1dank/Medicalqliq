//
//  PatientDemographicsView.h
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/18/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PatientDemographicsView : UIView
{
    UIImageView *headerView;
    UIImageView *patientPhotoView;
    UILabel *patientNameLabel;
    
    UITableView *infoTable_;
}

@property (nonatomic, assign) NSString *patientName;
@property (nonatomic, assign) UIImage *patientPhoto;
@property (nonatomic, readonly) UITableView *infoTable;

@end
