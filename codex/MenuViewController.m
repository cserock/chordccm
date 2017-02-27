//
//  MenuViewController.m
//  codex
//
//  Created by Rock Kang on 2014. 5. 11..
//  Copyright (c) 2014년 neosave.me. All rights reserved.
//

#import "MenuViewController.h"
#import "HomeViewController.h"
#import "PlayListViewController.h"
#import "UIViewController+REFrostedViewController.h"
#import "NavigationController.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"

@interface MenuViewController ()
@end

@implementation MenuViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.separatorColor = [UIColor colorWithRed:150/255.0f green:161/255.0f blue:177/255.0f alpha:1.0f];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.opaque = NO;
    self.tableView.backgroundColor = [UIColor clearColor];
    
    // s : ios6 menu background color
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        // here you go with iOS 6
        self.tableView.backgroundColor = [UIColor whiteColor];
    }
    // e : ios6 menu background color
    
    
    self.tableView.tableHeaderView = ({
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 80.0f)];
        
        /*
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 40, 100, 100)];
        imageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        imageView.image = [UIImage imageNamed:@"avatar.jpg"];
        imageView.layer.masksToBounds = YES;
        imageView.layer.cornerRadius = 50.0;
        imageView.layer.borderColor = [UIColor whiteColor].CGColor;
        imageView.layer.borderWidth = 3.0f;
        imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        imageView.layer.shouldRasterize = YES;
        imageView.clipsToBounds = YES;
        */
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, 0, 24)];
//        label.text = [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:@"CFBundleDisplayName"];
        label.text = [NSString stringWithFormat:@"%@", NSLocalizedString(@"ChordCCM", nil)];
        label.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:18];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor colorWithRed:62/255.0f green:68/255.0f blue:75/255.0f alpha:1.0f];
        [label sizeToFit];
        label.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        
//        [view addSubview:imageView];
        [view addSubview:label];
        view;
    });
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark -
#pragma mark UITableView Delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [UIColor colorWithRed:62/255.0f green:68/255.0f blue:75/255.0f alpha:1.0f];
    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:15];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)sectionIndex
{
    if (sectionIndex == 0){
        return nil;
    } else {
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 34)];
        view.backgroundColor = [UIColor colorWithRed:167/255.0f green:167/255.0f blue:167/255.0f alpha:0.6f];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 8, 0, 0)];
        
        if (sectionIndex == 1){
            label.text = NSLocalizedString(@"Settings", nil);

        } else if (sectionIndex == 2){
            label.text = NSLocalizedString(@"Invite Friend", nil);

    //    label.font = [UIFont systemFontOfSize:15];
        }
        [label setFont:[UIFont fontWithName: @"HelveticaNeue-Medium" size: 13]];
        
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor clearColor];
        [label sizeToFit];
        [view addSubview:label];
        
        return view;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)sectionIndex
{
    if (sectionIndex == 0)
        return 0;
    
    return 30;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UINavigationController *navigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"contentController"];
    
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    
    GAIDictionaryBuilder *gBuilder = nil;
    
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        
        gBuilder = [GAIDictionaryBuilder createEventWithCategory:@"ui_action"     // Event category (required)
                                                          action:@"menu_press"  // Event action (required)
                                                           label:@"Home"          // Event label
                                                           value:nil];
        
        HomeViewController *homeViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"homeController"];
        navigationController.viewControllers = @[homeViewController];
    } else if (indexPath.section == 0 && indexPath.row == 1) {
        
        gBuilder = [GAIDictionaryBuilder createEventWithCategory:@"ui_action"     // Event category (required)
                                                          action:@"menu_press"  // Event action (required)
                                                           label:@"Play List"          // Event label
                                                           value:nil];
        
        PlayListViewController *playListViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"playListController"];
        navigationController.viewControllers = @[playListViewController];
    } else if (indexPath.section == 1 && indexPath.row == 0) {
        
        gBuilder = [GAIDictionaryBuilder createEventWithCategory:@"ui_action"     // Event category (required)
                                                          action:@"menu_press"  // Event action (required)
                                                           label:@"Feedback"          // Event label
                                                           value:nil];
        
        [self.frostedViewController feedback];
        
//        SettingViewController *settingViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"settingController"];
//        navigationController.viewControllers = @[settingViewController];
    } else if (indexPath.section == 1 && indexPath.row == 1) {
        
        gBuilder = [GAIDictionaryBuilder createEventWithCategory:@"ui_action"     // Event category (required)
                                                          action:@"menu_press"  // Event action (required)
                                                           label:@"Reviews"          // Event label
                                                           value:nil];
        
        [self.frostedViewController goReview];
        
        //        SettingViewController *settingViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"settingController"];
        //        navigationController.viewControllers = @[settingViewController];
    } else if (indexPath.section == 2 && indexPath.row == 0) {
        
        gBuilder = [GAIDictionaryBuilder createEventWithCategory:@"ui_action"     // Event category (required)
                                                          action:@"menu_press"  // Event action (required)
                                                           label:@"Kakao"          // Event label
                                                           value:nil];
        
        [self.frostedViewController inviteKakao];
        
    } else if (indexPath.section == 2 && indexPath.row == 1) {
        
        gBuilder = [GAIDictionaryBuilder createEventWithCategory:@"ui_action"     // Event category (required)
                                                          action:@"menu_press"  // Event action (required)
                                                           label:@"Facebook"          // Event label
                                                           value:nil];
        
        [self.frostedViewController inviteFB];
    }
    
    if(gBuilder){
        [tracker send:[gBuilder build]];    // Event value
    }
    
    self.frostedViewController.contentViewController = navigationController;
    [self.frostedViewController hideMenuViewController];
}

#pragma mark -
#pragma mark UITableView Datasource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 42;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    if (sectionIndex == 0){
        return 2;
    } else if (sectionIndex == 1){
        return 2;
    } else {
        return 2;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    if (indexPath.section == 0) {
        NSArray *titles = @[NSLocalizedString(@"Home", nil), NSLocalizedString(@"Play List", nil), ];
        cell.textLabel.text = titles[indexPath.row];
    } else if (indexPath.section == 1) {
        NSArray *titles = @[NSLocalizedString(@"Feedback", nil), NSLocalizedString(@"Reviews", nil)];
        cell.textLabel.text = titles[indexPath.row];
    } else if (indexPath.section == 2) {
        NSArray *titles = @[NSLocalizedString(@"Kakao", nil), NSLocalizedString(@"Facebook", nil)];
        cell.textLabel.text = titles[indexPath.row];
    }
    
    return cell;
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
