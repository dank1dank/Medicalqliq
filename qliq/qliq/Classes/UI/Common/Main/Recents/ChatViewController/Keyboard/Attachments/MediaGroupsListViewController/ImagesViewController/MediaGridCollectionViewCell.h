//
//  MediaGridCollectionViewCell.h
//  qliqConnect
//
//  Created by Valerii Lider on 08/13/14.
//
//

#import <UIKit/UIKit.h>

#define kMediaGridCollectionViewCellWidth                           100.f
#define kMediaGridCollectionViewCellHeight                          110.f

@interface MediaGridCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UILabel *mediafileNameLabel;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) BOOL progressBarHidden;

-(void)setupProgressHandler:(NSInteger)attachmentId atIndex:(NSInteger)index;

@end
