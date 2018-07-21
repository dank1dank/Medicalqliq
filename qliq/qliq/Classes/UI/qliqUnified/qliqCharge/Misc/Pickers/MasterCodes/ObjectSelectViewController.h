//
//  ICDSelectViewController.h
//  CCiPhoneApp
//
//  Created by Marcin Zbijowski on 03/05/2011.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ObjectListViewController;
@class Census_old;
@class EncounterCpt;
@class SelectIcdTabView;
@class Icd;
//@class Patient;

@interface ObjectSelectViewController : UIViewController {

    ObjectListViewController *_favoritesController;
    ObjectListViewController *_crosswalkController;
    ObjectListViewController *_masterController;
    
    SelectIcdTabView *mainTabView;
    UIBarButtonItem *_doneItem;
    NSMutableArray *favList;
    NSMutableArray *crosswalkList;
}

@property (nonatomic, assign, getter = isPrimary) BOOL primary;
@property (nonatomic, retain) Census_old *censusObj;
@property (nonatomic, retain) EncounterCpt *sectionObj;
@property (nonatomic, assign) BOOL useCrosswalk;
@property (nonatomic, assign, getter = isShowingCPTs) BOOL showingCPTs;
@property (nonatomic, assign) NSInteger encounterId;
@property (nonatomic, assign) NSInteger superbillId;
@end
