//
//  HomeViewController.m
//  codex
//
//  Created by Rock Kang on 2014. 5. 12..
//  Copyright (c) 2014년 neosave.me. All rights reserved.
//

#import "HomeViewController.h"
#import "SongInfo.h"
#import "SongInfoCell.h"
#import "SongDetailViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"

#define DATABASE_NAME @"codex.rdb"

@interface HomeViewController ()

@end

@implementation HomeViewController

FMDatabase *_database;
NSArray *searchResults;

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
    
    // s : GA
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Home"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    // e : GA
    
    [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:@"CFBundleDisplayName"];
    
    NSString *homeTitle = [NSString stringWithFormat:@"%@", NSLocalizedString(@"ChordCCM", nil)];
    self.navigationItem.title = homeTitle;
    
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    _songs = [[NSMutableArray alloc] init];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex: 0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:DATABASE_NAME];
    _database = [FMDatabase databaseWithPath:path];
    
    NSString *sql = @"SELECT * FROM song_info ORDER BY song_info_id ;";
    [_database open];
    
    FMResultSet *results = [_database executeQuery:sql];
    while ([results next])
    {
        
        // insert into an object
        SongInfo *songInfo = [[SongInfo alloc] init];
        
        if (songInfo) {
            
            songInfo.song_info_id = [results intForColumnIndex:0];
            songInfo.song_number = [results intForColumnIndex:1];
            songInfo.song_title = [results stringForColumnIndex:2];
            songInfo.category_1 = [results intForColumnIndex:3];
            songInfo.category_2 = [results intForColumnIndex:4];
            songInfo.song_lyric_start = [results stringForColumnIndex:5];
            songInfo.song_lyric_refrain = [results stringForColumnIndex:6];
            songInfo.song_lyric_keyword = [results stringForColumnIndex:7];
            songInfo.beat = [results stringForColumnIndex:8];
            songInfo.chord = [results stringForColumnIndex:9];
            songInfo.chord_pitch = [results stringForColumnIndex:10];
            songInfo.chord_option = [results stringForColumnIndex:11];
            songInfo.bar_count = [results intForColumnIndex:12];
            songInfo.lyric_count = [results intForColumnIndex:13];
            songInfo.pitch_count = 0;
            
            [_songs addObject:songInfo];
        }
        
//        NSLog(@"%d, %d, %@, %@, %@, %@, %@", [results intForColumnIndex:0], [results intForColumnIndex:1], [results stringForColumnIndex:2], [results stringForColumnIndex:8], [results stringForColumnIndex:9], [results stringForColumnIndex:10], [results stringForColumnIndex:11]);
    }
    [_database close];
    
    self.sections = [[NSMutableDictionary alloc] init];
    
    BOOL found;
    
    
    // Loop through the books and create our keys
    for (SongInfo *songInfo in _songs)
    {
        NSString *c = [[self GetUTF8String:songInfo.song_title] substringToIndex:1];
        found = NO;
        
        for (NSString *str in [self.sections allKeys])
        {
            if ([str isEqualToString:c])
            {
                found = YES;
            }
        }
        
        if (!found)
        {
            [self.sections setValue:[[NSMutableArray alloc] init] forKey:c];
        }
    }
    
    
    // Loop again and sort the books into their respective keys
    for (SongInfo *songInfo in _songs)
    {
        [[self.sections objectForKey:[[self GetUTF8String:songInfo.song_title] substringToIndex:1]] addObject:songInfo];
    }
    
    // Sort each section array
    for (NSString *key in [self.sections allKeys])
    {
        [[self.sections objectForKey:key] sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"song_title" ascending:YES]]];
    }
//    NSLog( @"%@", self.sections );
    
    self.sectionsForSearch = [[NSMutableDictionary alloc] init];
    
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
     if (tableView == self.searchDisplayController.searchResultsTableView) {
         return [[self.sectionsForSearch allKeys] count];
     } else {
         return [[self.sections allKeys] count];
     }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [[[self.sectionsForSearch allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:section];
    } else {
        return [[[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:section];
    }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (tableView == self.searchDisplayController.searchResultsTableView) {
//        return [searchResults count];
        return [[self.sectionsForSearch valueForKey:[[[self.sectionsForSearch allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:section]] count];
    } else {
        return [[self.sections valueForKey:[[[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:section]] count];
//        return [_songs count];
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [[self.sectionsForSearch allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    } else {
        return [[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 52;
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
    if (tableView == self.searchDisplayController.searchResultsTableView) {
//        songInfo = [searchResults objectAtIndex:indexPath.row];
        songInfo = [[self.sectionsForSearch valueForKey:[[[self.sectionsForSearch allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    } else {
//        songInfo = [_songs objectAtIndex:indexPath.row];
        songInfo = [[self.sections valueForKey:[[[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    }

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
    return cell;
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"(song_title contains[c] %@) OR (song_lyric_start contains[c] %@) OR (song_lyric_refrain contains[c] %@)", searchText, searchText, searchText];
    searchResults = [_songs filteredArrayUsingPredicate:resultPredicate];
    [self.sectionsForSearch removeAllObjects];
    
    BOOL found;
    
    // Loop through the books and create our keys
    for (SongInfo *songInfo in searchResults)
    {
        NSString *c = [[self GetUTF8String:songInfo.song_title] substringToIndex:1];
        found = NO;
        for (NSString *str in [self.sectionsForSearch allKeys])
        {
            if ([str isEqualToString:c])
            {
                found = YES;
            }
        }
        
        if (!found)
        {
            [self.sectionsForSearch setValue:[[NSMutableArray alloc] init] forKey:c];
        }
    }
    
    
    // Loop again and sort the books into their respective keys
    for (SongInfo *songInfo in searchResults)
    {
        [[self.sectionsForSearch objectForKey:[[self GetUTF8String:songInfo.song_title] substringToIndex:1]] addObject:songInfo];
    }
    
    // Sort each section array
    for (NSString *key in [self.sectionsForSearch allKeys])
    {
        [[self.sectionsForSearch objectForKey:key] sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"song_title" ascending:YES]]];
    }
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString
                               scope:[[self.searchDisplayController.searchBar scopeButtonTitles]
                                      objectAtIndex:[self.searchDisplayController.searchBar
                                                     selectedScopeButtonIndex]]];
    
    return YES;
}

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


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showSongDetail"]) {
        NSIndexPath *indexPath = nil;
        SongInfo *songInfo = nil;
        
        if (self.searchDisplayController.active) {
            
            indexPath = [self.searchDisplayController.searchResultsTableView indexPathForSelectedRow];
//            songInfo = [searchResults objectAtIndex:indexPath.row];
            
            songInfo = [[self.sectionsForSearch valueForKey:[[[self.sectionsForSearch allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
            
        } else {

            indexPath = [self.tableView indexPathForSelectedRow];
//            songInfo = [_songs objectAtIndex:indexPath.row];
            songInfo = [[self.sections valueForKey:[[[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];            
        }
        
        SongDetailViewController *destViewController = segue.destinationViewController;
        destViewController.songInfo = songInfo;
    }
}

- (NSString *)GetUTF8String:(NSString *)hanggulString {
    
    
    const char *tmp = [hanggulString cStringUsingEncoding:NSUTF8StringEncoding];
    
    NSString *textResult = @"";
    
    // 한글 체크
    if(hanggulString.length != strlen(tmp)){
        
        NSArray *chosung = [[NSArray alloc] initWithObjects:@"ㄱ",@"ㄲ",@"ㄴ",@"ㄷ",@"ㄸ",@"ㄹ",@"ㅁ",@"ㅂ",@"ㅃ",@"ㅅ",@"ㅆ",@"ㅇ",@"ㅈ",@"ㅉ",@"ㅊ",@"ㅋ",@"ㅌ",@"ㅍ",@"ㅎ",nil];
        
        NSArray *jungsung = [[NSArray alloc] initWithObjects:@"ㅏ",@"ㅐ",@"ㅑ",@"ㅒ",@"ㅓ",@"ㅔ",@"ㅕ",@"ㅖ",@"ㅗ",@"ㅘ",@"ㅙ",@"ㅚ",@"ㅛ",@"ㅜ",@"ㅝ",@"ㅞ",@"ㅟ",@"ㅠ",@"ㅡ",@"ㅢ",@"ㅣ",nil];
        
        NSArray *jongsung = [[NSArray alloc] initWithObjects:@"",@"ㄱ",@"ㄲ",@"ㄳ",@"ㄴ",@"ㄵ",@"ㄶ",@"ㄷ",@"ㄹ",@"ㄺ",@"ㄻ",@"ㄼ",@"ㄽ",@"ㄾ",@"ㄿ",@"ㅀ",@"ㅁ",@"ㅂ",@"ㅄ",@"ㅅ",@"ㅆ",@"ㅇ",@"ㅈ",@"ㅊ",@"ㅋ",@" ㅌ",@"ㅍ",@"ㅎ",nil];
        
        
        
        for (int i=0;i<[hanggulString length];i++) {
            
            NSInteger code = [hanggulString characterAtIndex:i];
            
            if (code >= 44032 && code <= 55203) {
                
                NSInteger uniCode = code - 44032;
                
                NSInteger chosungIndex = uniCode / 21 / 28;
                
                NSInteger jungsungIndex = uniCode % (21 * 28) / 28;
                
                NSInteger jongsungIndex = uniCode % 28;
                
                textResult = [NSString stringWithFormat:@"%@%@%@%@", textResult, [chosung objectAtIndex:chosungIndex], [jungsung objectAtIndex:jungsungIndex], [jongsung objectAtIndex:jongsungIndex]];
                
            }
            
        }

    } else {
        textResult = hanggulString;
    }
    
    return textResult;
}

@end
