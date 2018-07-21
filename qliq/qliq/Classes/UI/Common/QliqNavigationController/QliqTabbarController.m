//
//  QliqTabbarItems.m
//  qliq
//
//  Created by Aleksey Garbarev on 20.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqTabbarController.h"
#import "QliqNavigationController.h"

//#import "ContactsListViewController.h"
//#import "ConversationListViewController.h"

#import "MediaGroupsListViewController.h"
//#import "ComingSoonViewController.h"
#import "InvitationService.h"
#import "ContactDBService.h"
//#import "SettingsTableViewController.h"

NSString *QliqBarButtonIdRecentChat = @"QliqBarButtonIdRecentChat";
NSString *QliqBarButtonIdFavorites  = @"QliqBarButtonIdFavorites";
NSString *QliqBarButtonIdContacts   = @"QliqBarButtonIdContacts";
NSString *QliqBarButtonIdMedia      = @"QliqBarButtonIdMedia";
NSString *QliqBarButtonIdSettings    = @"QliqBarButtonIdSettings";

@interface QliqTabbarController()

- (Class) classForIdentifier:(NSString *) identifier;

@end

@implementation QliqTabbarController{
    __unsafe_unretained QliqNavigationController * navigationController;
}

- (void) setNavigationController:(QliqNavigationController *) _navController{
    navigationController = _navController;
}

- (void) dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (QliqTabbarController *) currentController {
    static dispatch_once_t pred;
    static QliqTabbarController *shared = nil;
    dispatch_once(&pred, ^{
        shared = [[QliqTabbarController alloc] init];
        /*
        [[NSNotificationCenter defaultCenter] addObserver:shared selector:@selector(chatBadgeValueChanged:) name:ChatBadgeValueNotification object:nil];
         */
        [[NSNotificationCenter defaultCenter] addObserver:shared selector:@selector(chatBadgeValueChanged:) name:InvitationServiceInvitationsChangedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:shared selector:@selector(chatBadgeValueChanged:) name:ContactServiceNewContactNotification object:nil];
    });
    return shared;
}



- (void) updateBadgeValuesForButtons:(NSArray *) items{
    
    for (QliqBarButtonItem * item in items){
        //Update badge for recent chat
        if ([item isKindOfClass:[QliqBarButtonItem class]] && [item.targetIdentifier isEqualToString:QliqBarButtonIdRecentChat]){
/*
            item.badgeValue = [ChatMessage unreadMessagesCount];
            DDLogSupport(@"New Recents Badge Value: %lu", (unsigned long)item.badgeValue);
 */
        }
       
        if ([item isKindOfClass:[QliqBarButtonItem class]] && [item.targetIdentifier isEqualToString:QliqBarButtonIdContacts]){
            
            item.badgeValue = [[InvitationService sharedService] getPendingInvitationCount] + [[ContactDBService sharedService] getNewContactsCount];   
        }
        
        if ([item isKindOfClass:[QliqBarButtonItem class]] && [item.targetIdentifier isEqualToString:QliqBarButtonIdSettings]){
            
            NSString *currentBuildVersion = [AppDelegate currentBuildVersion];
            NSString *availableVersion = [appDelegate availableVersion];
            item.badgeValue = (NSOrderedAscending == [currentBuildVersion compare:availableVersion options:NSNumericSearch] ? 1 : 0);
        }
        
        //Update badge for buttons with another ID will be below..
        //..
    }
}


- (void) chatBadgeValueChanged:(NSNotification *) notif{
    [self updateBadgeValuesForButtons:[navigationController visibleViewController].toolbarItems];
}


#pragma mark - QliqTabbar protocol

- (void) qliqNavigationController:(QliqNavigationController *)_navController didChangeVisibleController:(UIViewController *)viewController{
    for (QliqBarButtonItem * item in [viewController toolbarItems]){
        if ([item isKindOfClass:[QliqBarButtonItem class]]){
            item.enabled = ![viewController isKindOfClass:[self classForIdentifier:item.targetIdentifier]];
        }
    }
    [self updateBadgeValuesForButtons:[viewController toolbarItems]];
}

- (CGFloat)heightForTabbarInNavigationController:(QliqNavigationController *)_navController{
    return kBarButtonHeight + 1;
}


#pragma mark -

- (void)qliqBarButtomItemPressed:(QliqBarButtonItem *)item{
    if ([item.targetIdentifier isEqualToString:QliqBarButtonIdFavorites]){
        /*
        
        [navigationController switchToViewControllerByClass:[self classForIdentifier:item.targetIdentifier]animated:NO initializationBlock:^UIViewController *{
            ContactsListViewController * listViewController = [[ContactsListViewController alloc] init];
            listViewController.contactGroup = [[QliqFavoritesContactGroup alloc] init];
            return listViewController;
        }];
        */
        
    }else{
        [navigationController switchToViewControllerByClass:[self classForIdentifier:item.targetIdentifier] animated:NO];
    }
}

#pragma mark - Common tabbar

+ (UIBarButtonItem *) separator{
    
    UIImageView * imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tabBarSeparator"]];
    imgView.frame = CGRectMake(0, 1, 2, kBarButtonHeight);
    UIBarButtonItem * item = [[UIBarButtonItem alloc] initWithCustomView:imgView];
    return item;
    
}

+ (NSArray *) tabbarItemsWithSeparatorsFromItems:(NSArray *) toolbar_items{
    UIBarButtonItem* noSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    noSpace.width = -10;
    UIBarButtonItem* beginNoSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    beginNoSpace.width = -15;
    
    NSMutableArray * items = [[NSMutableArray alloc] init];
    [items addObject:beginNoSpace];
//    [items addObject:[QliqTabbarController separator]];
//    [items addObject:noSpace];
    
    for (UIBarButtonItem * item in toolbar_items){
        [items addObject:item];
        [items addObjectsFromArray:[NSArray arrayWithObjects:noSpace,[QliqTabbarController separator],noSpace, nil]];
    }
    
    return items;
}

#pragma mark - CommunicationModule tabbar


- (Class) classForIdentifier:(NSString *) identifier{
   /*
    if ([identifier isEqualToString:QliqBarButtonIdRecentChat]) return  [ConversationListViewController class];
    */
    /*
    if ([identifier isEqualToString:QliqBarButtonIdFavorites])  return [ContactsListViewController class];
     */
    if ([identifier isEqualToString:QliqBarButtonIdMedia])      return [MediaGroupsListViewController class];
    /*
    if ([identifier isEqualToString:QliqBarButtonIdContacts])   return [ContactsGroupsListViewController class];
     */
    return nil;
}

//QliqActionPopover * currentPopover;

- (NSArray *) communicationModuleButtons{
    
    QliqBarButtonItem * favorites = [[QliqBarButtonItem alloc] initWithButtonImage:[UIImage imageNamed:@"tabBarButton_favorites.png"] targetIdentifier:QliqBarButtonIdFavorites actionBlock:^(QliqBarButtonItem *item) {
        [self qliqBarButtomItemPressed:item];
    }];
    QliqBarButtonItem * recent = [[QliqBarButtonItem alloc] initWithButtonImage:[UIImage imageNamed:@"tabBarButton_recents.png"] targetIdentifier:QliqBarButtonIdRecentChat actionBlock:^(QliqBarButtonItem *item) {
        [self qliqBarButtomItemPressed:item];
    }];
    QliqBarButtonItem * contacts = [[QliqBarButtonItem alloc] initWithButtonImage:[UIImage imageNamed:@"tabBarButton_contacts.png"]  targetIdentifier:QliqBarButtonIdContacts actionBlock:^(QliqBarButtonItem *item) {
        [self qliqBarButtomItemPressed:item];
    }];
    QliqBarButtonItem * media = [[QliqBarButtonItem alloc] initWithButtonImage:[UIImage imageNamed:@"tabBarButton_media.png"] targetIdentifier:QliqBarButtonIdMedia actionBlock:^(QliqBarButtonItem *item) {
        [self qliqBarButtomItemPressed:item];
    }];
    
    QliqBarButtonItem * settings = [[QliqBarButtonItem alloc] initWithFrame:CGRectMake(0, 0, 62, kBarButtonHeight) buttonStyle:QliqButtonStyleTabBarItem actionBlock:^(QliqBarButtonItem *item) {
        /*
        SettingsTableViewController *tempController = [[SettingsTableViewController alloc] init];
        tempController.previousControllerTitle = NSLocalizedString(@"Back", @"Back");
        [navigationController pushViewController:tempController animated:YES];
         */
    }];
    settings.targetIdentifier = QliqBarButtonIdSettings;
    [settings.button setImage:[UIImage imageNamed:@"TabBarItemList"] forState:UIControlStateNormal];
    [settings.button setTitle:@"Settings" forState:UIControlStateNormal];
    [settings.button setTitleEdgeInsets:UIEdgeInsetsMake(70.0, -150.0, 5.0, 5.0)];

    
    NSArray * buttons = [NSArray arrayWithObjects: favorites, recent, contacts, media, settings, nil];

    return [QliqTabbarController tabbarItemsWithSeparatorsFromItems:buttons];
}

@end
