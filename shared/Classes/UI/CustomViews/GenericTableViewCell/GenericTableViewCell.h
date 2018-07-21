//
//  GenericTableViewCell.h
//  CCiPhoneApp
//
//  Created by Dmitriy Nasyrov on 6/12/11.
//  Copyright 2011 NetroadGroup.com. All rights reserved.
//

@class LightGreyGradientView;

@interface GenericTableViewCell : UITableViewCell {
    LightGreyGradientView *bg;
}

- (void)backgroundViewOn:(BOOL)_isOn;

@end
