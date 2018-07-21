//
//  GenericListViewController.h
//  CCiPhoneApp
//
//  Created by Marcin Zbijowski on 20/05/2011.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QliqBaseViewController.h"

extern NSInteger const kGenericListElementHeight;

@interface GenericListViewController : QliqBaseViewController <UITableViewDelegate, UITableViewDataSource> {
    NSArray *_elements;
    NSString *_rightTitle;
    UITableView *_tableView;
}

@end
