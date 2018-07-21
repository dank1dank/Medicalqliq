//
//  AllChargesTableViewCell.h
//  CCiPhoneApp
//
//  Created by Marcin Zbijowski on 18/05/2011.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AllChargesTableViewCell : UITableViewCell {
    
}

@property (nonatomic, retain) UILabel *lblCptCodes;
@property (nonatomic, retain) UILabel *lblIcdCodes;
@property (nonatomic, retain) UILabel *lblDate;
@property (nonatomic, retain) UIImageView *statusImage;

@property (nonatomic, assign) BOOL showStatusImage;

@end
