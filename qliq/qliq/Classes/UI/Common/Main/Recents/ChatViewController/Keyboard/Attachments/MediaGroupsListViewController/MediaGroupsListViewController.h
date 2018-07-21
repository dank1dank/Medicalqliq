//
//  MediaGroupsListViewController.h
//  qliqConnect
//
//  Created by Paul Bar on 12/15/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MediaFile, MediaGroupsListViewController;

@protocol MediaGroupsListViewControllerDelegate <NSObject>

- (void)mediaGroupsListViewController:(MediaGroupsListViewController *)controller didSelectMediaFile:(MediaFile *)mediaFile;

@end


@interface MediaGroupsListViewController : UIViewController

@property (nonatomic, weak) id<MediaGroupsListViewControllerDelegate> delegate;

@property (nonatomic, assign) BOOL isGetMediaForConversation;
@property (nonatomic, assign) BOOL fromSupportSettings;

@end
