//
//  CustomListTableViewCell.h
//  qliq
//
//  Created by Vita on 7/18/12.
//  Copyright (c) 2012 Al Digit. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CustomListTableViewCell;

@protocol CustomListCellDelegate <NSObject>

@optional
- (void)checkedButtonPressed:(CustomListTableViewCell *)cell;

@end

@interface CustomListTableViewCell : UITableViewCell

@property (nonatomic, assign) id <CustomListCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *checkmarkButton;

@property (nonatomic, assign) BOOL checked;

- (void)setListTitle:(NSString*)listTitle;

@end
