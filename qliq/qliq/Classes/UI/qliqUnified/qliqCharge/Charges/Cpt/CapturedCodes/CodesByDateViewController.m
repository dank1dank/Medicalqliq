//
//  CodesByDateViewController.m
//  CCiPhoneApp
//
//  Created by Marcin Zbijowski on 13/05/2011.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "CodesByDateViewController.h"
#import "EncounterCpt.h"
#import "LightGreyGradientView.h"
#import <QuartzCore/QuartzCore.h>
#import "NSDate+Helper.h"

@implementation CodesByDateViewController
- (void)loadView {
    //[super loadView];
    self.view.backgroundColor = [UIColor blackColor];
    self.navigationItem.rightBarButtonItem = [self rightItemWithTitle:NSLocalizedString(@"Charges by Date", @"Charges by Date") 
                                                          buttonImage:nil
                                                         buttonAction:nil];
    [_patientView setState:UIControlStateDisabled];

    //_dateOfService = 0;

}

#pragma mark -
#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    NSDictionary *dictObjPreviousSection = nil;
    EncounterCpt *previousSectionObj = nil;
    if (section > 0) {
        dictObjPreviousSection = [arrayToDisplay objectAtIndex:section-1];
        previousSectionObj = [dictObjPreviousSection objectForKey:@"cpt"];
    }
    NSDictionary *dictObjThisSection = [arrayToDisplay objectAtIndex:section];
    EncounterCpt *sectionObj = [dictObjThisSection objectForKey:@"cpt"];
    
    if (previousSectionObj == nil || previousSectionObj.dateOfService != sectionObj.dateOfService) {
        return 20.0f;
    }
    return 0.0f;
}

-(UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section {
    NSDictionary *dictObjPreviousSection = nil;
    EncounterCpt *previousSectionObj = nil;
    if (section > 0) {
        dictObjPreviousSection = [arrayToDisplay objectAtIndex:section-1];
        previousSectionObj = [dictObjPreviousSection objectForKey:@"cpt"];
    }
    NSDictionary *dictObjThisSection = [arrayToDisplay objectAtIndex:section];
    EncounterCpt *sectionObj = [dictObjThisSection objectForKey:@"cpt"];
    
    if (previousSectionObj == nil || previousSectionObj.dateOfService != sectionObj.dateOfService) {
        UIView *sectionView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, 20)];
        UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, self.view.bounds.size.width - 20, 20)];
        dateLabel.font = [UIFont boldSystemFontOfSize:13.0f];
        dateLabel.textColor = [UIColor colorWithWhite:0.3019 alpha:1.0f];
        dateLabel.backgroundColor = [UIColor clearColor];
        
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormatter setDateFormat:@"EEE, MMM d, yyyy"];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:sectionObj.dateOfService];
        if (date != nil) {
            [dateFormatter setDoesRelativeDateFormatting:YES];
            [dateFormatter setDateStyle:NSDateFormatterShortStyle];
            NSString *str = [dateFormatter stringFromDate:date];
            NSDate *today = [NSDate dateWithoutTime];
            NSString *todayStr = [dateFormatter stringFromDate:today];
            if (![str isEqualToString:todayStr]) {
                [dateFormatter setDoesRelativeDateFormatting:NO];
                [dateFormatter setDateFormat:@"EEEE, MMM d, yyyy"];
                str = [dateFormatter stringFromDate:date];
                sectionView.backgroundColor = [UIColor colorWithWhite:0.9059 alpha:1.0f];
            }
            else {
                LightGreyGradientView *bgView = [[LightGreyGradientView alloc] initWithFrame:sectionView.bounds];
                bgView.layer.cornerRadius = 0;
                [sectionView addSubview:bgView];
                [bgView release];
            }
            dateLabel.text = str;
            
        }

        [sectionView addSubview:dateLabel];
        [dateLabel release];
        
        return [sectionView autorelease];
    }
    
    
	return nil;
}





@end
