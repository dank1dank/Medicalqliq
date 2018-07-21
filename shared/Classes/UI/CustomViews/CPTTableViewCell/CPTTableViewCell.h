//
//  CPTTableViewCell.h
//  CCiPhoneApp
//
//  Created by Marcin Zbijowski on 04/05/2011.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CPTTableViewCell : UITableViewCell {
    UIImage *_openedImage;
    UIImage *_closedImage;
}

@property (nonatomic, assign) BOOL opened;

@end
