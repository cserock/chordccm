//
//  PlayListViewController.h
//  codex
//
//  Created by Rock Kang on 2014. 5. 11..
//  Copyright (c) 2014년 neosave.me. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "REFrostedViewController.h"
#import "AppDelegate.h"
@interface PlayListViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *songs;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editBarButton;
@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic,retain) UIActivityIndicatorView *activityIndicatorObject;
@property (strong, nonatomic) IBOutlet UITableView *playListTableView;

- (IBAction)showMenu;
- (IBAction)editPlayList;
@end
