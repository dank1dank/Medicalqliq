//
//  SelectPDFViewController.h
//  qliq
//
//  Created by Valerii Lider on 11/18/16.
//
//

#import <UIKit/UIKit.h>

typedef void (^SelectPdfBlock)(MediaFile *);

@interface SelectPDFViewController : UIViewController

@property (nonatomic, copy) SelectPdfBlock selectPDFCallBack;
@property (nonatomic, assign) BOOL showNewPDFButton;


@end
