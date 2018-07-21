//
//  UploadDetailTableViewCell.m
//  qliq
//
//  Created by Valerii Lider on 04/26/2017.
//
//

#import "UploadDetailTableViewCell.h"
#import "NSDate+Format.h"

@interface UploadDetailTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *timestampLabel;

@end

@implementation UploadDetailTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code

    self.imageView.backgroundColor = [UIColor whiteColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.selectedBackgroundView = [[UIView alloc] init];
    self.selectedBackgroundView.backgroundColor = [UIColor clearColor];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {

    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setCellWithMessage:(NSString *)message withEvent:(NSString *)event withTime:(NSTimeInterval)time {

    self.timestampLabel.text = [[NSDate dateWithTimeIntervalSince1970:time] stringWithTimeWithSecondsAndDate];
    if ([event isEqualToString:QliqLocalizedString(@"2461-TitleStarted")]) {
        event = QliqLocalizedString(@"2462-TitleStartedUploading");
    }
    self.titleLabel.text = event;
}

@end
