//
//  EditableQuickMessageCell.m
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/15/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "EditableQuickMessageCell.h"

@implementation EditableQuickMessageCell

@synthesize editing;
@synthesize textField;
@synthesize delegate;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) 
    {
        // Initialization code
//        self.contentView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg-cell"]];
//        self.textLabel.textColor = [UIColor colorWithWhite:0.3019 alpha:1.0f];
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.font = [UIFont boldSystemFontOfSize:13.0f];
        
        textField = [[UITextField alloc] init];
        textField.borderStyle = UITextBorderStyleRoundedRect;
        textField.delegate = self;
		textField.accessibilityLabel = @"NewQuickMessage";
        [self addSubview:textField];
        
        editing = NO;
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    CGFloat xOffset = 0.0;
    
    if(editing)
    {
        textField.frame = CGRectMake(10.0,
                                     10.0,
                                     self.frame.size.width - 10.0 - 10.0,
                                     self.frame.size.height - 10.0 - 10.0);
        
        xOffset += textField.frame.origin.x + textField.frame.size.width;
    }
    else
    {
        textField.frame = CGRectMake(0.0,
                                     10.0,
                                     0.0,
                                     self.frame.size.height - 10.0 - 10.0);
    }
    
    self.textLabel.frame = CGRectMake(self.textLabel.frame.origin.x + xOffset,
                                      self.textLabel.frame.origin.y,
                                      self.textLabel.frame.size.width,
                                      self.textLabel.frame.size.height);
    
    self.imageView.frame = CGRectMake(self.imageView.frame.origin.x + xOffset,
                                      self.imageView.frame.origin.y,
                                      self.imageView.frame.size.width, 
                                      self.imageView.frame.size.height);
}


-(void) setEditing:(BOOL)_editing
{
    editing = _editing;
    [UIView beginAnimations:@"cellEditing" context:nil];
    [self layoutSubviews];
    [UIView commitAnimations];
}

-(BOOL) textFieldShouldReturn:(UITextField *)_textField
{
    NSString *text = [_textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if(text.length > 0)
    {
        [self.delegate EditableQuickMessageCell:self didEndEditingWithResultString:text];
    }
    [_textField resignFirstResponder];
    return YES;
}

@end
