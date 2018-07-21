//
//  QSPDFPreview.h
//  QliqSign
//
//  Created by macb on 3/2/17.
//  Copyright © 2017 macb. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QSPDFPreview : UIView

- (int)PDFOpen:(NSString *)path withPassword:(NSString *)pwd;
- (void)PDFClose;
@end
