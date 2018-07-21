//
//  ICDTableViewCell.m
//  CCiPhoneApp
//
//  Created by Marcin Zbijowski on 03/05/2011.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "ICDTableViewCell.h"
#import "LightGreyGradientView.h"

#define INDICATOR_X_POS     6
#define DETAIL_X_POS_IND    27
#define DETAIL_X_POS_NOIND  6
#define TEXT_X_POS_IND      81
#define TEXT_X_POS_NOIND    60

@implementation ICDTableViewCell

@synthesize favorite = _favorite, crosswalk = _crosswalk, selected = _selected;
@synthesize visibledIndicators, primaryIcd = _primaryIcd;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundView = [[[UIView alloc] init] autorelease];
        self.backgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg-cell"]];
  
        //self.textLabel.textColor = [UIColor colorWithRed:0.10f green:0.10f blue:0.10f alpha:1.0f];
        self.textLabel.textColor = [UIColor colorWithRed:0.0039f green:0.2549f blue:0.4353 alpha:1.0f];
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.font = [UIFont systemFontOfSize:15.0f];
        self.textLabel.numberOfLines = 2;
        self.detailTextLabel.textColor = [UIColor colorWithWhite:0.3019 alpha:1.0f];
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
        self.detailTextLabel.font = [UIFont systemFontOfSize:15.0f];

    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect frame = self.detailTextLabel.frame;
    if (self.visibledIndicators) {
        frame.origin = CGPointMake(DETAIL_X_POS_IND, 3.0f);
    }
    else {
        frame.origin = CGPointMake(DETAIL_X_POS_NOIND, 3.0f);
    }
    frame.size.width = 55.0f;
    self.detailTextLabel.frame = frame;
	
    frame = self.textLabel.frame;
    if (self.visibledIndicators) {
        frame.origin = CGPointMake(TEXT_X_POS_IND, 3.0f);
    }
    else {
        frame.origin = CGPointMake(TEXT_X_POS_NOIND, 3.0f);
    }
    frame.size.width = self.contentView.bounds.size.width - self.detailTextLabel.frame.origin.x - self.detailTextLabel.frame.size.width - 10;
    
    CGSize textSize = [self.textLabel.text sizeWithFont:self.textLabel.font
                                      constrainedToSize:CGSizeMake(frame.size.width, self.contentView.bounds.size.height)
                                          lineBreakMode:UILineBreakModeWordWrap];
    int lines = (int)floor(textSize.height / self.textLabel.font.pointSize);
    if (lines > 2) lines = 2;
    self.textLabel.numberOfLines = lines;
	
    //frame.size.height = MIN(self.contentView.bounds.size.height - 10, textSize.height);
    
	frame.size.height = MIN(self.contentView.bounds.size.height, textSize.height);
 	frame.origin.y = (int)((self.contentView.bounds.size.height - frame.size.height) / 2);
    self.textLabel.frame = frame;
    frame = self.detailTextLabel.frame;
    frame.origin.y = self.textLabel.frame.origin.y;
    self.detailTextLabel.frame = frame;

}

/*
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}*/

- (void)dealloc
{
    [_favoriteView release];
    [_crosswalkView release];
    [super dealloc];
}

#pragma mark -
#pragma mark Custom setters

- (void)setSelected:(BOOL)selected {
    if (_selected != selected) {
        _selected = selected;
        
        if (_selectedView == nil) {
            _selectedView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"picked"]];
            CGRect frame = _selectedView.frame;
            frame.origin = CGPointMake(INDICATOR_X_POS, 4.0);
            _selectedView.frame = frame;
            [self.contentView addSubview:_selectedView];
        }
        _selectedView.hidden = !_selected;
    }
}


- (void)setFavorite:(BOOL)favorite {
    if (_favorite != favorite) {
        _favorite = favorite;
        
        if (_favoriteView == nil) {
            _favoriteView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-fav"]];
            CGRect frame = _favoriteView.frame;
            frame.origin = CGPointMake(INDICATOR_X_POS, 4.0);
            _favoriteView.frame = frame;
            [self.contentView addSubview:_favoriteView];
        }
        _favoriteView.hidden = !_favorite;
    }
}

- (void)setCrosswalk:(BOOL)crosswalk {
    if (_crosswalk != crosswalk) {
        _crosswalk = crosswalk;
        
        if (_crosswalkView == nil) {
            _crosswalkView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-crosswalk"]];
            CGRect frame = _crosswalkView.frame;
            frame.origin = CGPointMake(INDICATOR_X_POS, 22.0);
            _crosswalkView.frame = frame;
            [self.contentView addSubview:_crosswalkView];
        }
        _crosswalkView.hidden = !_crosswalk;
    }
}

- (void)setPrimaryIcd:(BOOL)primaryIcd {
    if (_primaryIcd != primaryIcd) {
        _primaryIcd = primaryIcd;
        if (_primaryIcd) {
            self.detailTextLabel.font = [UIFont boldSystemFontOfSize:self.detailTextLabel.font.pointSize];
            self.textLabel.font = [UIFont boldSystemFontOfSize:self.textLabel.font.pointSize];
        }
        else {
            self.detailTextLabel.font = [UIFont systemFontOfSize:self.detailTextLabel.font.pointSize];
            self.textLabel.font = [UIFont systemFontOfSize:self.textLabel.font.pointSize];
        }
    }
}

@end
