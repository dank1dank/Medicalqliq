//
//  RecepientCell.m
//  qliq
//
//  Created by Aleksey Garbarev on 11/23/12.
//
//

#import "RecepientCell.h"

#define avatarWidth 44.0f
#define iconWidth 20.0f


@implementation RecepientCell{
    UIButton * rightButton;
    UILabel * titleLabel;
    UILabel * subtitleLabel;
    UIImageView * leftImageView;
    
    UIColor * activeColor;
    UIColor * inactiveColor;
    
    BOOL isAvatarShowed;
}

@synthesize recepient;

- (void) layoutSubviews{
    [super layoutSubviews];
    CGFloat offsetX = 0;
    CGFloat offsetY = 5;
    
    CGFloat rightPadding = 0;
    
    if (!leftImageView.hidden){
        CGFloat boundWidth = isAvatarShowed ? avatarWidth : iconWidth;
        CGFloat imageSize = isAvatarShowed ? avatarWidth : iconWidth;
        leftImageView.frame = CGRectMake(5 + (boundWidth - imageSize)/2, (self.bounds.size.height - imageSize)/2, imageSize, imageSize);
        
        offsetX = 5*isAvatarShowed + boundWidth;
    }
    
    if (subtitleLabel.text.length == 0) offsetY = (self.bounds.size.height - 27)/2;
    
    if (!rightButton.hidden){
        rightPadding = self.bounds.size.width - rightButton.frame.origin.x - (self.bounds.size.width - (offsetX + 12 + 210) );
    }
    
    CGFloat titlesWidth = self.bounds.size.width - (rightPadding + offsetX + 12);
    titleLabel.frame = CGRectMake(offsetX + 12, offsetY + 5, titlesWidth, 27);
    subtitleLabel.frame = CGRectMake(offsetX + 12, 27, titlesWidth, 20);
    
    [rightButton setSelected:NO];
    [rightButton setHighlighted:NO];
    
}



- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        UIViewAutoresizing autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        UIImageView * backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell_bg_gray"]];
        backgroundView.frame = self.bounds;
        backgroundView.autoresizingMask = autoresizingMask;
        [self addSubview:backgroundView];
        
        activeColor = [[UIColor alloc] initWithRed:2/255.0f green:65/255.0f blue:110/255.0f alpha:1.0];
        inactiveColor = [[UIColor alloc] initWithWhite:0.5 alpha:1.0];
        
        rightButton = [[QliqButton alloc] initWithFrame:CGRectMake(230, (self.bounds.size.height - 28)/2, 60, 28)];
        rightButton.autoresizingMask = autoresizingMask;
        rightButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeueLTStd-Bd" size:12];
        [rightButton setTitle:@"Invite" forState:UIControlStateNormal];
        rightButton.contentEdgeInsets = UIEdgeInsetsMake(5, 0, 0, 0);
        [rightButton addTarget:self action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:rightButton];
        rightButton.hidden = YES;
        
        titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(42, 10, 210, 27)];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textColor = activeColor;
        titleLabel.font = [UIFont fontWithName:@"HelveticaNeueLTStd-Bd" size:18];
        [self addSubview:titleLabel];
        
        subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(42, 27, 210, 20)];
        subtitleLabel.backgroundColor = [UIColor clearColor];
        subtitleLabel.textColor = [UIColor colorWithRed:109/255.0f green:110/255.0f blue:112/255.0f alpha:1.0];
        subtitleLabel.font = [UIFont fontWithName:@"HelveticaNeueLTStd-Bd" size:11];
        [self addSubview:subtitleLabel];
        
        leftImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 15, 20, 20)];
        leftImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:leftImageView];
        leftImageView.hidden = YES;
        leftImageView.clipsToBounds = YES;

    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

- (void) setRecepient:(id <Recipient>) _recepient{
    
    recepient = _recepient;
    
    if ([recepient respondsToSelector:@selector(recipientTitle)])
        titleLabel.text = [recepient recipientTitle];
    else
        titleLabel.text = nil;
    
    if ([recepient respondsToSelector:@selector(recipientSubtitle)])
        subtitleLabel.text = [recepient recipientSubtitle];
    else
        subtitleLabel.text = nil;
    
    if ([recepient respondsToSelector:@selector(recipientAvatar)]){
        leftImageView.image = [recepient recipientAvatar];
    }else
        leftImageView.image = [UIImage imageNamed:@"group_registration_logo"];
    
    isAvatarShowed = YES;// avatars and group icons should be displayed same size
    
    if ([recepient respondsToSelector:@selector(isRecipientEnabled)])
        titleLabel.textColor = [recepient isRecipientEnabled] ? activeColor : inactiveColor;
    else
        titleLabel.textColor = inactiveColor;
    
    rightButton.hidden = YES;
    leftImageView.hidden = NO;
    
}

@end

