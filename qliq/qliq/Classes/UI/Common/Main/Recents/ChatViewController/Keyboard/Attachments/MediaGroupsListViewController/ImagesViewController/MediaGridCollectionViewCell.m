//
//  ImagesTableViewCell.m
//  qliqConnect
//
//  Created by Paul Bar on 12/15/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import "MediaGridCollectionViewCell.h"

#import "MediaGridSelectionIndicatorView.h"
//#import <QuartzCore/QuartzCore.h>

#define VIEWS_OFFSET 10.0

@interface MediaGridCollectionViewCell() <UIGestureRecognizerDelegate, ProgressObserver>

@property (nonatomic, strong) MediaGridSelectionIndicatorView *selectionIndicatorView;
@property (nonatomic, strong) UIProgressView *progressBar;
@property (nonatomic, strong) UILabel * fileNameLabel;

@end

@implementation MediaGridCollectionViewCell

- (void)setName:(NSString *)name {

//    NSRange r = [name rangeOfString:@"_"];
//
//    if (r.length == 1){
//        r.length = r.location + 1;
//        r.location = 0;
//        name = [name stringByReplacingCharactersInRange:r withString:@""];
//    }
//
//    self.fileNameLabel.text = name;
    self.mediafileNameLabel.text = name;
}

- (void)setSelected:(BOOL)selected {
    
    [super setSelected:selected];
    
    if(selected) {
        [self bringSubviewToFront:self.selectionIndicatorView];
        [self.selectionIndicatorView show];
    }else{
        [self.selectionIndicatorView hide];
        [self sendSubviewToBack:self.selectionIndicatorView];
    }
}

-(void) setProgressBarHidden:(BOOL)hidden
{
    [self.progressBar setHidden:hidden];
}

- (void) setupProgressHandler:(NSInteger)attachmentId atIndex:(NSInteger)index
{

}

#pragma mark - Progress Observing

- (void)progressHandler:(ProgressHandler *)progressHandler didChangeProgress:(CGFloat)progress
{

}

- (void)progressHandler:(ProgressHandler *)progressHandler didChangeState:(ProgressState)state
{

}

@end
