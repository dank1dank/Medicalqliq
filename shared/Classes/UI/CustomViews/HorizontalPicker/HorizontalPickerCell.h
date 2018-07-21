#import <UIKit/UIKit.h>


@interface HorizontalPickerCell : UITableViewCell
{
    UILabel* dateLabel;
    UILabel* dayLabel;
    
    BOOL verticalAlignedContent;
}

@property (nonatomic, readonly) UILabel* dateLabel;
@property (nonatomic, readonly) UILabel* dayLabel;

@property (nonatomic, assign) BOOL verticalAlignedContent;

@end
