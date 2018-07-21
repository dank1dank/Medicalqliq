//
//  ICDListViewController.h
//  CCiPhoneApp
//
//  Created by Marcin Zbijowski on 03/05/2011.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Icd;
@class FMResultSet;

@protocol ICDListViewDelegate

@required
- (void)saveSelectedIcd:(id)selectedIcd;
- (void)didSelectObj:(id)selectedIcd;
- (void)shouldPresentDetails:(Icd *)selectedIcd;

@end

@interface ObjectListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate> {
    
	UITableView *tblIcdCodes;
	UIToolbar *toolbarIcdList;
	//---search---
	IBOutlet UISearchBar *searchBar;
	NSMutableArray *searchResult;
	NSMutableArray *shortList;

	NSMutableArray *selectedObjArray;
	id selectedObj;
	NSInteger selectedRow;
	NSInteger selectedCount;
	
	//instance variables
    NSInteger encounterCptId;
    double physicianNpi;
	BOOL isPrimary;
    
    id _delegate;
    
	NSInteger tapCount;
	NSIndexPath *tableSelection;
	
    FMResultSet* fmSearchResult;
}

//---search---
@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, readwrite) NSInteger encounterCptId;
@property (nonatomic, readwrite) double physicianNpi;
@property (nonatomic, retain) NSMutableArray *listOfIcdCodes;
@property (nonatomic, readwrite) BOOL isPrimary;
@property (nonatomic, readonly) id selectedObj;
@property (nonatomic, retain) NSMutableArray *selectedObjArray;
@property (nonatomic, assign, getter = isShowingCPTs) BOOL showingCPTs;

@property (nonatomic, retain) id<ICDListViewDelegate> delegate;

- (void) doneSearching: (id)sender;
- (void) searchIcdTableView;
- (void) doneSelectIcd: (id)sender;
- (void) cancelSelectIcd:(id)sender;
- (void) reloadTableData;
@end
