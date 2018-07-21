//
//  UploadsMediaViewController.h
//  qliq
//
//  Created by Valerii Lider on 04/11/2017.
//
//

#import <UIKit/UIKit.h>
#import "MediaFile.h"
#import "FaxContact.h"

@interface UploadsMediaViewController : UIViewController

@property (nonatomic, assign) BOOL uploadToEMR;
@property (nonatomic, strong) MediaFile *uploadingMediaFile;
@property (nonatomic, strong) NSDictionary *uploadsEMRInfo;

@property (nonatomic, assign) BOOL faxUpload;
@property (nonatomic, strong) NSString *faxSubject;
@property (nonatomic, strong) NSString *faxBody;
@property (nonatomic, strong) FaxContact *faxContact;


@end
