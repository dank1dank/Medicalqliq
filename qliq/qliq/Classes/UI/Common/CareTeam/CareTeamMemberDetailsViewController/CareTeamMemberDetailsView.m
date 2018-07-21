//
//  CareTeamMemberDetailsView.m
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/18/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "CareTeamMemberDetailsView.h"

#define HEADER_HEIGHT 60.0
#define TAB_VIEW_HEIGHT 55.0

@implementation CareTeamMemberDetailsView

@synthesize infoTable = infoTable_;

-(id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        headerView = [[UIImageView alloc] init];
        headerView.image = [UIImage imageNamed:@"careTeamView_header_background.png"];
        [self addSubview:headerView];
        
        favoritesView = [[UIImageView alloc] init];
        favoritesView.backgroundColor = [UIColor clearColor];
        favoritesView.image = [UIImage imageNamed:@"add_to_favorites.png"];
        [self addSubview:favoritesView];
        
        physicianNameLabel = [[UILabel alloc] init];
        physicianNameLabel.textColor = [UIColor blackColor];
        physicianNameLabel.backgroundColor = [UIColor clearColor];
        physicianNameLabel.font = [UIFont boldSystemFontOfSize:18.0];
        [self addSubview:physicianNameLabel];
        
        infoTable_ = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        infoTable_.showsHorizontalScrollIndicator = NO;
        infoTable_.showsVerticalScrollIndicator = NO;
        infoTable_.backgroundColor = [UIColor colorWithWhite:0.2039f alpha:1.0f];
        infoTable_.separatorColor = [UIColor colorWithWhite:0.2039f alpha:1.0f];
        infoTable_.separatorStyle = UITableViewCellSeparatorStyleNone;
        [self addSubview:infoTable_];
        
        tabView = [[CareTeamMemberDetailsTabView alloc] init];
        [self addSubview:tabView];
    }
    return self;
}


-(void) dealloc
{
    [infoTable_ release];
    [physicianNameLabel release];
    [favoritesView release];
    [headerView release];
    [super dealloc];
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    headerView.frame = CGRectMake(0.0,
                                  0.0,
                                  self.frame.size.width, 
                                  HEADER_HEIGHT);
    
    favoritesView.frame = CGRectMake(headerView.frame.origin.x + headerView.frame.size.width - 10.0 - 50.0,
                                        5.0,
                                        50.0,
                                        headerView.frame.size.height - 5.0 * 2.0);
    
    CGFloat xOffset = 10.0;
    CGFloat maxLabelWidth = self.frame.size.width - xOffset - 10.0 * 2.0 - 50.0;
    CGSize tmpSize = [physicianNameLabel.text sizeWithFont:physicianNameLabel.font];
    if(tmpSize.width > maxLabelWidth)
    {
        tmpSize.width = maxLabelWidth;
    }
    physicianNameLabel.frame = CGRectMake(xOffset,
                                        (headerView.frame.size.height / 2.0) - (tmpSize.height / 2.0),
                                        maxLabelWidth,
                                        tmpSize.height);
    
    infoTable_.frame = CGRectMake(0.0,
                                  HEADER_HEIGHT,
                                  self.frame.size.width,
                                  self.frame.size.height - HEADER_HEIGHT - TAB_VIEW_HEIGHT);
    
    tabView.frame = CGRectMake(0.0,
                               self.frame.size.height - TAB_VIEW_HEIGHT,
                               self.frame.size.width,
                               TAB_VIEW_HEIGHT);
    
}

#pragma mark -
#pragma mark Properties

-(void) setProviderName:(NSString *)providerName
{
    physicianNameLabel.text = providerName;
}

-(NSString*) physicianName
{
    return physicianNameLabel.text;
}


-(void) setFavoritesViewImage:(UIImage *)favoritesViewImage
{
    if(favoritesViewImage == nil)
    {
        favoritesView.image = [UIImage imageNamed:@"add_to_favorites.png"];
    }
    else
    {
        favoritesView.image = favoritesViewImage;
    }
}

-(UIImage*) favoritesViewImage
{
    return favoritesView.image;
}



@end
