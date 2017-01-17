//
//  PlayListViewController.m
//  codex
//
//  Created by Rock Kang on 2014. 5. 11..
//  Copyright (c) 2014년 neosave.me. All rights reserved.
//

#import "PlayListViewController.h"
#import "SongInfo.h"
#import "SongInfoCell.h"
#import "PlayDetailViewController.h"

#define NSLog //

@interface PlayListViewController ()

@end

@implementation PlayListViewController

- (IBAction)editPlayList
{
    NSLog(@"editPlayList");
    
    [self.tableView setEditing:!self.tableView.editing animated:YES];
    
    if (self.tableView.editing){
        
        [self.navigationItem.rightBarButtonItem setImage:[UIImage imageNamed:@"icon-edit-ok.png"]];
        
//        [self.navigationItem.rightBarButtonItem setTitle:@"Done"];
    } else {
        [self.navigationItem.rightBarButtonItem setImage:[UIImage imageNamed:@"icon-edit.png"]];
//        [self.navigationItem.rightBarButtonItem setTitle:@"Edit"];
    }
    
}

- (IBAction)showMenu
{
    // Dismiss keyboard (optional)
    //
    [self.view endEditing:YES];
    [self.frostedViewController.view endEditing:YES];
    
    // Present the view controller
    //
    [self.frostedViewController presentMenuViewController];
}

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
    
    // s : ios6 navigator bar color
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        // here you go with iOS 6
        self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:240.0/255.0 green:115.0/255.0 blue:106.0/255.0 alpha:1.0];
    }
    // e : ios6 navigator bar color
    
    NSString *homeTitle = [NSString stringWithFormat:@"%@", NSLocalizedString(@"Play List", nil)];
    self.navigationItem.title = homeTitle;
    
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    _songs = [[NSMutableArray alloc] init];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *bookmarkList = [defaults objectForKey:@"bookmarkList"];
    
    if(bookmarkList){
        
        for( NSDictionary *dict in bookmarkList ) {
            
            // insert into an object
            SongInfo *songInfo = [[SongInfo alloc] init];
            
            if (songInfo) {
                
                songInfo.song_info_id = [(NSNumber *) [dict objectForKey:@"songInfo.song_info_id"] intValue];
                songInfo.song_number = [(NSNumber *) [dict objectForKey:@"songInfo.song_number"] intValue];
                songInfo.song_title = [dict objectForKey:@"songInfo.song_title"];
                songInfo.category_1 = [(NSNumber *) [dict objectForKey:@"songInfo.category_1"] intValue];
                songInfo.category_2 = [(NSNumber *)[dict objectForKey:@"songInfo.category_2"] intValue];
                songInfo.song_lyric_start = [dict objectForKey:@"songInfo.song_lyric_start"];
                songInfo.song_lyric_refrain = [dict objectForKey:@"songInfo.song_lyric_refrain"];
                songInfo.song_lyric_keyword = [dict objectForKey:@"songInfo.song_lyric_keyword"];
                songInfo.beat = [dict objectForKey:@"songInfo.beat"];
                songInfo.chord = [dict objectForKey:@"songInfo.chord"];
                songInfo.chord_pitch = [dict objectForKey:@"songInfo.chord_pitch"];
                songInfo.chord_option = [dict objectForKey:@"songInfo.chord_option"];
                songInfo.bar_count = [(NSNumber *) [dict objectForKey:@"songInfo.bar_count"] intValue];
                songInfo.lyric_count = [(NSNumber *) [dict objectForKey:@"songInfo.lyric_count"] intValue];
                songInfo.pitch_count = [(NSNumber *) [dict objectForKey:@"songInfo.pitch_count"] intValue];
                
                
                [_songs addObject:songInfo];
                
                NSLog(@"PlayListViewController %d, %@, %@, %@", songInfo.song_info_id, songInfo.song_title, songInfo.chord, songInfo.beat);
            }   
        }
    }
    
    _activityIndicatorObject = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    // Set Center Position for ActivityIndicator
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    _activityIndicatorObject.center = CGPointMake(screenRect.size.width/2, (screenRect.size.height/2)-64);
    _activityIndicatorObject.color = [UIColor redColor];
    
    // Add ActivityIndicator to your view
    [self.view addSubview:_activityIndicatorObject];
    
    
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 52;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [_songs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SongInfoCell";
    SongInfoCell *cell = (SongInfoCell *)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if (cell == nil) {
        cell = [[SongInfoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    SongInfo *songInfo = nil;
    songInfo = [_songs objectAtIndex:indexPath.row];
    
    cell.titleLabel.text = songInfo.song_title;
    cell.chordLabel.text = songInfo.chord;
    cell.chordLabel.layer.cornerRadius = 5;
    
    cell.chordPitchLabel.text = [_appDelegate getChordPitchString:songInfo.chord_pitch];
    //    cell.chordPitchLabel.text = @"♯";
    //    cell.chordPitchLabel.text = @"♭";
    
    cell.chordPitchLabel.layer.cornerRadius = 5;
    
    if([[_appDelegate getChordPitchString:songInfo.chord_pitch] isEqualToString:@""]){
        cell.chordPitchLabel.hidden = TRUE;
    }
    
    //    cell.chordOptionLabel.text = songInfo.chord_option;
    cell.beatLabel.text = songInfo.beat;
    cell.beatLabel.layer.cornerRadius = 5;
    cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-detail-song.png"]];
    
    /*
	cell.titleLabel.text = songInfo.song_title;
    cell.chordLabel.text = songInfo.chord;
    cell.chordPitchLabel.text = [_appDelegate getChordPitchString:songInfo.chord_pitch];
//    cell.chordOptionLabel.text = songInfo.chord_option;
    cell.beatLabel.text = songInfo.beat;
    cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-detail-song.png"]];
    */
    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        [_songs removeObjectAtIndex:indexPath.row];
        
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
       
        // Additional code to configure the Edit Button, if any
        if (_songs.count == 0) {
            [self.navigationItem.rightBarButtonItem setTitle:@"Edit"];
            self.navigationItem.rightBarButtonItem.enabled = NO;
        }
        
        [self save];
        
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"didSelectRowAtIndexPath : %ld", (long)indexPath.row);
    
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        [NSThread detachNewThreadSelector:@selector(threadStartAnimating:) toTarget:self withObject:nil];
    }
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
 
//    NSLog(@"%ld: %ld", (long)fromIndexPath.row , (long)toIndexPath.row);
    
//    [_songs exchangeObjectAtIndex:fromIndexPath.row withObjectAtIndex:toIndexPath.row];
//    [self save];

    SongInfo *songInfo = [[SongInfo alloc] init];
    
    if(songInfo){
        songInfo = [_songs objectAtIndex:fromIndexPath.row];
        [_songs removeObjectAtIndex:fromIndexPath.row];
        [_songs insertObject:songInfo atIndex:toIndexPath.row];
        [self save];
    }

}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}

- (void) save {
    NSMutableArray *newBookmarkList = [[NSMutableArray alloc] init];
    for( SongInfo *songInfo in _songs ) {
        
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt: songInfo.song_info_id], @"songInfo.song_info_id",
                              [NSNumber numberWithInt: songInfo.song_number], @" songInfo.song_number",
                              songInfo.song_title, @"songInfo.song_title",
                              [NSNumber numberWithInt: songInfo.category_1], @"songInfo.category_1",
                              [NSNumber numberWithInt: songInfo.category_2], @"songInfo.category_2",
                              songInfo.song_lyric_start, @"songInfo.song_lyric_start",
                              songInfo.song_lyric_refrain, @"songInfo.song_lyric_refrain",
                              songInfo.song_lyric_keyword, @"songInfo.song_lyric_keyword",
                              songInfo.beat, @"songInfo.beat",
                              songInfo.chord, @"songInfo.chord",
                              songInfo.chord_pitch, @"songInfo.chord_pitch",
                              songInfo.chord_option, @"songInfo.chord_option",
                              [NSNumber numberWithInt: songInfo.bar_count], @"songInfo.bar_count",
                              [NSNumber numberWithInt: songInfo.lyric_count], @"songInfo.lyric_count",
                              [NSNumber numberWithInt: songInfo.pitch_count], @"songInfo.pitch_count",
                              nil];
        
        [newBookmarkList addObject:dict];
    }
    
    NSArray *bookmarkList = [newBookmarkList copy];
    NSLog(@"bookmarkList.count : %lu", (unsigned long)bookmarkList.count);
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:bookmarkList forKey:@"bookmarkList"];
    [defaults synchronize];
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showPlayDetail"]) {
        
        NSIndexPath *indexPath = nil;
        SongInfo *songInfo = nil;
        
        indexPath = [self.tableView indexPathForSelectedRow];
        songInfo = [_songs objectAtIndex:indexPath.row];
        
        PlayDetailViewController *destViewController = segue.destinationViewController;
        destViewController.bookmarkIndex = indexPath.row;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [_activityIndicatorObject stopAnimating];
}


- (void) threadStartAnimating:(id)data {
    [_activityIndicatorObject startAnimating];
}

@end
