//
//  UploadDetailView.h
//  qliq
//
//  Created by Valerii Lider on 04/26/2017.
//
//

#import <UIKit/UIKit.h>
#import "MediaFileUpload.h"

@interface UploadDetailView : UIView

@property (nonatomic, strong) MediaFileUpload *upload;

- (BOOL)uploadHasEvents;
- (void)loadUploadEventsForUploadFile:(MediaFileUpload *)upload;

@end
