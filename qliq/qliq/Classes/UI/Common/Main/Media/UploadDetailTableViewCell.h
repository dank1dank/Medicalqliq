//
//  UploadDetailTableViewCell.h
//  qliq
//
//  Created by Valerii Lider on 04/26/2017.
//
//

#import <UIKit/UIKit.h>
#import "MediaFileUpload.h"

@interface UploadDetailTableViewCell : UITableViewCell

- (void)setCellWithMessage:(NSString *)message withEvent:(NSString *)event withTime:(NSTimeInterval)time;

@end
