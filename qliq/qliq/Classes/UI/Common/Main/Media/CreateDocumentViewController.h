//
//  CreateDocumentViewController.h
//  qliq
//
//  Created by Valeriy Lider on 24.12.14.
//
//

#import <UIKit/UIKit.h>

@class CreateDocumentViewController;
@class MediaFile;

@protocol CreateDocumentViewControllerDelegate <NSObject>

- (void) createDocumentViewController:(CreateDocumentViewController *)document didCreateddMediaFile:(MediaFile *)mediaFile;

@end

@interface CreateDocumentViewController : UIViewController

@property (nonatomic, assign) id <CreateDocumentViewControllerDelegate> delegate;

@end

