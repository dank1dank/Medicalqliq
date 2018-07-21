//
//  EditableQuickMessageCell.h
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/15/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
@class EditableQuickMessageCell;

@protocol EditableQuickMessageCellDelegate

-(void) EditableQuickMessageCell:(EditableQuickMessageCell*)cell didEndEditingWithResultString:(NSString*)string;

@end

@interface EditableQuickMessageCell : UITableViewCell <UITextFieldDelegate>

@property (nonatomic, unsafe_unretained) id<EditableQuickMessageCellDelegate> delegate;

@property (nonatomic, assign, getter = isEditing) BOOL editing;
@property (nonatomic, readonly,retain) UITextField* textField;

@end
