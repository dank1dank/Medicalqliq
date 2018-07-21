//
//  CareTeamInfoTableCell.m
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/17/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "CareTeamInfoTableCell.h"

#define BUTTON_WIDTH 44.0
#define SEPARATOR_WIDTH 1.0

@interface CareTeamInfoTableCell()

-(void) tapEvent:(UITapGestureRecognizer*)sender;

@end

@implementation CareTeamInfoTableCell

@synthesize delegate = delegate_;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) 
    {
        // Initialization code
        self.backgroundView = [[[UIView alloc] init] autorelease];
        self.backgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg-cell.png"]];
        
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.font = [UIFont boldSystemFontOfSize:18.0];
        self.textLabel.textColor = [UIColor colorWithRed:0.0039f green:0.2549f blue:0.4353 alpha:1.0f];
        self.textLabel.adjustsFontSizeToFitWidth = YES ;
        
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
        self.detailTextLabel.font = [UIFont systemFontOfSize:12.0];
        self.detailTextLabel.textColor = [UIColor colorWithRed:0.4275 green:0.4314 blue:0.4431 alpha:1.0f];
        self.detailTextLabel.adjustsFontSizeToFitWidth = YES;
        self.detailTextLabel.textAlignment = UITextAlignmentLeft;
        
        callView = [[UIImageView alloc] init];
        callView.image = [UIImage imageNamed:@"phone_blue.png"];
        callView.contentMode = UIViewContentModeCenter;
        [self addSubview:callView];
        
        chatView = [[UIImageView alloc] init];
        chatView.image = [UIImage imageNamed:@"chat_blue.png"];
        chatView.contentMode = UIViewContentModeCenter;
        [self addSubview:chatView];
        
        separator1 = [[UIView alloc] init];
        separator1.backgroundColor = [UIColor grayColor];
        [self addSubview:separator1];
        
        separator2 = [[UIView alloc] init];
        separator2.backgroundColor = [UIColor grayColor];
        [self addSubview:separator2];
        
        tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapEvent:)];
        [self addGestureRecognizer:tapRecognizer];
    }
    return self;
}

-(void) dealloc
{
    [tapRecognizer release];
    [separator1 release];
    [separator2 release];
    [callView release];
    [chatView release];
    [super dealloc];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat rightXOffset = BUTTON_WIDTH;
    
    chatView.frame = CGRectMake(self.frame.size.width - rightXOffset,
                                0.0,
                                BUTTON_WIDTH,
                                self.frame.size.height);
    rightXOffset += SEPARATOR_WIDTH;
    
    separator2.frame = CGRectMake(self.frame.size.width - rightXOffset,
                                  0.0,
                                  SEPARATOR_WIDTH,
                                  self.frame.size.height);
    rightXOffset += BUTTON_WIDTH;
    
    callView.frame = CGRectMake(self.frame.size.width - rightXOffset,
                                0.0,
                                BUTTON_WIDTH,
                                self.frame.size.height);
    rightXOffset += SEPARATOR_WIDTH;
    
    separator1.frame = CGRectMake(self.frame.size.width - rightXOffset,
                                  0.0,
                                  SEPARATOR_WIDTH,
                                  self.frame.size.height);
    
    CGRect labelsRect = CGRectMake(10.0,
                                   10.0,
                                   self.frame.size.width - rightXOffset - (10.0 * 2.0),
                                   self.frame.size.height - (10.0 * 2.0));
    
    self.textLabel.frame = CGRectMake(labelsRect.origin.x,
                                      labelsRect.origin.y,
                                      labelsRect.size.width,
                                      labelsRect.size.height / 2.0);
    
    self.detailTextLabel.frame = CGRectMake(labelsRect.origin.x,
                                            labelsRect.origin.y + self.textLabel.frame.size.height + 5.0,
                                            labelsRect.size.width,
                                            labelsRect.size.height - self.textLabel.frame.size.height - 5.0);
}

-(void) tapEvent:(UITapGestureRecognizer *)sender
{
    [self.delegate selectedCell:self];
}

@end
