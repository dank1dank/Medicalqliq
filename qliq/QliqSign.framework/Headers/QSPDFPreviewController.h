//
//  QSPDFPreviewController.h
//  QliqSign
//
//  Created by macb on 9/28/16.
//  Copyright © 2016 macb. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "QSPagesViewController.h"
#import "QSPDFPreview.h"

@interface QSPDFPreviewController : UIViewController
{
    
}

@property (nonatomic,assign) id<QSEditingDoneDelegate> pdfEditingDoneDelegate;

@property (strong, nonatomic) NSString *pdfFileName;
@property (strong, nonatomic) QSPDFPreview *pdfViewer;
//@property (strong, nonatomic) UIWebView *pdfViewer;

@property (nonatomic, strong) void (^saveBlock)(NSString *temporaryFilePath);
@property (nonatomic, strong) bool (^fillSignAuthorizationBlock)(void);
@property (nonatomic, strong) void (^justmeBlock)(void);
@property (nonatomic, strong) void (^meandothersBlock)(void);
@property (nonatomic, strong) void (^othersBlock)(void);

@property (nonatomic, assign) bool isExistingPDF;

- (void)doneSaving:(NSString *)filePath;
- (void)setContacts:(NSDictionary *)contacts;
@end
