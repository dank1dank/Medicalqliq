//
//  RecordAudioViewController.h
//  qliq
//
//  Created by Aleksey Garbarev on 22.03.13.
//
//
#import "BaseAttachmentViewController.h"

@class MediaFile, RecordAudioViewController;
@protocol RecordAudioViewControllerDelegate;

@protocol RecordAudioViewControllerDelegate <NSObject>

- (void)recordAudioController:(RecordAudioViewController *)recordVC didRecordedMedaFile:(MediaFile *)mediaFile;

@end


@interface RecordAudioViewController : BaseAttachmentViewController

@property (nonatomic, assign) id <RecordAudioViewControllerDelegate> delegate;

@property (nonatomic, assign) BOOL isShowShareButton;

@end

