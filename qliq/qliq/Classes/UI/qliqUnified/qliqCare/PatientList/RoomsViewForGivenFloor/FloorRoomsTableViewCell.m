//
//  FloorTableViewCell.m
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/16/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "FloorRoomsTableViewCell.h"

#define SEPARATOR_WIDTH 1.0
#define MAX_NUM_OF_SECTIONS 3

@interface FloorRoomsTableViewCell()
-(void) tapEvent:(UITapGestureRecognizer*)sender;
@end

@implementation FloorRoomsTableViewCell
@synthesize delegate = delegate_;
@synthesize numOfSections = numOfSection_;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        // Initialization code
        self.backgroundView = [[[UIView alloc] init] autorelease];
        self.backgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg-cell.png"]];
        
        roomPlaces = [[NSMutableArray alloc] initWithCapacity:3];
        for(int i = 0; i < MAX_NUM_OF_SECTIONS; i++)
        {
            RoomPlaceView *view = [[RoomPlaceView alloc] init];
            [self addSubview:view];
            [roomPlaces addObject:view];
            [view release];
        }
        
        separators = [[NSMutableArray alloc] initWithCapacity:MAX_NUM_OF_SECTIONS - 1];
        for(int i = 0; i < (MAX_NUM_OF_SECTIONS - 1); i++)
        {
            UIView *separator = [[UIView alloc] init];
            separator.backgroundColor = [UIColor grayColor];
            [self addSubview:separator];
            [separators addObject:separator];
            [separator release];
        }
        tapRecognizer = [[UITapGestureRecognizer alloc] init];
        [tapRecognizer addTarget:self action:@selector(tapEvent:)];
        [self addGestureRecognizer:tapRecognizer];
        self.numOfSections = MAX_NUM_OF_SECTIONS;
    }
    return self;
}

-(void) dealloc
{
    [tapRecognizer release];
    [separators release];
    [roomPlaces release];
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
    
    CGFloat sectionWidth = (self.frame.size.width - ((self.numOfSections - 1) * SEPARATOR_WIDTH)) / self.numOfSections;
    CGFloat xOffset = 0.0;
    int i = 0;
    for( ; i < self.numOfSections; i++)
    {
        UIView *section = [roomPlaces objectAtIndex:i];
        
        section.frame = CGRectMake(xOffset,
                                   0.0,
                                   sectionWidth,
                                   self.frame.size.height);
        xOffset += section.frame.size.width;
        if(i < (MAX_NUM_OF_SECTIONS - 1))
        {
            UIView *separator = [separators objectAtIndex:i];
            separator.frame = CGRectMake(section.frame.origin.x + section.frame.size.width,
                                         0.0,
                                         SEPARATOR_WIDTH,
                                         self.frame.size.height);
            xOffset += separator.frame.size.width;
        }
    }
    if(i<MAX_NUM_OF_SECTIONS)
    {
        for(;i<MAX_NUM_OF_SECTIONS; i++)
        {
            UIView *section = [roomPlaces objectAtIndex:i];
            
            section.frame = CGRectZero;
            xOffset += section.frame.size.width;
            if(i < (MAX_NUM_OF_SECTIONS - 1))
            {
                UIView *separator = [separators objectAtIndex:i];
                separator.frame = CGRectZero;
                xOffset += separator.frame.size.width;
            }
        }
    }
}

-(RoomPlaceView*) roomPlaceViewWithIndex:(NSInteger)index
{
    if(index >= 0 && index < MAX_NUM_OF_SECTIONS)
    {
        return [roomPlaces objectAtIndex:index];
    }
    else
    {
        return nil;
    }
}

-(void) tapEvent:(UITapGestureRecognizer *)sender
{
    CGPoint tap = [sender locationInView:self];
    NSInteger index = 0;
    for(RoomPlaceView *roomPlace in roomPlaces)
    {
        if(!roomPlace.empty && CGRectContainsPoint(roomPlace.frame, tap))
        {
            [self.delegate floorRoomsTableViewCell:self didSelectRoomPlaceAtIndex:index];
            return;
        }
        index ++;
    }
}


-(void) setNumOfSections:(NSUInteger)numOfSections
{
    if(numOfSections > MAX_NUM_OF_SECTIONS)
    {
        numOfSection_ = MAX_NUM_OF_SECTIONS;
    }
    else
    {
        numOfSection_ = numOfSections;
    }
    [self setNeedsLayout];
}

-(NSUInteger) numOfSections
{
    return numOfSection_;
}

@end
