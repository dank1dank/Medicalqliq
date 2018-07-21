//
//  MediaTableViewCell.h
//  qliq
//
//  Created by Valerii Lider on 7/29/14.
//
//

#import <UIKit/UIKit.h>

@class MediaFile;

@protocol MediaTableViewCellDelegate <NSObject>

- (void)startDownloadMediaFile:(MediaFile*)mediaFile withCell:(id)cell withIndexPath:(NSIndexPath*)indexPath;

@end

@interface MediaTableViewCell : UITableViewCell

@property (nonatomic, assign) id <MediaTableViewCellDelegate> delegate;

@property (nonatomic, weak) IBOutlet UIImageView *contentTypeImageView;
@property (nonatomic, weak) IBOutlet UILabel *directionLabel;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *fileLabel;
@property (nonatomic, weak) IBOutlet UILabel *timeLabel;

- (void)setupProgressHandler:(NSInteger)attachmentId;
- (void)setCell:(id)item withIndexPath:(NSIndexPath*)indexPath;



@end
