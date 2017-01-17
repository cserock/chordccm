//
//  PlayDetailViewController.m
//  codex
//
//  Created by Rock Kang on 2014. 7. 1..
//  Copyright (c) 2014년 neosave.me. All rights reserved.
//

#import "PlayDetailViewController.h"
#import "SongData.h"
#import "Reachability.h"
#import "UIView+Toast.h"
#import "TTTRegexAttributedLabel.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"

#define DATABASE_NAME @"codex.rdb"
#define NSLog //

@interface PlayDetailViewController ()

@end

@implementation PlayDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)backHome {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // s : ios6 navigator bar color
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        // here you go with iOS 6
        self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:240.0/255.0 green:115.0/255.0 blue:106.0/255.0 alpha:1.0];
    }
    // e : ios6 navigator bar color
    
    // s : GA
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"PlayDetail"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    // e : GA
    
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    _startY = 0.0f;
    _lineX = 10.0f;
    _lineHeight = 2.0f;
    _cellHeight = 10.0f;
    _barCountInLine = 4.0f;
    _menuMarginX = 30.0f;
    
    _lineMarginY = 0.0f;
    _lyricHeight = 0.0f;
    
    // init pitch count
    _pitchCount = 0;
    
    _beatAllString = @"";
    _lyric_1_AllString = @"";
    _lyric_2_AllString = @"";
    _lyric_3_AllString = @"";
    _lyric_4_AllString = @"";
    
    _chordArray = @[@"C", @"D", @"E", @"F", @"G", @"A", @"B"];
    
    _playListSongIndex = 0;
    _maxHeight = 0;
    _chordPadding = 0.0f;
    
    _playListSongs = [[NSMutableArray alloc] init];
    
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
                
                
                [_playListSongs addObject:songInfo];
                
//                NSLog(@"PlayDetailViewController %d, %@, %@, %@", songInfo.song_info_id, songInfo.song_title, songInfo.chord, songInfo.beat);
            }
        }
    }
    
    
    NSLog(@"viewDidLoad : bookmarkIndex : %d", _bookmarkIndex);
    
    SongInfo *songInfoForTitle = [_playListSongs objectAtIndex:_bookmarkIndex];
    self.navigationItem.title = songInfoForTitle.song_title;

    _playListSongsCount = [_playListSongs count];
    
    NSLog(@"_playListSongsCount : %d", _playListSongsCount);
    
    
    // Do any additional setup after loading the view.
    if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)){
        _isShowingLandscapeView = YES;
    } else {
        _isShowingLandscapeView = NO;
    }
    
    //    NSLog(@"viewDidLoad : isShowingLandscapeView : %d", _isShowingLandscapeView);
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    _screenWidth = screenRect.size.width;
    _screenHeight = screenRect.size.height;
    
    if(_isShowingLandscapeView){
        self.view.frame =  CGRectMake(0, 0, _screenWidth, _screenHeight);
        self.view.bounds = CGRectMake(0, 0, _screenHeight, _screenWidth);
        _screenWidth = screenRect.size.height;
        _screenHeight = screenRect.size.width;
    }
    
    //    NSLog(@"viewDidLoad : %f %f", screenWidth, screenHeight);
    

    // Create a view and add it to the window.
    self.noteView = [[UIScrollView alloc] initWithFrame: CGRectMake(0, 64,_screenWidth,_screenHeight-64)];
    
    // s : ios6 noteView height
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        // here you go with iOS 6
        self.noteView = [[UIScrollView alloc] initWithFrame: CGRectMake(0, 0,_screenWidth,_screenHeight)];
    } else {
        self.noteView = [[UIScrollView alloc] initWithFrame: CGRectMake(0, 64,_screenWidth,_screenHeight-64)];
    }
    // e : ios6 noteView height
    
    
    [self.noteView setContentSize:CGSizeMake(_screenWidth, _screenHeight)];
    [self.noteView setBackgroundColor: [UIColor clearColor]];
    [self.view addSubview: self.noteView];
    
    for (; _playListSongIndex<_playListSongsCount; _playListSongIndex++) {
        
        // s: init note
        [self initNote];
        // e: init note
        
        // s : get beat
        NSString *songBeat = self.songInfo.beat;
        NSArray *tmpSongBeat = [songBeat componentsSeparatedByString:@"/"];
        int beatFirst = [[tmpSongBeat objectAtIndex:0] intValue];
        
        if((beatFirst % 3) == 0){
            _beatCountInBar = 6;
        } else {
            _beatCountInBar = 8;
        }
        // e : get beat
        
        _lineMarginY = 40.0f;
        _lyricHeight = 20.0f;
        _startY = 50.0f;
        _chordPadding = 2.0f;
        
        if(_beatCountInBar == 6){
            _lyricHeight = 30.0f;
        }
        
        if([_appDelegate isPad]){
            _lineMarginY = _lineMarginY * 2.6;
            _lyricHeight = _lyricHeight * 2.2;
//            _startY = _startY * 2.6;
            
            // s : ios6 _startY
            if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
                _startY = _startY * 2.0;
            } else {
                _startY = _startY * 2.6;
            }
            // e : ios6 _startY
            
            _chordPadding = 4.0f;
            _lineX = 40.0f;
        }
        
        
        
        // s: make view
        [self makeView];
        // e: make view
        
        // s: make note
        [self makeNote];
        // e: make note
        
        [self autoPitch];
    }
    
    [self.noteView setContentSize:CGSizeMake(self.noteView.frame.size.width * _playListSongsCount, _maxHeight)];
    
    self.noteView.showsVerticalScrollIndicator=YES;
    self.noteView.showsHorizontalScrollIndicator=YES;
    self.noteView.alwaysBounceVertical=NO;
    self.noteView.alwaysBounceHorizontal=NO;
    self.noteView.pagingEnabled=YES;
    self.noteView.delegate=self;

    _pageControl.currentPage = _bookmarkIndex;
    _pageControl.numberOfPages = _playListSongsCount;
    [_pageControl addTarget:self action:@selector(pageChangeValue:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_pageControl];
    

    // set currnet page
    float currentScroll = 64.0f;
    
    // s : ios6 currentScroll
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        // here you go with iOS 6
        currentScroll = 0.0f;
    }
    // e : ios6 currentScroll

    if([_appDelegate isPad]){
        currentScroll = 0.0f;
    }
    
    CGRect frame = self.noteView.frame;
    frame.origin.x = frame.size.width * _bookmarkIndex;
    frame.origin.y = currentScroll;
    [self.noteView scrollRectToVisible:frame animated:YES];

}

- (void) initNote {
    
    _songInfo = nil;
    _songInfo = [_playListSongs objectAtIndex:_playListSongIndex];
    
    NSLog(@"song info id : %d", _songInfo.song_info_id);
    
    
    _song = [[NSMutableArray alloc] init];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex: 0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:DATABASE_NAME];
    _database = [FMDatabase databaseWithPath:path];
    
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM song_data WHERE song_info_id = %d ORDER BY beat_index ;", _songInfo.song_info_id];
    
    [_database open];
    
    FMResultSet *results = [_database executeQuery:sql];
    while ([results next])
    {
        
        // insert into an object
        SongData *songData = [[SongData alloc] init];
        if (songData) {
            
            songData.song_data_id = [results intForColumnIndex:0];
            songData.song_info_id = [results intForColumnIndex:1];
            songData.beat_index = [results intForColumnIndex:2];
            songData.chord_1 = [results stringForColumnIndex:3];
            songData.chord_1_pitch = [results stringForColumnIndex:4];
            songData.chord_1_option = [results stringForColumnIndex:5];
            songData.chord_2 = [results stringForColumnIndex:6];
            songData.chord_2_pitch = [results stringForColumnIndex:7];
            songData.chord_2_option = [results stringForColumnIndex:8];
            songData.rest_type = [results intForColumnIndex:9];
            songData.bar_type = [results intForColumnIndex:10];
            songData.play_type = [results stringForColumnIndex:11];
            songData.expression = [results stringForColumnIndex:12];
            songData.lyric_1 = [results stringForColumnIndex:13];
            songData.lyric_2 = [results stringForColumnIndex:14];
            songData.lyric_3 = [results stringForColumnIndex:15];
            songData.lyric_4 = [results stringForColumnIndex:16];
            
            [_song addObject:songData];
        }
        
//        NSLog(@"%d, %d, %d, %@, %@, %@, %@, %@", [results intForColumnIndex:0], [results intForColumnIndex:1], [results intForColumnIndex:2], [results stringForColumnIndex:3], [results stringForColumnIndex:13], [results stringForColumnIndex:14], [results stringForColumnIndex:15], [results stringForColumnIndex:16]);
    }
    [_database close];
}


- (void) makeView {
    //    NSLog(@"make note");
    //    NSLog(@"%f : %f", _screenWidth, _screenHeight);
    
    
    NSString *songBeat = self.songInfo.beat;
    _songBarCount = self.songInfo.bar_count;
    _songLyricCount = self.songInfo.lyric_count;
    
    if(_songLyricCount == 1){
        _songLyricCount = 2;
    }
    
    _lineMarginY = _lineMarginY + (_songLyricCount * _lyricHeight);
    
//    NSLog(@"_songLyricCount : %d", _songLyricCount);
    
    
    _tableCount = 0;
    _beatCountInBar = 0;
    _beatMaxCount = 0;
    //    int selextedBeatIndex = 0;
	
    // set table count
    _tableCount = ceil(_songBarCount / _barCountInLine);
    
    // set beat count in bar
    NSArray *tmpSongBeat = [songBeat componentsSeparatedByString:@"/"];
    
    int beatFirst = [[tmpSongBeat objectAtIndex:0] intValue];
    
    if((beatFirst % 3) == 0){
        _beatCountInBar = 6;
    } else {
        _beatCountInBar = 8;
    }
    
    // set beat max count
    _beatMaxCount = _songBarCount * _beatCountInBar;
    
    float noteViewHeight = _lineMarginY*(1+_tableCount);
    
    if(_maxHeight <= noteViewHeight){
        _maxHeight = noteViewHeight;
    }
    
    
    /*
    for (int i=0; i<_playListSongsCount; i++) {
        UIImage *img = [UIImage imageNamed:@"Default.png"];
        UIImageView *imgView = [[UIImageView alloc] initWithImage:img];
        imgView.frame = CGRectMake(self.noteView.frame.size.width*i, 0, self.noteView.frame.size.width, self.noteView.frame.size.height);
        
        [self.noteView addSubview:imgView];
    }
    */
    
}

- (void) makeNote {
    for(int i=0;i<_tableCount;i++){
        [self makeLine:i];
        [self makeContent:i];
    }
}


- (void) makeLine:(int)lineNum {
    
//    NSLog(@"make line");
//    NSLog(@"%d, %d, %d", lineNum, _beatCountInBar, _beatMaxCount);
    
    CGFloat lineWidth = _screenWidth-(_lineX*2.0f);
    CGFloat lineY = (_lineMarginY * lineNum) + _startY;
    
    UIView *lineView = [[UIView alloc] initWithFrame: CGRectMake(_lineX + (_screenWidth * _playListSongIndex), lineY, lineWidth, _lineHeight)];
    [lineView setBackgroundColor: [UIColor blackColor]];
    [self.noteView addSubview: lineView];
    
    NSLog(@"%f, %d, %d", lineY, _playListSongIndex, _playListSongsCount);
    
    /*
     CGFloat barWidth = lineWidth / _barCountInLine;
     
     CGFloat v_lineX = barWidth;
     
     for(int i=0;i<(_barCountInLine+1);i++){
     
     v_lineX = (barWidth * i) + _lineX;
     UIView *vlineView = [[UIView alloc] initWithFrame: CGRectMake(v_lineX, lineY-4, 1, 10)];
     [vlineView setBackgroundColor: [UIColor blackColor]];
     [self.noteView addSubview: vlineView];
     }
     */
}

- (void) makeContent:(int)lineNum {
    //    NSLog(@"make beat index column");
    
    int beatIndex = 0;
    int barIndex = 0;
    CGFloat cellX = _lineX;
    
    CGFloat lineWidth = _screenWidth-(_lineX*2.0f);
    int totalBeatCountInLine = _beatCountInBar * _barCountInLine;
    CGFloat cellWidth = lineWidth / totalBeatCountInLine;
    
    // overloading cellHeight
    CGFloat cellHeight = cellWidth;
    //    NSLog(@"cellHeight : %f", cellHeight);
    
    _fontSize = cellWidth;
    
    if(_isShowingLandscapeView){
        _fontSize = cellWidth - 5.0;
    }
    
//    NSLog(@"_fontSize : %f", _fontSize);
    
    //    CGFloat beatIndexlineY = (_lineMarginY * lineNum) + _startY - cellHeight - cellHeight - cellHeight - cellHeight;
    //    CGFloat barTypelineY = (_lineMarginY * lineNum) + _startY - cellHeight;
    CGFloat barTypelineY = (_lineMarginY * lineNum) + _startY - (cellHeight/1.6);
    
    CGFloat beatIndexlineY = (_lineMarginY * lineNum) + _startY - cellHeight;
    CGFloat chordlineY = (_lineMarginY * lineNum) + _startY - cellHeight - cellHeight - (cellHeight/3.0);
    CGFloat playTypelineY = (_lineMarginY * lineNum) + _startY - cellHeight - cellHeight - cellHeight - cellHeight - (cellHeight/1.8);
    
    float chordPitchlineYPadding = 6.0f;
    
    if(_beatCountInBar == 6){
        chordPitchlineYPadding = 7.0f;
    }
    
    if([_appDelegate isPad]){
        chordPitchlineYPadding = 12.0f;
        
        if(_beatCountInBar == 6){
            chordPitchlineYPadding = 16.0f;
        }
    }
    
    CGFloat chordPitchlineY = (_lineMarginY * lineNum) + _startY - cellHeight - cellHeight - cellHeight - chordPitchlineYPadding;
    
    CGFloat restTypelineY = (_lineMarginY * lineNum) + _startY - cellHeight - (cellHeight/4);
    CGFloat lyric_1_lineY = (_lineMarginY * lineNum) + _startY + cellHeight;
    CGFloat lyric_2_lineY = (_lineMarginY * lineNum) + _startY + cellHeight + cellHeight + 4;
    CGFloat lyric_3_lineY = (_lineMarginY * lineNum) + _startY + cellHeight + cellHeight + cellHeight + 8;
    CGFloat lyric_4_lineY = (_lineMarginY * lineNum) + _startY + cellHeight + cellHeight + cellHeight + cellHeight + 12;
    
    //    CGFloat lyric_1_cell_lineY = (_lineMarginY * lineNum) + _startY + cellHeight + cellHeight + cellHeight + cellHeight + cellHeight;
    CGFloat barWidth = lineWidth / _barCountInLine;
    
    
    //    NSLog(@"%f %f %f", _screenWidth, lineWidth, cellWidth);
    
    for(int i=0;i<totalBeatCountInLine;i++){
        
        beatIndex = ((lineNum * totalBeatCountInLine) + i + 1);
        barIndex = (ceil)((float)beatIndex / _beatCountInBar);
        //        barIndex = (((lineNum * totalBeatCountInLine) + i + 1) / _beatCountInBar);
        
        /*
         // beat index
         UILabel *cellBeatIndex = [[UILabel alloc] initWithFrame:CGRectMake(cellX, beatIndexlineY, cellWidth, cellHeight)];
         [cellBeatIndex setText:[NSString stringWithFormat:@"%d", beatIndex]];
         [cellBeatIndex setTextColor:[UIColor whiteColor]];
         [cellBeatIndex setBackgroundColor:[UIColor blackColor]];
         [cellBeatIndex setFont:[UIFont fontWithName: @"Trebuchet MS" size: 8.0f]];
         [self.noteView addSubview:cellBeatIndex];
         */
        
        SongData *songData = nil;
        
        for (SongData *song in _song) {
            if (song.beat_index == beatIndex) {
                songData = song;
                break;
            }
        }
        
        // bar type
        if(((beatIndex % _beatCountInBar) == 0) || ((beatIndex % ((int)_barCountInLine*_beatCountInBar) == 1))){
            
            NSString *barImageFileName = nil;
            
            if(songData){
                switch (songData.bar_type) {
                    case 0:
                        barImageFileName = @"bar_standard.png";
                        break;
                    case 1:
                        barImageFileName = @"bar_double.png";
                        break;
                    case 2:
                        barImageFileName = @"bar_end.png";
                        break;
                    case 3:
                        barImageFileName = @"bar_begin_repeat.png";
                        break;
                    case 4:
                        barImageFileName = @"bar_end_repeat.png";
                        break;
                    default:
                        barImageFileName = @"bar_standard.png";
                        break;
                }
            } else {
                barImageFileName = @"bar_standard.png";
            }
            
            CGFloat barType_lineX = cellX + (_screenWidth * _playListSongIndex) + (_lineX/4.0);
            
            if([_appDelegate isPad]){
                barType_lineX = cellX + (_screenWidth * _playListSongIndex) + (_lineX/9.0);
            }
            
            /*
            if([_appDelegate isPad]){
                barType_lineX = cellX + (_screenWidth * _playListSongIndex) + (_lineX/2.6);
            }
            */
            
            if((beatIndex % ((int)_barCountInLine*_beatCountInBar) == 1)){
                
                barType_lineX = cellX  + (_screenWidth * _playListSongIndex) - (_lineX/1.5);
                
                if(_beatCountInBar == 6){
                    barType_lineX = barType_lineX - 3.0;
                }
                
                if([_appDelegate isPad]){
                    barType_lineX = cellX + (_screenWidth * _playListSongIndex) - (_lineX/2.2);
                    
                    if(_beatCountInBar == 6){
                        barType_lineX = barType_lineX - 6.0;
                    }
                }
                
                /*
                if([_appDelegate isPad]){
                    barType_lineX = cellX  + (_screenWidth * _playListSongIndex) - (_lineX/0.5);
                }
                */
                
                if(_isShowingLandscapeView){
                    barType_lineX = cellX  + (_screenWidth * _playListSongIndex) - (_lineX/0.8);
                }
            }
            
            UIImage *barTypeImage = [UIImage imageNamed:barImageFileName];
            UIImageView *cellBarType = [[UIImageView alloc] initWithImage:barTypeImage];
            cellBarType.frame = CGRectMake(barType_lineX, barTypelineY, cellWidth+(cellWidth/2), cellWidth+(cellWidth/2));
            [self.noteView addSubview:cellBarType];
            
        }
        
        float cornerRadius = 2.0f;
        float chordPitchPadding = 3.2f;
        float restTypePadding = 0.0f;
        float chordFontPadding = 2.6f;
        float chordFontAdjust = 0.0f;
        float chordPithYPadding = 0.0f;
        float playTypeFontAdjust = 0.0f;
        
        if(_beatCountInBar == 6){
            chordFontPadding = -2.0;
            chordFontAdjust = -2.0;
            chordPithYPadding = 2.0;
        }
        
        
        if([_appDelegate isPad]){
            cornerRadius = 4.0f;
            restTypePadding = 0.5f;
            playTypeFontAdjust = -4.0;
            
            if(_beatCountInBar == 6){
                chordFontPadding = 0.0;
                chordFontAdjust = -6.0;
                chordPithYPadding = 6.0;
            }
        }
        

        
        // playType
        
        if(songData){
            
            if(![songData.play_type isEqualToString:@""]){
                
                NSString *playTypeString = nil;
                playTypeString = songData.play_type;
                
                CGSize labelSize = [playTypeString sizeWithFont:[UIFont systemFontOfSize:_fontSize + 1]];
                
                UILabel *cellPlayType = [[UILabel alloc] initWithFrame:CGRectMake(cellX + (_screenWidth * _playListSongIndex), playTypelineY, labelSize.width, cellHeight)];
                [cellPlayType setText:playTypeString];
                [cellPlayType setTextColor:[UIColor colorWithRed:(79/255.f) green:(80/255.f) blue:(82/255.f) alpha:1.0f]];
                [cellPlayType setBackgroundColor:[UIColor clearColor]];
                [cellPlayType setFont:[UIFont fontWithName: @"Georgia-Italic" size: _fontSize + playTypeFontAdjust]];
                [self.noteView addSubview:cellPlayType];
            }
        }
        
        
        
        // chord
        if(songData){
            
            if(![songData.chord_1 isEqualToString:@""]){
                
                NSString *chordString = nil;
                
                if([songData.chord_2 isEqualToString:@""]){
                    chordString = [NSString stringWithFormat:@"%@%@", songData.chord_1, songData.chord_1_option];
                } else {
                    chordString = [NSString stringWithFormat:@"%@%@/%@%@", songData.chord_1, songData.chord_1_option, songData.chord_2,songData.chord_2_option];
                }
                
                CGSize labelSize = [chordString sizeWithFont:[UIFont systemFontOfSize:_fontSize+chordFontPadding]];
                
                UILabel *cellChord = [[UILabel alloc] initWithFrame:CGRectMake(cellX + (_screenWidth * _playListSongIndex), chordlineY, (labelSize.width + _chordPadding), (cellHeight + _chordPadding + chordFontAdjust))];
                cellChord.tag = (_playListSongIndex * 100000) + beatIndex;
                [cellChord setText:chordString];
                [cellChord setTextColor:[UIColor whiteColor]];
                [cellChord setBackgroundColor:[UIColor colorWithRed:(4/255.f) green:(189/255.f) blue:(204/255.f) alpha:1.0f]];
                [cellChord setFont:[UIFont fontWithName: @"AppleSDGothicNeo-Medium" size: _fontSize]];
                cellChord.textAlignment = NSTextAlignmentCenter;
                cellChord.clipsToBounds = YES;
                cellChord.layer.cornerRadius = cornerRadius;
                [self.noteView addSubview:cellChord];
                
                // chord Pitch
                NSString *chordPitchString = nil;
                
                if([[songData.chord_2_pitch stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]){
                    chordPitchString = [NSString stringWithFormat:@"%@", [self getChordPitchString:songData.chord_1_pitch]];
                } else {
                    
                    NSString *chord_1_pitch = @"  ";
                    
                    if(![[songData.chord_1_pitch stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]){
                        chord_1_pitch = [self getChordPitchString:songData.chord_1_pitch];
                    }
                    
                    chordPitchString = [NSString stringWithFormat:@"%@/%@", chord_1_pitch, [self getChordPitchString:songData.chord_2_pitch]];
                }
                
                CGFloat chordPitch_lineX = cellX + (_screenWidth * _playListSongIndex) + (_lineX/chordPitchPadding);
                
                labelSize = [chordPitchString sizeWithFont:[UIFont systemFontOfSize:_fontSize+chordFontPadding]];
                UILabel *cellChordPitch = [[UILabel alloc] initWithFrame:CGRectMake(chordPitch_lineX, chordPitchlineY+chordPithYPadding, (labelSize.width + _chordPadding), (cellHeight + _chordPadding + chordFontAdjust))];
                cellChordPitch.tag = (_playListSongIndex * 100000) + 10000 + beatIndex;
                [cellChordPitch setText:chordPitchString];
                [cellChordPitch setTextColor:[UIColor whiteColor]];
                
                if([[chordPitchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]){
                    [cellChordPitch setBackgroundColor:[UIColor clearColor]];
                } else {
                    [cellChordPitch setBackgroundColor:[UIColor colorWithRed:(115/255.f) green:(194/255.f) blue:(125/255.f) alpha:1.0f]];
                }
                
                [cellChordPitch setFont:[UIFont fontWithName: @"AppleSDGothicNeo-Bold" size: _fontSize + chordFontAdjust]];
                cellChordPitch.textAlignment = NSTextAlignmentCenter;
                cellChordPitch.clipsToBounds = YES;
                cellChordPitch.layer.cornerRadius = cornerRadius;
                [cellChordPitch sizeToFit];
                [self.noteView addSubview:cellChordPitch];
                
            }
            
            /*
             if(![songData.chord_1_pitch isEqualToString:@""]){
             
             NSString *chordString = nil;
             
             if([songData.chord_2 isEqualToString:@""]){
             chordString = [NSString stringWithFormat:@"%@%@%@", songData.chord_1, songData.chord_1_pitch, songData.chord_1_option];
             } else {
             chordString = [NSString stringWithFormat:@"%@%@%@/%@%@%@", songData.chord_1, songData.chord_1_pitch, songData.chord_1_option,songData.chord_2, songData.chord_2_pitch, songData.chord_2_option];
             }
             
             CGSize labelSize = [chordString sizeWithFont:[UIFont systemFontOfSize:14.0f]];
             UILabel *cellChord = [[UILabel alloc] initWithFrame:CGRectMake(cellX, chordlineY, labelSize.width, cellHeight)];
             cellChord.tag = beatIndex;
             [cellChord setText:chordString];
             [cellChord setTextColor:[UIColor blackColor]];
             [cellChord setBackgroundColor:[UIColor clearColor]];
             [cellChord setFont:[UIFont fontWithName: @"Trebuchet MS" size: 8.0f]];
             [self.noteView addSubview:cellChord];
             }
             */
        }
        
       

        // restType
        if(songData){
            if(songData.rest_type > 0){
                
                NSString *restImageFileName = nil;
                
                switch (songData.rest_type) {
                    case 1:
                        restImageFileName = @"rest_whole.png";
                        break;
                    case 2:
                        restImageFileName = @"rest_half_point.png";
                        break;
                    case 3:
                        restImageFileName = @"rest_half.png";
                        break;
                    case 4:
                        restImageFileName = @"rest_quarter_point.png";
                        break;
                    case 5:
                        restImageFileName = @"rest_quarter.png";
                        break;
                    case 6:
                        restImageFileName = @"rest_eighth_point.png";
                        break;
                    case 7:
                        restImageFileName = @"rest_eighth.png";
                        break;
                    case 8:
                        restImageFileName = @"rest_sixteenth.png";
                        break;
                        
                    default:
                        break;
                }
                
                CGFloat restTypeLineX = cellX - restTypePadding;
                
                UIImage *restTypeImage = [UIImage imageNamed:restImageFileName];
                UIImageView *cellRestType = [[UIImageView alloc] initWithImage:restTypeImage];
                cellRestType.frame = CGRectMake(restTypeLineX + (_screenWidth * _playListSongIndex), restTypelineY, cellWidth+3, cellHeight+3);
                [self.noteView addSubview:cellRestType];
            }
        }
        
        if(beatIndex <= _beatMaxCount){
        
            [self makeLyric:songData];
            
            _beatAllString = [_beatAllString stringByAppendingString:@"☐"];
            
            if((beatIndex % _beatCountInBar) == 1){
                
                float beatCellHeight = 0.0f;
                
                // s : ios6 beatCellHeight
                if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
                    // here you go with iOS 6
                    if([_appDelegate isPad]){
                        beatCellHeight = 3.0f;
                    }
                }
                // e : ios6 beatCellHeight
                
                
                // beat_cell
                UILabel *cellBeat_cell = [[UILabel alloc] initWithFrame:CGRectMake(cellX + (_screenWidth * _playListSongIndex)+2, beatIndexlineY, barWidth, cellHeight + beatCellHeight)];
                cellBeat_cell.tag = (_playListSongIndex * 100000) + 30000 + barIndex;
                [cellBeat_cell setTextColor:[UIColor colorWithRed:(148/255.f) green:(123/255.f) blue:(131/255.f) alpha:1.0f]];
                [cellBeat_cell setBackgroundColor:[UIColor clearColor]];
                [cellBeat_cell setFont:[UIFont fontWithName: @"AppleSDGothicNeo-Medium" size: _fontSize]];
                [self.noteView addSubview:cellBeat_cell];
                
                // Lyric_1_cell
                TTTRegexAttributedLabel *cellLyric_1_cell = [[TTTRegexAttributedLabel alloc] initWithFrame:CGRectMake(cellX + (_screenWidth * _playListSongIndex)+2, lyric_1_lineY, barWidth, cellHeight+3)];
                cellLyric_1_cell.tag = (_playListSongIndex * 100000) + 40000 + barIndex;
                [cellLyric_1_cell setTextColor:[UIColor colorWithRed:(61/255.f) green:(63/255.f) blue:(69/255.f) alpha:1.0f]];
                [cellLyric_1_cell setBackgroundColor:[UIColor clearColor]];
                [cellLyric_1_cell setFont:[UIFont fontWithName: @"AppleSDGothicNeo-Medium" size: _fontSize]];
                [self.noteView addSubview:cellLyric_1_cell];
                
                
                // Lyric_2_cell
                if(![_lyric_2_AllString isEqualToString:@""]){
                    TTTRegexAttributedLabel *cellLyric_2_cell = [[TTTRegexAttributedLabel alloc] initWithFrame:CGRectMake(cellX + (_screenWidth * _playListSongIndex)+2, lyric_2_lineY, barWidth, cellHeight+3)];
                    cellLyric_2_cell.tag = (_playListSongIndex * 100000) + 50000 + barIndex;
                    [cellLyric_2_cell setTextColor:[UIColor colorWithRed:(61/255.f) green:(63/255.f) blue:(69/255.f) alpha:1.0f]];
                    [cellLyric_2_cell setBackgroundColor:[UIColor clearColor]];
                    [cellLyric_2_cell setFont:[UIFont fontWithName: @"AppleSDGothicNeo-Medium" size: _fontSize]];
                    [self.noteView addSubview:cellLyric_2_cell];
                }
                
                // Lyric_3_cell
                if(![_lyric_3_AllString isEqualToString:@""]){
                    TTTRegexAttributedLabel *cellLyric_3_cell = [[TTTRegexAttributedLabel alloc] initWithFrame:CGRectMake(cellX + (_screenWidth * _playListSongIndex)+2, lyric_3_lineY, barWidth, cellHeight+3)];
                    cellLyric_3_cell.tag = (_playListSongIndex * 100000) + 60000 + barIndex;
                    [cellLyric_3_cell setTextColor:[UIColor colorWithRed:(61/255.f) green:(63/255.f) blue:(69/255.f) alpha:1.0f]];
                    [cellLyric_3_cell setBackgroundColor:[UIColor clearColor]];
                    [cellLyric_3_cell setFont:[UIFont fontWithName: @"AppleSDGothicNeo-Medium" size: _fontSize]];
                    [self.noteView addSubview:cellLyric_3_cell];
                }
                
                // Lyric_4_cell
                if(![_lyric_4_AllString isEqualToString:@""]){
                    TTTRegexAttributedLabel *cellLyric_4_cell = [[TTTRegexAttributedLabel alloc] initWithFrame:CGRectMake(cellX + (_screenWidth * _playListSongIndex)+2, lyric_4_lineY, barWidth, cellHeight+3)];
                    cellLyric_4_cell.tag = (_playListSongIndex * 100000) + 70000 + barIndex;
                    [cellLyric_4_cell setTextColor:[UIColor colorWithRed:(61/255.f) green:(63/255.f) blue:(69/255.f) alpha:1.0f]];
                    [cellLyric_4_cell setBackgroundColor:[UIColor clearColor]];
                    [cellLyric_4_cell setFont:[UIFont fontWithName: @"AppleSDGothicNeo-Medium" size: _fontSize]];
                    [self.noteView addSubview:cellLyric_4_cell];
                }
                
            } else if((beatIndex % _beatCountInBar) == 0){
                
                // beat
                UILabel *Beat_Label = (UILabel *)[self.noteView viewWithTag:(_playListSongIndex * 100000) + 30000 + barIndex];
                NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:_beatAllString];
                float spacing = 1.0f;
                
                if([_appDelegate isPad]){
                    spacing = 2.5f;
                }
                
                [attributedString addAttribute:NSKernAttributeName
                                         value:@(spacing)
                                         range:NSMakeRange(0, [_beatAllString length])];
                
                Beat_Label.attributedText = attributedString;
                _beatAllString = @"";
                
                // Lyric_1
                TTTRegexAttributedLabel *Lyric_1_Label = (TTTRegexAttributedLabel *)[self.noteView viewWithTag:(_playListSongIndex * 100000) + 40000 + barIndex];
                [Lyric_1_Label setLyricText:_lyric_1_AllString withBeatCountInBar:_beatCountInBar];
                _lyric_1_AllString = @"";
                
                // Lyric_2
                if(![_lyric_2_AllString isEqualToString:@""]){
                    TTTRegexAttributedLabel *Lyric_2_Label = (TTTRegexAttributedLabel *)[self.noteView viewWithTag:(_playListSongIndex * 100000) + 50000 + barIndex];
                    [Lyric_2_Label setLyricText:_lyric_2_AllString withBeatCountInBar:_beatCountInBar];
                    _lyric_2_AllString = @"";
                }
                
                // Lyric_3
                if(![_lyric_3_AllString isEqualToString:@""]){
                    TTTRegexAttributedLabel *Lyric_3_Label = (TTTRegexAttributedLabel *)[self.noteView viewWithTag:(_playListSongIndex * 100000) + 60000 + barIndex];
                    [Lyric_3_Label setLyricText:_lyric_3_AllString withBeatCountInBar:_beatCountInBar];
                    _lyric_3_AllString = @"";
                }
                
                // Lyric_4
                if(![_lyric_4_AllString isEqualToString:@""]){
                    TTTRegexAttributedLabel *Lyric_4_Label = (TTTRegexAttributedLabel *)[self.noteView viewWithTag:(_playListSongIndex * 100000) + 70000 + barIndex];
                    [Lyric_4_Label setLyricText:_lyric_4_AllString withBeatCountInBar:_beatCountInBar];
                    _lyric_4_AllString = @"";
                }
            }
        }
        
        cellX = cellX + cellWidth;
        _lastBeatIndex = beatIndex;
    }
}

- (void)autoPitch {
    
    //    _pitchCount = self.songInfo.pitch_count;
    
    NSLog(@"autoPitch _pitchCount : %d", self.songInfo.pitch_count);
    int absPitchCount = abs(self.songInfo.pitch_count);
    
    if(self.songInfo.pitch_count > 0){
        
        NSLog(@"autoUpPitch");
        for(int i=0;i<absPitchCount;i++){
            [self upPitchAction];
        }
    } else if(self.songInfo.pitch_count < 0){
        
        NSLog(@"autoDownPitch");
        for(int i=0;i<absPitchCount;i++){
            [self downPitchAction];
        }    
    }
}

- (SongInfo*)setPitchforSongInfo:(SongInfo*)songInfo pitchCount:(int)count{
    
    
    NSLog(@"pitchCount : %d", count);
    
    int absPitchCount = abs(count);
    
    NSLog(@"absPitchCount : %d", absPitchCount);
    
    if(count > 0){
        
        for(int i=0;i<absPitchCount;i++){
            
            if([songInfo.chord_pitch isEqualToString:@"+"]){
                songInfo.chord_pitch = @"";
                songInfo.chord = [self upChord:songInfo.chord];
            } else if([songInfo.chord_pitch isEqualToString:@"-"]){
                songInfo.chord_pitch = @"";
            } else {
                
                if([songInfo.chord hasPrefix:@"E"] || [songInfo.chord hasPrefix:@"B"]){
                    songInfo.chord = [self upChord:songInfo.chord];
                    songInfo.chord_pitch = @"";
                } else {
                    songInfo.chord_pitch = @"+";
                }
            }
        }
    } else if(count < 0){
        
        for(int i=0;i<absPitchCount;i++){
            
            if([songInfo.chord_pitch isEqualToString:@"+"]){
                songInfo.chord_pitch = @"";
            } else if([songInfo.chord_pitch isEqualToString:@"-"]){
                songInfo.chord_pitch = @"";
                songInfo.chord = [self downChord:songInfo.chord];
            } else {
                if([songInfo.chord hasPrefix:@"F"] || [songInfo.chord hasPrefix:@"C"]){
                    songInfo.chord = [self downChord:songInfo.chord];
                    songInfo.chord_pitch = @"";
                } else {
                    songInfo.chord_pitch = @"-";
                }
            }
        }
    }
    
    return songInfo;
}

- (void)upPitchAction {
    
    for (SongData *song in _song) {
        NSLog(@"%@ %@ %@", song.chord_1, song.chord_1_pitch, song.chord_1_option);
        
        if(![song.chord_1 isEqualToString:@""]){
            
            if([song.chord_1_pitch isEqualToString:@"+"]){
                song.chord_1_pitch = @"";
                song.chord_1 = [self upChord:song.chord_1];
            } else if([song.chord_1_pitch isEqualToString:@"-"]){
                song.chord_1_pitch = @"";
            } else {
                
                if([song.chord_1 hasPrefix:@"E"] || [song.chord_1 hasPrefix:@"B"]){
                    song.chord_1 = [self upChord:song.chord_1];
                    song.chord_1_pitch = @"";
                } else {
                    song.chord_1_pitch = @"+";
                }
            }
            [self updateChordLabel:song];
        }
        
        if(![song.chord_2 isEqualToString:@""]){
            if([song.chord_2_pitch isEqualToString:@"+"]){
                song.chord_2_pitch = @"";
                song.chord_2 = [self upChord:song.chord_2];
            } else if([song.chord_2_pitch isEqualToString:@"-"]){
                song.chord_2_pitch = @"";
            } else {
                if([song.chord_2 hasPrefix:@"E"] || [song.chord_2 hasPrefix:@"B"]){
                    song.chord_2 = [self upChord:song.chord_2];
                    song.chord_2_pitch = @"";
                } else {
                    song.chord_2_pitch = @"+";
                }
            }
            [self updateChordLabel:song];
        }
    }
    
    _pitchCount++;
    if(_pitchCount == 12){
        _pitchCount = 0;
    }
    NSLog(@"upPitchAction : %d", _pitchCount);
}

- (void)downPitchAction {
    
    for (SongData *song in _song) {
        NSLog(@"%@ %@ %@", song.chord_1, song.chord_1_pitch, song.chord_1_option);
        
        if(![song.chord_1 isEqualToString:@""]){
            
            if([song.chord_1_pitch isEqualToString:@"+"]){
                song.chord_1_pitch = @"";
            } else if([song.chord_1_pitch isEqualToString:@"-"]){
                song.chord_1_pitch = @"";
                song.chord_1 = [self downChord:song.chord_1];
            } else {
                if([song.chord_1 hasPrefix:@"F"] || [song.chord_1 hasPrefix:@"C"]){
                    song.chord_1 = [self downChord:song.chord_1];
                    song.chord_1_pitch = @"";
                } else {
                    song.chord_1_pitch = @"-";
                }
            }
            [self updateChordLabel:song];
        }
        
        if(![song.chord_2 isEqualToString:@""]){
            if([song.chord_2_pitch isEqualToString:@"+"]){
                song.chord_1_pitch = @"";
            } else if([song.chord_2_pitch isEqualToString:@"-"]){
                song.chord_2_pitch = @"";
                song.chord_2 = [self downChord:song.chord_2];
            } else {
                if([song.chord_2 hasPrefix:@"F"] || [song.chord_2 hasPrefix:@"C"]){
                    song.chord_2 = [self downChord:song.chord_2];
                    song.chord_2_pitch = @"";
                } else {
                    song.chord_2_pitch = @"-";
                }
            }
            [self updateChordLabel:song];
        }
    }
    
    _pitchCount--;
    if(_pitchCount == -12){
        _pitchCount = 0;
    }
    
    NSLog(@"downPitchAction : %d", _pitchCount);
}

- (NSString*)upChord:(NSString*) chord {
    
    int chordLength = [chord length];
    
    NSString *chordPostString = nil;
    NSString *tmpChord = nil;
    
    if(chordLength > 1){
        //        NSLog(@"chordLength : %d", chordLength);
        tmpChord = chord;
        
        chord = [tmpChord substringWithRange:NSMakeRange(0, 1)];
        chordPostString = [tmpChord substringWithRange:NSMakeRange(1, 1)];
        
        //        NSLog(@"chord : %@, chordPostString : %@", chord, chordPostString);
    }
    
    NSString *returnChord = nil;
    
    int chordIndex = [_chordArray indexOfObject:chord];
    
    chordIndex++;
    
    if(chordIndex == 7){
        chordIndex = 0;
    }
    
    if(chordLength > 1){
        returnChord = [NSString stringWithFormat:@"%@%@", [_chordArray objectAtIndex:chordIndex], chordPostString];
    } else {
        returnChord = [_chordArray objectAtIndex:chordIndex];
    }
    
    //    NSLog(@"returnChord : %@", returnChord);
    return returnChord;
}

- (NSString*)downChord:(NSString*) chord {
    
    int chordLength = [chord length];
    
    NSString *chordPostString = nil;
    NSString *tmpChord = nil;
    
    if(chordLength > 1){
        //        NSLog(@"chordLength : %d", chordLength);
        tmpChord = chord;
        
        chord = [tmpChord substringWithRange:NSMakeRange(0, 1)];
        chordPostString = [tmpChord substringWithRange:NSMakeRange(1, 1)];
        
        //        NSLog(@"chord : %@, chordPostString : %@", chord, chordPostString);
    }
    
    NSString *returnChord = nil;
    
    int chordIndex = [_chordArray indexOfObject:chord];
    
    chordIndex--;
    
    if(chordIndex == -1){
        chordIndex = 6;
    }
    
    if(chordLength > 1){
        returnChord = [NSString stringWithFormat:@"%@%@", [_chordArray objectAtIndex:chordIndex], chordPostString];
    } else {
        returnChord = [_chordArray objectAtIndex:chordIndex];
    }
    
    //    NSLog(@"returnChord : %@", returnChord);
    return returnChord;
}

- (void)updateChordLabel:(SongData*)song {
    
    float chordFontPadding = 2.6f;
    
    if(_beatCountInBar == 6){
        chordFontPadding = -2.0;
    }
    
    
    if([_appDelegate isPad]){
        
        if(_beatCountInBar == 6){
            chordFontPadding = 0.0;
        }
    }

    
    UILabel *chordLabel = (UILabel *)[self.noteView viewWithTag:(_playListSongIndex * 100000) + song.beat_index];
    NSString *chordString = nil;
    
    if([song.chord_2 isEqualToString:@""]){
        chordString = [NSString stringWithFormat:@"%@%@", song.chord_1, song.chord_1_option];
    } else {
        chordString = [NSString stringWithFormat:@"%@%@/%@%@", song.chord_1, song.chord_1_option, song.chord_2, song.chord_2_option];
    }
    
    CGSize labelSize = [chordString sizeWithFont:[UIFont systemFontOfSize:_fontSize + chordFontPadding]];
    CGRect newLabelFrame = chordLabel.frame;
    newLabelFrame.size.width = labelSize.width + _chordPadding;
    chordLabel.frame = newLabelFrame;
    [chordLabel setText:chordString];
    
    // chord Pitch
    UILabel *chordPitchLabel = (UILabel *)[self.noteView viewWithTag:((_playListSongIndex * 100000) + 10000 + song.beat_index)];
    NSString *chordPitchString = nil;
    
    
    if([[song.chord_2_pitch stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]){
        chordPitchString = [NSString stringWithFormat:@"%@", [self getChordPitchString:song.chord_1_pitch]];
    } else {
        
        NSString *chord_1_pitch = @"  ";
        
        if(![[song.chord_1_pitch stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]){
            chord_1_pitch = [self getChordPitchString:song.chord_1_pitch];
        }
        
        chordPitchString = [NSString stringWithFormat:@"%@/%@", chord_1_pitch, [self getChordPitchString:song.chord_2_pitch]];
    }
    //    NSLog(@"chordPitchString : %@", chordPitchString);
    
    labelSize = [chordPitchString sizeWithFont:[UIFont systemFontOfSize:_fontSize + chordFontPadding]];
    CGRect newChordPitchLabelFrame = chordPitchLabel.frame;
    newChordPitchLabelFrame.size.width = labelSize.width + _chordPadding;
    chordPitchLabel.frame = newChordPitchLabelFrame;
    [chordPitchLabel setText:chordPitchString];
    [chordPitchLabel sizeToFit];
    
    if([[chordPitchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]){
        [chordPitchLabel setBackgroundColor:[UIColor clearColor]];
    } else {
        [chordPitchLabel setBackgroundColor:[UIColor colorWithRed:(115/255.f) green:(194/255.f) blue:(125/255.f) alpha:1.0f]];
    }
    
}




- (NSString*)getChordPitchString:(NSString*) chordPitch {
    
    NSString *returnChordPitchString = nil;
    
    if([chordPitch isEqualToString:@"+"]){
        returnChordPitchString = @"♯";
    } else if([chordPitch isEqualToString:@"-"]){
        returnChordPitchString = @"♭ ";
    } else {
        returnChordPitchString = @"";
    }
    return returnChordPitchString;
}

- (void)resetPitchAction {
    [self initNote];
    
    for (SongData *song in _song) {
        if(![song.chord_1 isEqualToString:@""]){
            [self updateChordLabel:song];
        }
    }
    
    _pitchCount = 0;
}


- (void)renamePitchAction {
    
    for (SongData *song in _song) {
        
        if(![song.chord_1_pitch isEqualToString:@""]){
            if([song.chord_1_pitch isEqualToString:@"+"]){
                song.chord_1_pitch = @"-";
                song.chord_1 = [self upChord:song.chord_1];
            } else if([song.chord_1_pitch isEqualToString:@"-"]){
                song.chord_1_pitch = @"+";
                song.chord_1 = [self downChord:song.chord_1];
            }
            [self updateChordLabel:song];
        }
        
        if(![song.chord_2_pitch isEqualToString:@""]){
            if([song.chord_2_pitch isEqualToString:@"+"]){
                song.chord_2_pitch = @"-";
                song.chord_2 = [self upChord:song.chord_2];
            } else if([song.chord_1_pitch isEqualToString:@"-"]){
                song.chord_2_pitch = @"+";
                song.chord_2 = [self downChord:song.chord_2];
            }
            [self updateChordLabel:song];
        }
    }
}


- (void)makeLyric:(SongData*)songData {
    
    
    switch(_songLyricCount) {
        case 1 :
            if(songData){
                if(![songData.lyric_1 isEqualToString:@""]){
                    _lyric_1_AllString = [_lyric_1_AllString stringByAppendingString:songData.lyric_1];
                } else {
                    _lyric_1_AllString = [_lyric_1_AllString stringByAppendingString:@"☐"];
                }
            } else {
                _lyric_1_AllString = [_lyric_1_AllString stringByAppendingString:@"☐"];
            }
            break;
        case 2 :
            if(songData){
                if(![songData.lyric_1 isEqualToString:@""]){
                    _lyric_1_AllString = [_lyric_1_AllString stringByAppendingString:songData.lyric_1];
                } else {
                    _lyric_1_AllString = [_lyric_1_AllString stringByAppendingString:@"☐"];
                }
                
                if(![songData.lyric_2 isEqualToString:@""]){
                    _lyric_2_AllString = [_lyric_2_AllString stringByAppendingString:songData.lyric_2];
                } else {
                    _lyric_2_AllString = [_lyric_2_AllString stringByAppendingString:@"☐"];
                }
            } else {
                _lyric_1_AllString = [_lyric_1_AllString stringByAppendingString:@"☐"];
                _lyric_2_AllString = [_lyric_2_AllString stringByAppendingString:@"☐"];
            }
            break;
        case 3 :
            if(songData){
                if(![songData.lyric_1 isEqualToString:@""]){
                    _lyric_1_AllString = [_lyric_1_AllString stringByAppendingString:songData.lyric_1];
                } else {
                    _lyric_1_AllString = [_lyric_1_AllString stringByAppendingString:@"☐"];
                }
                
                if(![songData.lyric_2 isEqualToString:@""]){
                    _lyric_2_AllString = [_lyric_2_AllString stringByAppendingString:songData.lyric_2];
                } else {
                    _lyric_2_AllString = [_lyric_2_AllString stringByAppendingString:@"☐"];
                }
                
                if(![songData.lyric_3 isEqualToString:@""]){
                    _lyric_3_AllString = [_lyric_3_AllString stringByAppendingString:songData.lyric_3];
                } else {
                    _lyric_3_AllString = [_lyric_3_AllString stringByAppendingString:@"☐"];
                }
            } else {
                _lyric_1_AllString = [_lyric_1_AllString stringByAppendingString:@"☐"];
                _lyric_2_AllString = [_lyric_2_AllString stringByAppendingString:@"☐"];
                _lyric_3_AllString = [_lyric_3_AllString stringByAppendingString:@"☐"];
            }
            break;
        case 4 :
            if(songData){
                if(![songData.lyric_1 isEqualToString:@""]){
                    _lyric_1_AllString = [_lyric_1_AllString stringByAppendingString:songData.lyric_1];
                } else {
                    _lyric_1_AllString = [_lyric_1_AllString stringByAppendingString:@"☐"];
                }
                
                if(![songData.lyric_2 isEqualToString:@""]){
                    _lyric_2_AllString = [_lyric_2_AllString stringByAppendingString:songData.lyric_2];
                } else {
                    _lyric_2_AllString = [_lyric_2_AllString stringByAppendingString:@"☐"];
                }
                
                if(![songData.lyric_3 isEqualToString:@""]){
                    _lyric_3_AllString = [_lyric_3_AllString stringByAppendingString:songData.lyric_3];
                } else {
                    _lyric_3_AllString = [_lyric_3_AllString stringByAppendingString:@"☐"];
                }
                
                if(![songData.lyric_4 isEqualToString:@""]){
                    _lyric_4_AllString = [_lyric_4_AllString stringByAppendingString:songData.lyric_4];
                } else {
                    _lyric_4_AllString = [_lyric_4_AllString stringByAppendingString:@"☐"];
                }
            } else {
                _lyric_1_AllString = [_lyric_1_AllString stringByAppendingString:@"☐"];
                _lyric_2_AllString = [_lyric_2_AllString stringByAppendingString:@"☐"];
                _lyric_3_AllString = [_lyric_3_AllString stringByAppendingString:@"☐"];
                _lyric_4_AllString = [_lyric_4_AllString stringByAppendingString:@"☐"];
            }
            break;
    }
    
    
}

- (void) pageChangeValue:(id)sender {
    UIPageControl *pControl = (UIPageControl *) sender;
    [_noteView setContentOffset:CGPointMake(pControl.currentPage*320, 0) animated:YES];
    
//    NSLog(@"pageChangeValue : %d", pControl.currentPage);
    
    [self changeTitle: pControl.currentPage];
}

//스크롤이 변경될때 page의 currentPage 설정
- (void)scrollViewDidEndDecelerating:(UIScrollView *)sender {
    
//    NSLog(@"scrollViewDidEndDecelerating");
    
    CGFloat pageWidth = _noteView.frame.size.width;
    
    int currentPageIndex = floor((_noteView.contentOffset.x - pageWidth / _playListSongsCount) / pageWidth) + 1;
    
    _pageControl.currentPage = currentPageIndex;
//    
    [self changeTitle: currentPageIndex];
    
}

- (void)changeTitle:(int)pageIndex {
    SongInfo *songInfoForTitle = [_playListSongs objectAtIndex:pageIndex];
    self.navigationItem.title = songInfoForTitle.song_title;
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


/*
- (void)orientationChanged:(NSNotification *)notification
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if((orientation == UIInterfaceOrientationPortrait) && _isShowingLandscapeView) {
        
        _isShowingLandscapeView = NO;
        
        screenRect = [[UIScreen mainScreen] bounds];
        screenWidth = screenRect.size.width;
        screenHeight = screenRect.size.height;
        
        self.view.frame =  CGRectMake(0, 0, screenWidth, screenHeight);
        self.view.bounds = CGRectMake(0, 0, screenWidth, screenHeight);
        screenWidth = screenRect.size.width;
        screenHeight = screenRect.size.height;
        
        NSLog(@"Portrait : %f %f", screenWidth, screenHeight);
        
        [self resetView];
        
        // s: make view
        [self makeView];
        // e: make view
        
        // s: make note
        [self makeNote];
        // e: make note
        
        
    } else if((orientation == UIInterfaceOrientationLandscapeRight) && !_isShowingLandscapeView) {
        
        _isShowingLandscapeView = YES;
        
        screenRect = [[UIScreen mainScreen] bounds];
        screenWidth = screenRect.size.width;
        screenHeight = screenRect.size.height;
        
        self.view.frame =  CGRectMake(0, 0, screenWidth, screenHeight);
        self.view.bounds = CGRectMake(0, 0, screenHeight, screenWidth);
        screenWidth = screenRect.size.height;
        screenHeight = screenRect.size.width;
        
        // 480, 320
        NSLog(@"Landscape : %f %f", screenWidth, screenHeight);
        
        [self resetView];
        
        // s: make view
        [self makeView];
        // e: make view
        
        // s: make note
        [self makeNote];
        // e: make note
    }
}
*/

- (void) confirmConnectToYoutube {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"확인" message:@"이동통신망을 이용하여 유투브 검색을\n이용하면 별도의 데이터 통화료가\n발생할 수 있습니다."
												   delegate:self cancelButtonTitle:nil otherButtonTitles: NSLocalizedString(@"취소",nil), NSLocalizedString(@"확인",nil), nil];
	alert.tag = 1;
	[alert show];
}

- (void) connectionErrorAlert {
    
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Internet connection",nil) message:NSLocalizedString(@"Please check your internet connection.",nil)
												   delegate:self cancelButtonTitle:NSLocalizedString(@"Check",nil) otherButtonTitles: nil];
    alert.tag = 2;
    [alert show];
}

- (void)alertView: (UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if ((alertView.tag == 1) && (buttonIndex == 1)) {
        [self connectToYoutube];
    }
}

- (void) connectToYoutube {
    NSString *query = [NSString stringWithFormat:@"http://www.youtube.com/results?search_query=%@", [_songInfo.song_title stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:query]];
}

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
