#import "HorizontalPickerCell.h"

static const float distanceBetweenLabels = -1.5f;

@implementation HorizontalPickerCell

@synthesize dateLabel;
@synthesize dayLabel;
@synthesize verticalAlignedContent;

- (id) initWithStyle: (UITableViewCellStyle) style 
     reuseIdentifier: (NSString*)            reuseIdentifier
{
	if ((self = [super initWithStyle: style reuseIdentifier: reuseIdentifier]))
	{
        verticalAlignedContent = NO;
        
        dateLabel = [[[UILabel alloc] initWithFrame: CGRectZero] autorelease];
        dateLabel.textColor = [UIColor colorWithWhite: 0.3019 alpha: 1.0];
        dateLabel.font = [UIFont boldSystemFontOfSize: 18];
        dateLabel.textAlignment = UITextAlignmentCenter;

        dayLabel = [[[UILabel alloc] initWithFrame: CGRectZero] autorelease];
        dayLabel.textColor = [UIColor colorWithWhite: 0.4313 alpha: 1.0];
        dayLabel.font = [UIFont boldSystemFontOfSize: 11];
        dayLabel.textAlignment = UITextAlignmentCenter;

        [self.contentView addSubview: dateLabel];
        [self.contentView addSubview: dayLabel];
    }
    
    return self;
} // [HabitsCell initWithStyle: reuseIdentifier:]


- (void) layoutSubviews
{
    [super layoutSubviews];
    
    [dateLabel sizeToFit];
    [dayLabel sizeToFit];
    
    if (!verticalAlignedContent)
    {
        dateLabel.frame = CGRectMake(0.0f, (int)((CGRectGetWidth(self.bounds) - CGRectGetHeight(dateLabel.frame) - CGRectGetHeight(dayLabel.frame) - distanceBetweenLabels) / 2),
                                     (int)CGRectGetHeight(self.bounds), CGRectGetHeight(dateLabel.frame));
        dayLabel.frame = CGRectMake(0.0f, CGRectGetMaxY(dateLabel.frame) + distanceBetweenLabels,
                                    (int)CGRectGetHeight(self.bounds), CGRectGetHeight(dayLabel.frame));
    }
    else
    {
        dateLabel.frame = CGRectMake(0.0f, (int)((CGRectGetHeight(self.bounds) - CGRectGetHeight(dateLabel.frame) - CGRectGetHeight(dayLabel.frame) - distanceBetweenLabels) / 2),
                                     (int)CGRectGetWidth(self.bounds), CGRectGetHeight(dateLabel.frame));
        dayLabel.frame = CGRectMake(0.0f, CGRectGetMaxY(dateLabel.frame) + distanceBetweenLabels,
                                    (int)CGRectGetWidth(self.bounds), CGRectGetHeight(dayLabel.frame));        
    }
} // [HabitsCell layoutSubviews]


- (void) dealloc 
{
    [super dealloc];
} // [HabitsCell dealloc]



@end
