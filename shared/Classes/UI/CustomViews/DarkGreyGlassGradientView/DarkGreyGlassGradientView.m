//
//  DarkGreyGlassGradientView.m
//  CCiPhoneApp
//
//  Created by Marcin Zbijowski on 06/05/2011.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "DarkGreyGlassGradientView.h"
#import <QuartzCore/QuartzCore.h>

@implementation DarkGreyGlassGradientView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        static NSMutableArray *darkGreyGlassColors = nil;
        if (darkGreyGlassColors == nil) {
            darkGreyGlassColors = [[NSMutableArray alloc] initWithCapacity:3];
            UIColor *color = nil;
            color = [UIColor colorWithRed:0.2392 green:0.2353 blue:0.2431 alpha:1.0];
            [darkGreyGlassColors addObject:(id)[color CGColor]];
            color = [UIColor colorWithRed:0.3451 green:0.3451 blue:0.3529 alpha:1.0];
            [darkGreyGlassColors addObject:(id)[color CGColor]];
            color = [UIColor colorWithRed:0.2196 green:0.2196 blue:0.2196 alpha:1.0];
            [darkGreyGlassColors addObject:(id)[color CGColor]];
            color = [UIColor colorWithRed:0.0863 green:0.0863 blue:0.0902 alpha:1.0];
            [darkGreyGlassColors addObject:(id)[color CGColor]];
        }
        [(CAGradientLayer *)self.layer setColors:darkGreyGlassColors];
        [(CAGradientLayer *)self.layer setLocations:[NSArray arrayWithObjects:
                                                     [NSNumber numberWithFloat:0.0], 
                                                     [NSNumber numberWithFloat:0.48], 
                                                     [NSNumber numberWithFloat:0.51], 
                                                     [NSNumber numberWithFloat:1.0], nil]];
    }
    return self;
}

+ (Class)layerClass {
    
    return [CAGradientLayer class];
}

- (void)dealloc
{
    [super dealloc];
}

@end
