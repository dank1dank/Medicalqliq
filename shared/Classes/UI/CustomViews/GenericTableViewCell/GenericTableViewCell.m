//
//  GenericTableViewCell.m
//  CCiPhoneApp
//
//  Created by Dmitriy Nasyrov on 6/12/11.
//  Copyright 2011 NetroadGroup.com. All rights reserved.
//

#import "GenericTableViewCell.h"
#import "LightGreyGradientView.h"

@implementation GenericTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        bg = [[LightGreyGradientView alloc] init];
        self.backgroundView = bg;
        
		self.textLabel.textColor = [UIColor colorWithRed:0.0039f green:0.2549f blue:0.4353 alpha:1.0f];
        //self.textLabel.textColor = [UIColor colorWithWhite:0.2196 alpha:1.0f];
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.font = [UIFont boldSystemFontOfSize:16.0f];
        self.detailTextLabel.textColor = [UIColor colorWithWhite:0.3019 alpha:1.0f];
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
        self.detailTextLabel.font = [UIFont systemFontOfSize:13.0f];
        
    }
    return self;
}

- (void)backgroundViewOn:(BOOL)_isOn {
    if(_isOn) {
        self.textLabel.textColor = [UIColor colorWithWhite:0.2196 alpha:1.0f];
        self.detailTextLabel.textColor = [UIColor colorWithWhite:0.3019 alpha:1.0f];
        self.backgroundView = bg;
    } else {
        self.textLabel.textColor = [UIColor colorWithWhite:1.0 alpha:1.0f];
        self.detailTextLabel.textColor = [UIColor colorWithWhite:1.0 alpha:1.0f];
        self.backgroundView = nil;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)dealloc
{
    [bg release];
    [super dealloc];
}

@end
