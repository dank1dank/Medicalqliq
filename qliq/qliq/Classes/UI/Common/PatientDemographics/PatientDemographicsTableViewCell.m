//
//  PatientDemographicsTableViewCell.m
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/18/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "PatientDemographicsTableViewCell.h"

#define VIEWS_OFFSET 10.0

@implementation PatientDemographicsTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        // Initialization code
        self.backgroundView = [[[UIView alloc] init] autorelease];
        //self.backgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"PatientDemographicsTableViewCell_bg.png"]];
        self.backgroundView.backgroundColor = [UIColor whiteColor];
        labelGroups = [[NSMutableArray alloc] initWithCapacity:3];
        for(int i = 0; i < 3; i++)
        {
            PatientDemographicsTableCellLabelGroup *group = [[PatientDemographicsTableCellLabelGroup alloc] init];
            [self addSubview:group];
            [labelGroups addObject:group];
            [group release];
        }
    }
    return self;
}

-(void) dealloc
{
    [labelGroups release];
    [super dealloc];
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat yOffset = VIEWS_OFFSET;
    
    for(int i = 0; i < 3; i ++)
    {
        UIView *group = [labelGroups objectAtIndex:i];
        
        group.frame = CGRectMake(VIEWS_OFFSET,
                                 yOffset,
                                 self.frame.size.width - VIEWS_OFFSET * 3.0 - 44.0,
                                 roundf((self.frame.size.height - (2.0 * VIEWS_OFFSET)) / 3.0));
        
        yOffset += group.frame.size.height;
    }
    
    self.imageView.frame = CGRectMake(self.frame.size.width - VIEWS_OFFSET - 44.0,
                                      self.frame.size.height / 2.0 - 22.0,
                                      44.0,
                                      44.0);
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(PatientDemographicsTableCellLabelGroup*)labelGroupAtIndex:(NSInteger)index
{
    if(index>=0 && index < [labelGroups count])
    {
        return [labelGroups objectAtIndex:index];
    }
    return nil;
}

@end
