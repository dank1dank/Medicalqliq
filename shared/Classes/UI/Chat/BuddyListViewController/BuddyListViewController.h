// Created by Developer Toy
//BuddyListView.h

#import <UIKit/UIKit.h>
#import "QliqBaseViewController.h"
#import "BuddyListView.h"

@class Patient_old;
@class Buddy;

@protocol BuddyListViewControllerDelegate <NSObject>

-(void) selectedBuddy:(Buddy*) buddy;

@end

@interface BuddyListViewController : QliqBaseViewController <UITextFieldDelegate,UITableViewDelegate,UITableViewDataSource>
{
	NSArray *buddyList;
	NSMutableArray *searchList;

    BOOL _isContentInset;
    BOOL _isSearching;
	Patient_old *patient;
    
    BuddyListView *buddyListView;
    
    id<BuddyListViewControllerDelegate> delegate_;
}

//@property (nonatomic, retain) Patient *patient;
//@property (nonatomic, retain) Census_old *censusObj;

@property (nonatomic, assign) NSTimeInterval dateOfService;

@property (nonatomic, assign) id<BuddyListViewControllerDelegate> delegate;

@end