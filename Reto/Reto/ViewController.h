//
//  ViewController.h
//  Reto
//
//  Created by Pablo García on 9/6/17.
//  Copyright © 2017 Pablo García. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reachability.h"
#import "ServiceObject.h"
#import "RssResponse.h"
#import "MBProgressHUD.h"
#import "UIImageViewAsync.h"
#import "AppDelegate.h"


@interface ViewController : UIViewController<UIScrollViewDelegate,UITableViewDataSource, UITableViewDelegate,UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating, UIGestureRecognizerDelegate>{
    
@private
    Reachability *internetReachable;
    UIRefreshControl *refreshControl;
    ServiceObject *serviceObject;
    RssResponse *rssResponse;
    MBProgressHUD *HUD;
    CGFloat sizeFontDescription;
    UIImage *img;
    UIView *viewKeyboard;
}

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) NSMutableArray *items;
@property (strong, nonatomic) ItemBean *itemSelected;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonAtras;
@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (strong, nonatomic) IBOutlet UILabel *lbl_detail_title;
@property (strong, nonatomic) IBOutlet UILabel *lbl_detail_link;
@property (strong, nonatomic) IBOutlet UIImageViewAsync *iv_detail;
@property (strong, nonatomic) IBOutlet UITextView *ta_detail_desc;

@property (nonatomic, strong) UISearchController * searchController;
@property (nonatomic, strong) NSMutableArray * filteredItems;
@property (nonatomic, weak) NSArray * displayedItems;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *constraint_pt_1;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *constraint_pt_2;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *constraint_pt_3;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *constraint_pt_4;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *constraint_pt_5;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *constraint_pt_6;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *constraint_pt_7;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *constraint_pt_8;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *constraint_land_1;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *constraint_land_2;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *constraint_land_3;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *constraint_land_4;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *constraint_land_5;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *constraint_land_6;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *constraint_land_7;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *constraint_land_8;

- (IBAction)clickButtonAtras:(id)sender;
@end

