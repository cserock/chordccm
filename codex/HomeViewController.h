//
//  HomeViewController.h
//  codex
//
//  Created by Rock Kang on 2014. 5. 12..
//  Copyright (c) 2014년 neosave.me. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "REFrostedViewController.h"
#import "FMDB.h"
#import "AppDelegate.h"
@interface HomeViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *songs;
@property (nonatomic, strong) FMDatabase *database;
@property (nonatomic, strong) AppDelegate *appDelegate;

@property (nonatomic, strong) NSMutableDictionary *sections;
@property (nonatomic, strong) NSMutableDictionary *sectionsForSearch;

- (IBAction)showMenu;

@end
