//
//  EMRUploadViewController.h
//  qliq
//
//  Created by Valerii Lider on 03/13/2017.
//
//

#import <AVKit/AVKit.h>
#import <UIKit/UIKit.h>
#import "FhirResources.h"
#import "MediaFile.h"

@interface EMRUploadViewController : UIViewController

@property (nonatomic, strong) MediaFile *mediaFile;
@property (nonatomic, strong) FhirPatient *patient;
@property (nonatomic, strong) NSString *emrTargetQliqId;
@property (nonatomic, strong) NSString *emrTargetDeviceUuid;
@property (nonatomic, strong) NSString *emrTargetPublicKey;

@end
