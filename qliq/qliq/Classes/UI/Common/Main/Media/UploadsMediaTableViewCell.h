//
//  UploadsMediaTableViewCell.h
//  qliq
//
//  Created by Valerii Lider on 04/11/2017.
//
//

#import <UIKit/UIKit.h>
#import "MediaFileUpload.h"

@protocol UploadsMediaTableViewCellDelegate <NSObject>

- (BOOL)startDownloadOfUploadingFile:(QxMediaFile *)mediaFile forCell:(id)cell withIndexPath:(NSIndexPath*)indexPath;

@end

@interface UploadsMediaTableViewCell : UITableViewCell

@property (nonatomic, assign) id <UploadsMediaTableViewCellDelegate> delegate;
@property (nonatomic, strong) ProgressHandler *progressHandler;
@property (nonatomic, weak) IBOutlet UIImageView *contentTypeImageView;

- (void)setCell:(id)item withIndexPath:(NSIndexPath*)indexPath;
- (void)setupProgressHandler:(NSInteger)attachmentId;

@end
