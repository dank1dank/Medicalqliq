//
//  ImageCaptureController.m
//  qliqConnect
//
//  Created by Paul Bar on 12/16/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import "ImageCaptureController.h"
#import "UIImage+ScaleAndRotate.h"
#import "AlertController.h"

@interface ImageCaptureController()

-(void) selectPhotoFromLibrary;
-(void) takePhotoWithCamera;

@end

@implementation ImageCaptureController

@synthesize delegate;

-(id) init
{
    self = [super init];
    if(self)
    {
        imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    [imagePicker release];
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

#pragma mark AUTOROTATE_METHOD


- (void)captureImage {
    DDLogInfo(@"Capture image");
    
    
    [AlertController showAlertWithTitle:QliqLocalizedString(@"1118-TextSelectSource")
                                message:nil
                       withTitleButtons:@[QliqLocalizedString(@"26-ButtonPhotoLibrary"), QliqLocalizedString(@"27-ButtonCamera")]
                      cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                             completion:^(NSUInteger buttonIndex) {
                                 switch (buttonIndex) {
                                     case 0:{
                                         [self selectPhotoFromLibrary];
                                     }
                                         break;
                                     case 1:{
                                         [self takePhotoWithCamera];
                                     }
                                         break;
                                         
                                     default:
                                         break;
                                 }
                             }];
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    DDLogInfo(@"Image picked");
    UIImage *pickedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    UIImage *scaledImage = [pickedImage scaleAndRotate];
//    UIImage *scaledImage = pickedImage;
    [self.delegate imageCaptured:scaledImage withController:imagePicker];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    DDLogInfo(@"Image pick canceled");
    [self.delegate imageCaptureControllerCanceled:imagePicker];
}


#pragma mark - 
#pragma mark Private

-(void) takePhotoWithCamera
{
    DDLogInfo(@"Camera");
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self.delegate presentImageCaptureController:imagePicker];
}

-(void) selectPhotoFromLibrary
{
    DDLogInfo(@"Library");
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self.delegate presentImageCaptureController:imagePicker];
}


@end
