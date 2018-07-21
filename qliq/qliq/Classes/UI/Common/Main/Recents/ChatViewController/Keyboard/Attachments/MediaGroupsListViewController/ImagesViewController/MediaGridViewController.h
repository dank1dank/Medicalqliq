//
//  ImagesViewController.h
//  qliqConnect
//
//  Created by Paul Bar on 12/15/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//


#import <UIKit/UIKit.h>

#import "MessageAttachment.h"

@class KeyboardAccessoryViewController, MediaGridViewController;

#define kViewerMediaFilesArray  @"kViewerMediaFilesArray"
#define kViewerTitle            @"kViewerTitle"
#define kViewerTitleImage       @"kViewerTitleImage"
#define kViewerMimeTypes        @"kViewerMimeTypes"
#define kViewerShowFilenames    @"kViewerShowFilenames"

@protocol MediaGridViewControllerDelegate <NSObject>

- (void)mediaGridViewController:(MediaGridViewController*)controller didSelectMediaFile:(MediaFile *)mediaFile;

@end

@interface MediaGridViewController : UIViewController

@property (nonatomic, assign) id <MediaGridViewControllerDelegate> delegate;

@property (nonatomic, assign) BOOL fromSupportSettings;
@property (nonatomic, assign) BOOL viewArhive;
@property (nonatomic, assign) BOOL isGetMediaForConversation;

@property (nonatomic, strong) NSDictionary * viewOptions;
@property (nonatomic, strong) NSArray * mediafiles;

@property (nonatomic, unsafe_unretained) KeyboardAccessoryViewController *keyboardAccessoryViewController;


@end
