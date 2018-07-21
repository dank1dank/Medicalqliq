//
//  QSPagesViewController.h
//  QliqSign
//
//  Created by macb on 9/24/16.
//  Copyright © 2016 macb. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "QSImagePickerController.h"

@protocol QSEditingDoneDelegate <NSObject>

@required
- (void)canceledEditing;
- (void)doneEditing:(NSString *)path :(NSDictionary *)signedUser;

@end

@interface QSPagesViewController : UIViewController<UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, QSImagePickerControllerDelegate>
{
    NSInteger pageCounts;
    BOOL isAddedThumbView;
    NSInteger currentIndex;
}

@property (nonatomic,assign) id<QSEditingDoneDelegate> pdfEditingDoneDelegate;

@property (nonatomic, strong) void (^saveBlock)(NSString *temporaryFilePath);
@property (nonatomic, strong) bool (^fillSignAuthorizationBlock)(void);
@property (nonatomic, strong) void (^justmeBlock)(void);
@property (nonatomic, strong) void (^meandothersBlock)(void);
@property (nonatomic, strong) void (^othersBlock)(void);
@property (nonatomic, strong) void (^addPageFromGallery)(void);

@property (strong, nonatomic) UIScrollView *imageScrollView;
@property (strong, nonatomic) UITableView *pageThumbTableView;

@property (strong, nonatomic) UIImageView *currentPageView;

@property (strong, nonatomic) NSMutableArray<UIImage*> *images;

@property (nonatomic, assign) BOOL isAvailableDocument;

@property (strong, nonatomic) UIActivityIndicatorView *progressIndicator;

- (void)updateView;
- (void)doneSaving:(NSString *)filePath;
- (void)setContacts:(NSDictionary *)contacts;
@end
