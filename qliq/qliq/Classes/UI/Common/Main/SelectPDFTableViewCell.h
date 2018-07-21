//
//  SelectPDFTableViewCell.h
//  qliq
//
//  Created by Spire User on 18/11/2016.
//
//

#import <UIKit/UIKit.h>

@interface SelectPDFTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *contentTypeImageView;
@property (weak, nonatomic) IBOutlet UILabel *selectFileLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

- (void)setCell:(id)item withIndexPath:(NSIndexPath *)indexPath;
@end
