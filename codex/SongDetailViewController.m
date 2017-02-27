//
//  SongDetailViewController.m
//  codex
//
//  Created by Rock Kang on 2014. 5. 13..
//  Copyright (c) 2014년 neosave.me. All rights reserved.
//

#import "SongDetailViewController.h"
#import "SongData.h"
#import "Reachability.h"
#import "UIView+Toast.h"
#import "TTTRegexAttributedLabel.h"
#import <QuartzCore/QuartzCore.h>
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"

#define DATABASE_NAME @"codex.rdb"
#define PLAY_LIST_LIMIT 15
#define DEFAULT_SCALE 1.0
#define MOVE_PREV_SONG 0
#define MOVE_NEXT_SONG 1

//#define NSLog //

@interface SongDetailViewController ()

@end

@implementation SongDetailViewController

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
    
    NSLog(@"viewDidLoad - isPlayList : %d", _isPlaylist);
    NSLog(@"viewDidLoad - bookmarkIndex : %ld", _bookmarkIndex);
    
    if(_isPlaylist){
        [self setPlayList];
    }
    
    
    // s : ios6 navigator bar color
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        // here you go with iOS 6
        self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:240.0/255.0 green:115.0/255.0 blue:106.0/255.0 alpha:1.0];
    }
    // e : ios6 navigator bar color
    
    // s : GA
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"SongDetail"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    // e : GA
    
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [self initValue];
    
    self.noteScrollView = [[UIScrollView alloc] initWithFrame: CGRectMake(0,0,_screenWidth,_screenHeight)];
    [self.noteScrollView setBackgroundColor: [UIColor clearColor]];
    [self.view addSubview: self.noteScrollView];
    
    
    // s: make view
    [self makeView];
    // e: make view
    
    // s: init note
    [self initNote];
    // e: init note
    
    // s: make note
    [self makeNote];
    // e: make note
    
    // s: make menu
    [self makeMenu];
    // e: make menu
    
    [self autoPitch];
    
    _isScaled = NO;
    
    if([_appDelegate isPad]){
        [self setScale:YES];
        _isScaled = YES;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:tapGesture];
    
    UISwipeGestureRecognizer *swipeleft=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeleft:)];
    swipeleft.direction=UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeleft];
    
    UISwipeGestureRecognizer * swiperight=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swiperight:)];
    swiperight.direction=UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swiperight];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if(_isPlaylist){
        
        BOOL hasVisitedPlayList = [defaults boolForKey:@"hasVisitedPlayList"];
        if(!hasVisitedPlayList){
            [self.view makeToast:@"좌,우로 스와이핑 하면 곡 이동을 할 수 있습니다."];
            [defaults setBool:YES forKey:@"hasVisitedPlayList"];
            [defaults synchronize];
        }
        
    } else {
        
        BOOL isFirstLoading = [defaults boolForKey:@"isFirstLoading"];
        if(!isFirstLoading){
            [self.view makeToast:@"화면을 두 번 탭 하면 확대/축소 할 수 있습니다."];
            [defaults setBool:YES forKey:@"isFirstLoading"];
            [defaults synchronize];
        }
    }
}

-(void)initValue {
    
    _startY = 0.0f;
    _lineX = 10.0f;
    _lineHeight = 2.0f;
    _cellHeight = 10.0f;
    _barCountInLine = 4.0f;
    _menuMarginX = 30.0f;
    
    _lineMarginY = 0.0f;
    _lyricHeight = 0.0f;
    _chordPadding = 0.0f;
    
    _beatAllString = @"";
    _lyric_1_AllString = @"";
    _lyric_2_AllString = @"";
    _lyric_3_AllString = @"";
    _lyric_4_AllString = @"";
    
    _chordArray = @[@"C", @"D", @"E", @"F", @"G", @"A", @"B"];
    
    self.navigationItem.title = self.songInfo.song_title;
    
    // Do any additional setup after loading the view.
    if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)){
        _isShowingLandscapeView = YES;
    } else {
        _isShowingLandscapeView = NO;
    }
    
    NSLog(@"viewDidLoad : isShowingLandscapeView : %d", _isShowingLandscapeView);
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    _screenWidth = screenRect.size.width;
    _screenHeight = screenRect.size.height;
    
    /*
    if(_isShowingLandscapeView){
        self.view.frame =  CGRectMake(0, 0, _screenWidth, _screenHeight);
        self.view.bounds = CGRectMake(0, 0, _screenHeight, _screenWidth);
        _screenWidth = screenRect.size.height;
        _screenHeight = screenRect.size.width;
    }
    */
    
    NSLog(@"viewDidLoad : %f %f", _screenWidth, _screenHeight);
    
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
    
//    _lineMarginY = 40.0f;
    _lineMarginY = 30.0f;
    _lyricHeight = 20.0f;
    
    if(_beatCountInBar == 6){
        _lyricHeight = 30.0f;
    }
    
//    _startY = 50.0f;
    _startY = 40.0f;
    _chordPadding = 2.0f;
    
    if([_appDelegate isPad]){
        _lineMarginY = _lineMarginY * 2.6;
        _lyricHeight = _lyricHeight * 2.2;
        
        // s : ios6 _startY
        if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
            _startY = _startY * 2.0;
        } else {
            _startY = _startY * 3.2;
        }
        // e : ios6 _startY
        
        _chordPadding = 4.0f;
        _lineX = _lineX * 4.0;
    }
    
    // init pitch count
    _pitchCount = 0;
    
}

-(void)setPlayList {
    
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
    
    
    NSLog(@"viewDidLoad : bookmarkIndex : %ld", _bookmarkIndex);
    
//    SongInfo *songInfoForTitle = [_playListSongs objectAtIndex:_bookmarkIndex];
//    self.navigationItem.title = songInfoForTitle.song_title;
    
    _playListSongsCount = (int)[_playListSongs count];
    
    NSLog(@"_playListSongsCount : %d", _playListSongsCount);
}

-(void)updateSong {
    
    /*
    for(UIView *subview in [_noteScrollView subviews])
    {
        [_noteView removeFromSuperview];
    }
    */
    
    [_noteView removeFromSuperview];
    [_menu removeFromSuperview];
    [_prevSong removeFromSuperview];
    [_nextSong removeFromSuperview];
    
    [self initValue];
    
    // s: make view
    [self makeView];
    // e: make view
    
    // s: init note
    [self initNote];
    // e: init note
    
    // s: make note
    [self makeNote];
    // e: make note
    
    // s: make menu
    [self makeMenu];
    // e: make menu
    
    [self autoPitch];
    
    if(_isScaled){
        [self setScale:YES];
    }
    
    self.navigationItem.title = self.songInfo.song_title;
    NSLog(@"updateSong : bookmarkIndex : %ld", _bookmarkIndex);
}


-(void)swipeleft:(UISwipeGestureRecognizer*)gestureRecognizer
{
    //Do what you want here
    NSLog(@"swipeleft");
    
    if(!_isPlaylist){
        return;
    }
    
    if(_bookmarkIndex >= (_playListSongsCount - 1)){
        [self.view makeToast:@"플레이 리스트 마지막 곡 입니다."];
        return;
    }
    
    _bookmarkIndex++;
    
    self.songInfo = [_playListSongs objectAtIndex:_bookmarkIndex];
    
    [self updateSong];
}

-(void)swiperight:(UISwipeGestureRecognizer*)gestureRecognizer
{
    //Do what you want here
    NSLog(@"swiperight");
    
    if(!_isPlaylist){
        return;
    }
    
    if(_bookmarkIndex <= 0){
        [self.view makeToast:@"플레이 리스트 첫 곡 입니다."];
        return;
    }
    
    _bookmarkIndex--;
    
    self.songInfo = [_playListSongs objectAtIndex:_bookmarkIndex];
    
    [self updateSong];
}

- (void) setScale:(BOOL) isZoomOut {
    
    
    float scale = DEFAULT_SCALE;
    float scrollY = _lineMarginY*(1+_tableCount);
    
    if(isZoomOut){
    
        CGFloat scrollViewHeight = 0.0f;
        for (UIView* view in _noteView.subviews)
        {
            scrollViewHeight += view.frame.size.height;
        }
    
        scrollViewHeight =  (_lineMarginY * _tableCount) + _startY + _cellHeight + _cellHeight + _cellHeight + _cellHeight + 12;
    
        float adjustScale = (_screenHeight/scrollViewHeight);
    
        if(adjustScale >= 1.0){
            return;
        }
    
        if(adjustScale <= 0.4){
            adjustScale = 0.4;
        }
    
        NSLog(@"_screen Height : %f, _noteView Height : %f, content size : %f, adjustScale : %f", _screenHeight,  _noteView.frame.size.height, scrollViewHeight, adjustScale);
    
        scale = adjustScale;
        scrollY = scrollViewHeight * adjustScale;
    }

    _noteView.transform = CGAffineTransformMakeScale(scale, scale);
    
    [self.noteScrollView setContentSize:CGSizeMake(_screenWidth, scrollY)];
    
    _noteView.frame = CGRectMake(_noteView.frame.origin.x, 0, _noteView.frame.size.width, _noteView.frame.size.height);
    
    
//    [_noteScrollView setContentOffset:CGPointMake(0.0, (_lineMarginY*(1-scale)))];
//    [_noteScrollView setContentOffset:CGPointMake(0.0, scrollY)];
}

- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateRecognized) {
        NSLog(@"tap tap");
        
        if(!_isScaled){
            [self setScale:YES];
            _isScaled = YES;
        } else {
            [self setScale:NO];
            _isScaled = NO;
        }
    }
}
- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void) makeMenu {
//    NSLog(@"make menu");
    
    // s: make menu
    UIImage *storyMenuItemImage = [UIImage imageNamed:@"bg-menuitem.png"];
    UIImage *storyMenuItemImagePressed = [UIImage imageNamed:@"bg-menuitem-highlighted.png"];
    UIImage *upImage = [UIImage imageNamed:@"icon-up.png"];
    UIImage *downImage = [UIImage imageNamed:@"icon-down.png"];
    UIImage *renameImage = [UIImage imageNamed:@"icon-rename.png"];
    UIImage *reloadImage = [UIImage imageNamed:@"icon-reload.png"];
    UIImage *bookmarkImage = [UIImage imageNamed:@"icon-bookmark.png"];
    UIImage *youtubeImage = [UIImage imageNamed:@"icon-youtube.png"];
    
    //Path-like customization
    
    AwesomeMenuItem *starMenuItem1 = [[AwesomeMenuItem alloc] initWithImage:storyMenuItemImage
                                                           highlightedImage:storyMenuItemImagePressed
                                                               ContentImage:upImage
                                                    highlightedContentImage:nil];
    AwesomeMenuItem *starMenuItem2 = [[AwesomeMenuItem alloc] initWithImage:storyMenuItemImage
                                                           highlightedImage:storyMenuItemImagePressed
                                                               ContentImage:downImage
                                                    highlightedContentImage:nil];
    AwesomeMenuItem *starMenuItem3 = [[AwesomeMenuItem alloc] initWithImage:storyMenuItemImage
                                                           highlightedImage:storyMenuItemImagePressed
                                                               ContentImage:renameImage
                                                    highlightedContentImage:nil];
    AwesomeMenuItem *starMenuItem4 = [[AwesomeMenuItem alloc] initWithImage:storyMenuItemImage
                                                           highlightedImage:storyMenuItemImagePressed
                                                               ContentImage:reloadImage
                                                    highlightedContentImage:nil];
    AwesomeMenuItem *starMenuItem5 = [[AwesomeMenuItem alloc] initWithImage:storyMenuItemImage
                                                           highlightedImage:storyMenuItemImagePressed
                                                               ContentImage:bookmarkImage
                                                    highlightedContentImage:nil];
    AwesomeMenuItem *starMenuItem6 = [[AwesomeMenuItem alloc] initWithImage:storyMenuItemImage
                                                           highlightedImage:storyMenuItemImagePressed
                                                               ContentImage:youtubeImage
                                                    highlightedContentImage:nil];
    
    NSArray *menus = [NSArray arrayWithObjects:starMenuItem1, starMenuItem2, starMenuItem3, starMenuItem4, starMenuItem5, starMenuItem6, nil];
    
    AwesomeMenuItem *startItem = [[AwesomeMenuItem alloc] initWithImage:[UIImage imageNamed:@"bg-addbutton.png"]
                                                       highlightedImage:[UIImage imageNamed:@"bg-addbutton-highlighted.png"]
                                                           ContentImage:[UIImage imageNamed:@"icon-plus.png"]
                                                highlightedContentImage:[UIImage imageNamed:@"icon-plus-highlighted.png"]];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    self.menu = [[AwesomeMenu alloc] initWithFrame:screenRect startItem:startItem optionMenus:menus];
    self.menu.delegate = self;
	self.menu.menuWholeAngle = M_PI_2;
	self.menu.farRadius = 110.0f;
	self.menu.endRadius = 100.0f;
	self.menu.nearRadius = 90.0f;
    self.menu.animationDuration = 0.3f;
    
    float menuHeightPadding = 0.0f;
    
    // s : ios6 menuHeightPadding
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        // here you go with iOS 6
        menuHeightPadding = 64.0f;
    }
    // e : ios6 menuHeightPadding
    
    self.menu.startPoint = CGPointMake(_menuMarginX, (_screenHeight - _menuMarginX - menuHeightPadding));
    [self.view addSubview:self.menu];
    
    
    if(_isPlaylist){
        self.prevSong = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [self.prevSong addTarget:self action:@selector(moveSong:) forControlEvents:UIControlEventTouchUpInside];
        [self.prevSong setFrame:CGRectMake((_screenWidth - 44 - 36 - 8), (_screenHeight - 44 - menuHeightPadding), 36, 36)];
//        [self.prevSong setExclusiveTouch:YES];
        [self.prevSong setTag:MOVE_PREV_SONG];
        [self.prevSong setBackgroundImage:[UIImage imageNamed:@"btn_left.png"] forState:UIControlStateNormal];
        [self.view addSubview:self.prevSong];
        
        self.nextSong = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [self.nextSong addTarget:self action:@selector(moveSong:) forControlEvents:UIControlEventTouchUpInside];
        [self.nextSong setFrame:CGRectMake((_screenWidth - 44), (_screenHeight - 44 - menuHeightPadding), 36, 36)];
//        [self.nextSong setExclusiveTouch:YES];
        [self.nextSong setTag:MOVE_NEXT_SONG];
        [self.nextSong setBackgroundImage:[UIImage imageNamed:@"btn_right.png"] forState:UIControlStateNormal];
        [self.view addSubview:self.nextSong];
    }
    
}


-(void) moveSong:(UIButton*)sender
{
    if(sender.tag == MOVE_PREV_SONG){
        [self swiperight:nil];
    } else if(sender.tag == MOVE_NEXT_SONG){
        [self swipeleft:nil];
    }
}

- (void) initNote {
//    NSLog(@"song info id : %d", self.songInfo.song_info_id);
    
    _song = [[NSMutableArray alloc] init];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex: 0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:DATABASE_NAME];
    _database = [FMDatabase databaseWithPath:path];
    
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM song_data WHERE song_info_id = %d ORDER BY beat_index ;", self.songInfo.song_info_id];
    
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
    
    // for remove lyric
    _songLyricCount = 1;
    
    _lineMarginY = _lineMarginY + (_songLyricCount * _lyricHeight);
    
    NSLog(@"_songLyricCount : %d", _songLyricCount);

    
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
    
    // Create a view and add it to the window.
//    self.noteScrollView = [[UIScrollView alloc] initWithFrame: CGRectMake(0,40,_screenWidth,_screenHeight-40)];
    
    // origin
//    self.noteScrollView = [[UIScrollView alloc] initWithFrame: CGRectMake(0,0,_screenWidth,_screenHeight)];
//    [self.noteScrollView setContentSize:CGSizeMake(_screenWidth, _lineMarginY*(1+_tableCount))];
//    [self.noteScrollView setBackgroundColor: [UIColor clearColor]];
//    [self.view addSubview: self.noteScrollView];
    
    [self.noteScrollView setContentSize:CGSizeMake(_screenWidth, _lineMarginY*(1+_tableCount))];
    
    
    float viewWidth = _screenWidth;
    float xPostion = 0.0f;
    
    if([_appDelegate isPad]){
        viewWidth = 768.0f;
        xPostion = (_screenWidth - viewWidth)/2;
    }
    
    self.noteView = [[UIView alloc] initWithFrame: CGRectMake(xPostion, 0, viewWidth,_screenHeight)];
   // [self.noteView setContentSize:CGSizeMake(_screenWidth, _lineMarginY*(1+_tableCount))];
    [self.noteView setBackgroundColor: [UIColor clearColor]];
    [self.noteScrollView addSubview: self.noteView];
    
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
    if([_appDelegate isPad]){
        lineWidth = 768.0-(_lineX*2.0f);
    }
    CGFloat lineY = (_lineMarginY * lineNum) + _startY;
    
    UIView *lineView = [[UIView alloc] initWithFrame: CGRectMake(_lineX, lineY, lineWidth, _lineHeight/2)];
    [lineView setBackgroundColor: [UIColor grayColor]];
    [self.noteView addSubview: lineView];
    
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
    if([_appDelegate isPad]){
        lineWidth = 768.0-(_lineX*2.0f);
    }
    
    
    int totalBeatCountInLine = _beatCountInBar * _barCountInLine;
    CGFloat cellWidth = lineWidth / totalBeatCountInLine;
    
    // overloading cellHeight
    CGFloat cellHeight = cellWidth;
//    NSLog(@"cellHeight : %f", cellHeight);
    
    _fontSize = cellWidth;
    
    /*
    if(_isShowingLandscapeView){
        _fontSize = cellWidth - 5.0;
    }
    */
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
        
//        NSLog(@"barindex : %d", barIndex);
        
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
            
            CGFloat barType_lineX = cellX + (_lineX/4.0);
            

            if([_appDelegate isPad]){
                barType_lineX = cellX + (_lineX/9.0);
            }

            
            if((beatIndex % ((int)_barCountInLine*_beatCountInBar) == 1)){
                
                barType_lineX = cellX - (_lineX/1.5);
                
                if(_beatCountInBar == 6){
                    barType_lineX = barType_lineX - 3.0;
                }
                
                if([_appDelegate isPad]){
                    barType_lineX = cellX - (_lineX/2.2);
                    
                    if(_beatCountInBar == 6){
                        barType_lineX = barType_lineX - 6.0;
                    }
                }
                
                
                /*
                if(_isShowingLandscapeView){
                    barType_lineX = cellX - (_lineX/0.8);
                }
                 */
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
        
        float chordFontZoomIn = 1.2f;
        float cellWidthAdjust = 1.6f;
        float chordOptionwidthAdjust = 0.68f;
        
        
        if(_beatCountInBar == 6){
            chordFontPadding = -2.0;
            chordFontAdjust = -2.0;
            chordPithYPadding = 2.0;
            chordOptionwidthAdjust = 0.6f;
            cellWidthAdjust = 1.8f;
        }
        
        
        if([_appDelegate isPad]){
            cornerRadius = 4.0f;
            restTypePadding = 0.5f;
            playTypeFontAdjust = -4.0;
            cellWidthAdjust = 2.0f;
            
            if(_beatCountInBar == 6){
                chordFontPadding = 0.0;
                chordFontAdjust = -6.0;
                chordPithYPadding = 6.0;
                cellWidthAdjust = 1.6f;
            }
        }
        
        // playType
        
        if(songData){
            
            if(![songData.play_type isEqualToString:@""]){
                
                NSString *playTypeString = nil;
                playTypeString = songData.play_type;
                
                CGSize labelSize = [playTypeString sizeWithFont:[UIFont systemFontOfSize:_fontSize + 1]];
                
                UILabel *cellPlayType = [[UILabel alloc] initWithFrame:CGRectMake(cellX, playTypelineY, labelSize.width, cellHeight+2)];
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
                
                NSString *minSample = @"G";
                CGSize labelMinSize = [minSample sizeWithFont:[UIFont systemFontOfSize:(_fontSize+chordFontPadding)*chordFontZoomIn]];
                
                NSString *sample = [NSString stringWithFormat:@"%@", songData.chord_1];
                CGSize labelSize = [sample sizeWithFont:[UIFont systemFontOfSize:(_fontSize+chordFontPadding)*chordFontZoomIn]];
                
                if(labelMinSize.width > labelSize.width){
                    labelSize.width = labelMinSize.width;
                }
                
                float chordCellWidth = (labelSize.width*cellWidthAdjust) + _chordPadding;
                float chordCellHeight = (cellHeight*2) + _chordPadding + chordFontAdjust;
                
                UIView *cellChord = [[UILabel alloc] initWithFrame:CGRectMake(cellX, chordPitchlineY, chordCellWidth, chordCellHeight)];
                [cellChord setBackgroundColor:[UIColor clearColor]];
                
                NSString *chordString1 = [NSString stringWithFormat:@"%@", songData.chord_1];
                UILabel *cellChord1 = [[UILabel alloc] initWithFrame:CGRectMake(0, chordCellHeight/2, chordCellWidth/2, chordCellHeight/2)];
                [cellChord1 setText:chordString1];
                cellChord1.tag = beatIndex;
                [cellChord1 setTextColor:[UIColor blackColor]];
                [cellChord1 setBackgroundColor:[UIColor clearColor]];
                [cellChord1 setFont:[UIFont fontWithName: @"ChalkboardSE-Regular" size: (_fontSize + chordFontAdjust)*chordFontZoomIn]];
//                cellChord.textAlignment = NSTextAlignmentCenter;
                cellChord.clipsToBounds = YES;
                //                cellChord.layer.cornerRadius = cornerRadius;
                [cellChord addSubview:cellChord1];
                
//                NSString *chordOptionString1 = [NSString stringWithFormat:@"%@", songData.chord_1_option];
                
                // chord Pitch
                NSString *chordPitchString1 = @"";
                if(![[songData.chord_1_pitch stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]){
                    chordPitchString1 = [NSString stringWithFormat:@"%@", [self getChordPitchString:[songData.chord_1_pitch stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]]];
                }
                UILabel *cellChordPitch1 = [[UILabel alloc] initWithFrame:CGRectMake(0, chordCellHeight/6, chordCellWidth/2, (chordCellHeight*0.5))];
                [cellChordPitch1 setText:chordPitchString1];
                cellChordPitch1.tag = 10000 + beatIndex;
                [cellChordPitch1 setTextColor:[UIColor blackColor]];
                [cellChordPitch1 setBackgroundColor:[UIColor clearColor]];
                [cellChordPitch1 setFont:[UIFont fontWithName: @"ChalkboardSE-Bold" size: (_fontSize + chordFontAdjust)*chordFontZoomIn]];
                                    cellChordPitch1.textAlignment = NSTextAlignmentCenter;
                //                    cellChordPitch1.clipsToBounds = YES;
                
                [cellChord addSubview:cellChordPitch1];
                
                // chord option #1
//                NSString *chordOptionString1 = @"maj7";
                NSString *chordOptionString1 = [NSString stringWithFormat:@"%@", songData.chord_1_option];
                UILabel *cellChordOption1 = [[UILabel alloc] initWithFrame:CGRectMake(cellX + chordCellWidth/2.6, (chordPitchlineY+(chordCellHeight/8)), chordCellWidth, chordCellHeight)];
                [cellChordOption1 setText:chordOptionString1];
                [cellChordOption1 setTextColor:[UIColor blackColor]];
                [cellChordOption1 setBackgroundColor:[UIColor clearColor]];
                [cellChordOption1 setFont:[UIFont fontWithName: @"ChalkboardSE-Regular" size: ((_fontSize + chordFontAdjust)*chordFontZoomIn)*chordOptionwidthAdjust]];
                cellChord.clipsToBounds = YES;
                [self.noteView addSubview:cellChordOption1];

                
                if(![songData.chord_2 isEqualToString:@""]){
                
                    NSString *chordString2 = [NSString stringWithFormat:@"%@", songData.chord_2];
                    UILabel *cellChord2 = [[UILabel alloc] initWithFrame:CGRectMake(chordCellWidth/2, chordCellHeight/2, chordCellWidth, chordCellHeight/2)];
                    [cellChord2 setText:chordString2];
                    cellChord2.tag = 80000 + beatIndex;
                    [cellChord2 setTextColor:[UIColor blackColor]];
                    [cellChord2 setBackgroundColor:[UIColor clearColor]];
                    [cellChord2 setFont:[UIFont fontWithName: @"ChalkboardSE-Regular" size: (_fontSize + chordFontAdjust)*chordFontZoomIn]];
                    //                cellChord.textAlignment = NSTextAlignmentCenter;
                    cellChord2.clipsToBounds = YES;
                    //                cellChord.layer.cornerRadius = cornerRadius;
                    [cellChord addSubview:cellChord2];
                    
                    NSString *seperatedString = @"/";
                    UILabel *cellSeperated = [[UILabel alloc] initWithFrame:CGRectMake(0, chordCellHeight/2, chordCellWidth, chordCellHeight/2)];
                    [cellSeperated setText:seperatedString];
                    //                [cellChord setTextColor:[UIColor whiteColor]];
                    [cellSeperated setTextColor:[UIColor blackColor]];
                    [cellSeperated setBackgroundColor:[UIColor clearColor]];
                    [cellSeperated setFont:[UIFont fontWithName: @"ChalkboardSE-Regular" size: (_fontSize + chordFontAdjust)*chordFontZoomIn]];
                    cellSeperated.textAlignment = NSTextAlignmentCenter;
                    cellSeperated.clipsToBounds = YES;
                    
                    [cellChord addSubview:cellSeperated];
                    
                    
                    NSString *chordPitchString2 = @"";
                    
                    if(![[songData.chord_2_pitch stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]){
                        chordPitchString2 = [NSString stringWithFormat:@"%@", [self getChordPitchString:[songData.chord_2_pitch stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]]];
                    }
                    UILabel *cellChordPitch2 = [[UILabel alloc] initWithFrame:CGRectMake(chordCellWidth/2, chordCellHeight/6, chordCellWidth/2, (chordCellHeight*0.5))];
                    [cellChordPitch2 setText:chordPitchString2];
                    cellChordPitch2.tag = 20000 + beatIndex;
                    [cellChordPitch2 setTextColor:[UIColor blackColor]];
                    [cellChordPitch2 setBackgroundColor:[UIColor clearColor]];
                    [cellChordPitch2 setFont:[UIFont fontWithName: @"ChalkboardSE-Bold" size: (_fontSize + chordFontAdjust)*chordFontZoomIn]];
                                        cellChordPitch2.textAlignment = NSTextAlignmentCenter;
                    //                    cellChordPitch2.clipsToBounds = YES;
                    
                    [cellChord addSubview:cellChordPitch2];
                    
                    // chord option #2
//                    NSString *chordOptionString2 = @"maj7";
                    NSString *chordOptionString2 = [NSString stringWithFormat:@"%@", songData.chord_2_option];
                    UILabel *cellChordOption2 = [[UILabel alloc] initWithFrame:CGRectMake(cellX + chordCellWidth/2.6 + chordCellWidth/3, (chordPitchlineY+(chordCellHeight/8)), chordCellWidth, chordCellHeight)];
                    [cellChordOption2 setText:chordOptionString2];
                    [cellChordOption2 setTextColor:[UIColor blackColor]];
                    [cellChordOption2 setBackgroundColor:[UIColor clearColor]];
                    [cellChordOption2 setFont:[UIFont fontWithName: @"ChalkboardSE-Regular" size: ((_fontSize + chordFontAdjust)*chordFontZoomIn)*chordOptionwidthAdjust]];
                    cellChord.clipsToBounds = YES;
                    [self.noteView addSubview:cellChordOption2];
                    
                }
               
                
                [self.noteView addSubview:cellChord];
                
                
            }
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
                cellRestType.frame = CGRectMake(restTypeLineX, restTypelineY, cellWidth+3, cellHeight+3);
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
                UILabel *cellBeat_cell = [[UILabel alloc] initWithFrame:CGRectMake(cellX+2, beatIndexlineY, barWidth, cellHeight + beatCellHeight)];
                cellBeat_cell.tag = 30000 + barIndex;
                [cellBeat_cell setTextColor:[UIColor colorWithRed:(148/255.f) green:(123/255.f) blue:(131/255.f) alpha:1.0f]];
                [cellBeat_cell setBackgroundColor:[UIColor clearColor]];
                [cellBeat_cell setFont:[UIFont fontWithName: @"HelveticaNeue-Light" size: _fontSize]];
                [self.noteView addSubview:cellBeat_cell];
                
                /*
                // Lyric_1_cell
                TTTRegexAttributedLabel *cellLyric_1_cell = [[TTTRegexAttributedLabel alloc] initWithFrame:CGRectMake(cellX+2, lyric_1_lineY, barWidth, cellHeight+3)];
                cellLyric_1_cell.tag = 40000 + barIndex;
                [cellLyric_1_cell setTextColor:[UIColor colorWithRed:(61/255.f) green:(63/255.f) blue:(69/255.f) alpha:1.0f]];
                [cellLyric_1_cell setBackgroundColor:[UIColor clearColor]];
                [cellLyric_1_cell setFont:[UIFont fontWithName: @"HelveticaNeue-Light" size: _fontSize]];
                [self.noteView addSubview:cellLyric_1_cell];
                
               
                // Lyric_2_cell
                if(![_lyric_2_AllString isEqualToString:@""]){
                    TTTRegexAttributedLabel *cellLyric_2_cell = [[TTTRegexAttributedLabel alloc] initWithFrame:CGRectMake(cellX+2, lyric_2_lineY, barWidth, cellHeight+3)];
                    cellLyric_2_cell.tag = 50000 + barIndex;
                    [cellLyric_2_cell setTextColor:[UIColor colorWithRed:(61/255.f) green:(63/255.f) blue:(69/255.f) alpha:1.0f]];
                    [cellLyric_2_cell setBackgroundColor:[UIColor clearColor]];
                    [cellLyric_2_cell setFont:[UIFont fontWithName: @"HelveticaNeue-Light" size: _fontSize]];
                    [self.noteView addSubview:cellLyric_2_cell];
                }
                
                // Lyric_3_cell
                if(![_lyric_3_AllString isEqualToString:@""]){
                    TTTRegexAttributedLabel *cellLyric_3_cell = [[TTTRegexAttributedLabel alloc] initWithFrame:CGRectMake(cellX+2, lyric_3_lineY, barWidth, cellHeight+3)];
                    cellLyric_3_cell.tag = 60000 + barIndex;
                    [cellLyric_3_cell setTextColor:[UIColor colorWithRed:(61/255.f) green:(63/255.f) blue:(69/255.f) alpha:1.0f]];
                    [cellLyric_3_cell setBackgroundColor:[UIColor clearColor]];
                    [cellLyric_3_cell setFont:[UIFont fontWithName: @"HelveticaNeue-Light" size: _fontSize]];
                    [self.noteView addSubview:cellLyric_3_cell];
                }
               
                // Lyric_4_cell
                if(![_lyric_4_AllString isEqualToString:@""]){
                    TTTRegexAttributedLabel *cellLyric_4_cell = [[TTTRegexAttributedLabel alloc] initWithFrame:CGRectMake(cellX+2, lyric_4_lineY, barWidth, cellHeight+3)];
                    cellLyric_4_cell.tag = 70000 + barIndex;
                    [cellLyric_4_cell setTextColor:[UIColor colorWithRed:(61/255.f) green:(63/255.f) blue:(69/255.f) alpha:1.0f]];
                    [cellLyric_4_cell setBackgroundColor:[UIColor clearColor]];
                    [cellLyric_4_cell setFont:[UIFont fontWithName: @"HelveticaNeue-Light" size: _fontSize]];
                    [self.noteView addSubview:cellLyric_4_cell];
                }
                */
            } else if((beatIndex % _beatCountInBar) == 0){
                
                // beat
                UILabel *Beat_Label = (UILabel *)[self.noteView viewWithTag:30000 + barIndex];
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
                
                /*
                // Lyric_1
                TTTRegexAttributedLabel *Lyric_1_Label = (TTTRegexAttributedLabel *)[self.noteView viewWithTag:40000 + barIndex];
                [Lyric_1_Label setLyricText:_lyric_1_AllString withBeatCountInBar:_beatCountInBar];
                _lyric_1_AllString = @"";
                
                // Lyric_2
                if(![_lyric_2_AllString isEqualToString:@""]){
                    TTTRegexAttributedLabel *Lyric_2_Label = (TTTRegexAttributedLabel *)[self.noteView viewWithTag:50000 + barIndex];
                    [Lyric_2_Label setLyricText:_lyric_2_AllString withBeatCountInBar:_beatCountInBar];
                    _lyric_2_AllString = @"";
                }
                
                // Lyric_3
                if(![_lyric_3_AllString isEqualToString:@""]){
                    TTTRegexAttributedLabel *Lyric_3_Label = (TTTRegexAttributedLabel *)[self.noteView viewWithTag:60000 + barIndex];
                    [Lyric_3_Label setLyricText:_lyric_3_AllString withBeatCountInBar:_beatCountInBar];
                    _lyric_3_AllString = @"";
                }
                
                // Lyric_4
                if(![_lyric_4_AllString isEqualToString:@""]){
                    TTTRegexAttributedLabel *Lyric_4_Label = (TTTRegexAttributedLabel *)[self.noteView viewWithTag:70000 + barIndex];
                    [Lyric_4_Label setLyricText:_lyric_4_AllString withBeatCountInBar:_beatCountInBar];
                    _lyric_4_AllString = @"";
                }
                 */
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)awesomeMenu:(AwesomeMenu *)menu didSelectIndex:(NSInteger)idx
{
    
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    
    GAIDictionaryBuilder *gBuilder = nil;
    
    
    switch(idx){
        // up
        case 0:
            
            gBuilder = [GAIDictionaryBuilder createEventWithCategory:@"ui_action"     // Event category (required)
                                                              action:@"button_press"  // Event action (required)
                                                               label:@"up pitch"          // Event label
                                                               value:nil];
            
            [self upPitchAction];
            break;
            
        // down
        case 1:
            
            gBuilder = [GAIDictionaryBuilder createEventWithCategory:@"ui_action"     // Event category (required)
                                                              action:@"button_press"  // Event action (required)
                                                               label:@"down pitch"          // Event label
                                                               value:nil];
            
            [self downPitchAction];
            break;
        
        // change
        case 2:
            
            gBuilder = [GAIDictionaryBuilder createEventWithCategory:@"ui_action"     // Event category (required)
                                                              action:@"button_press"  // Event action (required)
                                                               label:@"rename pitch"          // Event label
                                                               value:nil];
            
            [self renamePitchAction];
            break;
        
        // reset
        case 3:
            
            gBuilder = [GAIDictionaryBuilder createEventWithCategory:@"ui_action"     // Event category (required)
                                                              action:@"button_press"  // Event action (required)
                                                               label:@"reset pitch"          // Event label
                                                               value:nil];
            
            [self resetPitchAction];
            break;
            
        // bookmark
        case 4:
            
            gBuilder = [GAIDictionaryBuilder createEventWithCategory:@"ui_action"     // Event category (required)
                                                              action:@"button_press"  // Event action (required)
                                                               label:@"bookmark"          // Event label
                                                               value:nil];
            
            [self bookmarkAction];
            break;
            
        // search youtube
        case 5:
            
            gBuilder = [GAIDictionaryBuilder createEventWithCategory:@"ui_action"     // Event category (required)
                                                              action:@"button_press"  // Event action (required)
                                                               label:@"search youtube"          // Event label
                                                               value:nil];
            
            [self searchByYoutubeAction];
            break;
    }
    
    if(gBuilder){
        [tracker send:[gBuilder build]];    // Event value
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


- (void) bookmarkAction {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSArray *oldBookmarkList = [defaults objectForKey:@"bookmarkList"];
    NSMutableArray *newBookmarkList = [[NSMutableArray alloc] init];
    
    if(oldBookmarkList){
        
        
        if([oldBookmarkList count] >= PLAY_LIST_LIMIT){
            NSString *limitMessage = [NSString stringWithFormat:@"플레이 리스트에는 %d곡까지 추가가 가능합니다.", PLAY_LIST_LIMIT];
            [self.view makeToast:limitMessage];
            return;
        }
        
        
        for( NSDictionary *dict in oldBookmarkList ) {
            [newBookmarkList addObject:dict];
        }
    }
    
    // get origin from db
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex: 0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:DATABASE_NAME];
    _database = [FMDatabase databaseWithPath:path];
    
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM song_info WHERE song_info_id = %d;", self.songInfo.song_info_id];
    [_database open];
    
    
    FMResultSet *results = [_database executeQuery:sql];
    SongInfo *songInfoOrigin;
    
    while ([results next])
    {
        
        // insert into an object
        songInfoOrigin = [[SongInfo alloc] init];
        
        if (songInfoOrigin) {
            songInfoOrigin.song_info_id = [results intForColumnIndex:0];
            songInfoOrigin.song_number = [results intForColumnIndex:1];
            songInfoOrigin.song_title = [results stringForColumnIndex:2];
            songInfoOrigin.category_1 = [results intForColumnIndex:3];
            songInfoOrigin.category_2 = [results intForColumnIndex:4];
            songInfoOrigin.song_lyric_start = [results stringForColumnIndex:5];
            songInfoOrigin.song_lyric_refrain = [results stringForColumnIndex:6];
            songInfoOrigin.song_lyric_keyword = [results stringForColumnIndex:7];
            songInfoOrigin.beat = [results stringForColumnIndex:8];
            songInfoOrigin.chord = [results stringForColumnIndex:9];
            songInfoOrigin.chord_pitch = [results stringForColumnIndex:10];
            songInfoOrigin.chord_option = [results stringForColumnIndex:11];
            songInfoOrigin.bar_count = [results intForColumnIndex:12];
            songInfoOrigin.lyric_count = [results intForColumnIndex:13];
            songInfoOrigin.pitch_count = 0;
        }
        
//        NSLog(@"%d, %d, %@, %@, %@, %@, %@", [results intForColumnIndex:0], [results intForColumnIndex:1], [results stringForColumnIndex:2], [results stringForColumnIndex:8], [results stringForColumnIndex:9], [results stringForColumnIndex:10], [results stringForColumnIndex:11]);
    }
    [_database close];
    
    
    NSLog(@"before : %@", songInfoOrigin.chord);
    
    self.songInfo = [self setPitchforSongInfo:songInfoOrigin pitchCount:_pitchCount];
    
    NSLog(@"after : %@", self.songInfo.chord);
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt: self.songInfo.song_info_id], @"songInfo.song_info_id",
            [NSNumber numberWithInt: self.songInfo.song_number], @" songInfo.song_number",
            self.songInfo.song_title, @"songInfo.song_title",
            [NSNumber numberWithInt: self.songInfo.category_1], @"songInfo.category_1",
            [NSNumber numberWithInt: self.songInfo.category_2], @"songInfo.category_2",
            self.songInfo.song_lyric_start, @"songInfo.song_lyric_start",
            self.songInfo.song_lyric_refrain, @"songInfo.song_lyric_refrain",
            self.songInfo.song_lyric_keyword, @"songInfo.song_lyric_keyword",
            self.songInfo.beat, @"songInfo.beat",
            self.songInfo.chord, @"songInfo.chord",
            self.songInfo.chord_pitch, @"songInfo.chord_pitch",
            self.songInfo.chord_option, @"songInfo.chord_option",
            [NSNumber numberWithInt: self.songInfo.bar_count], @"songInfo.bar_count",
            [NSNumber numberWithInt: self.songInfo.lyric_count], @"songInfo.lyric_count",
            [NSNumber numberWithInt: _pitchCount], @"songInfo.pitch_count",
            nil];
    
    [newBookmarkList addObject:dict];
    
    NSArray *bookmarkList = [newBookmarkList copy];
    NSLog(@"bookmarkList.count : %d", bookmarkList.count);
    
    [defaults setObject:bookmarkList forKey:@"bookmarkList"];
    [defaults synchronize];
    
    [self.view makeToast:@"플레이 리스트에 추가되었습니다."];
}

- (void) searchByYoutubeAction {
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
    
    NetworkStatus status = [reachability currentReachabilityStatus];
    
    if(status == NotReachable)
    {
        //No internet
        [self connectionErrorAlert];
    }
    else if (status == ReachableViaWiFi)
    {
        //WiFi
        [self connectToYoutube];
    }
    else if (status == ReachableViaWWAN)
    {
        //3G
        [self confirmConnectToYoutube];
    }
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
    
    // chord
    UILabel *chordLabel = nil;
    NSString *chordString = nil;
    
    if(![song.chord_1 isEqualToString:@""]){
//        chordString = [NSString stringWithFormat:@"%@%@", song.chord_1, song.chord_1_option];
        chordLabel = (UILabel *)[self.noteView viewWithTag:song.beat_index];
        chordString = [NSString stringWithFormat:@"%@", song.chord_1];
        [chordLabel setText:chordString];
    }

    if(![song.chord_2 isEqualToString:@""]){
        //        chordString = [NSString stringWithFormat:@"%@%@", song.chord_1, song.chord_1_option];
        chordLabel = (UILabel *)[self.noteView viewWithTag:(80000 +song.beat_index)];
        chordString = [NSString stringWithFormat:@"%@", song.chord_2];
        [chordLabel setText:chordString];
    }

    
    // chord pitch
    UILabel *chordPitchLabel = nil;
    NSString *chordPitchString = @"";
    
    if(![[song.chord_1_pitch stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]){
        chordPitchString = [NSString stringWithFormat:@"%@", [self getChordPitchString:[song.chord_1_pitch stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]]];
    }
    chordPitchLabel = (UILabel *)[self.noteView viewWithTag:(10000 +song.beat_index)];
    [chordPitchLabel setText:chordPitchString];
    
    
    if(![[song.chord_2_pitch stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]){
        chordPitchString = [NSString stringWithFormat:@"%@", [self getChordPitchString:[song.chord_2_pitch stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]]];
    }
    chordPitchLabel = (UILabel *)[self.noteView viewWithTag:(20000 +song.beat_index)];
    [chordPitchLabel setText:chordPitchString];
    
}




- (NSString*)getChordPitchString:(NSString*) chordPitch {
    
    NSString *returnChordPitchString = nil;
    
    if([chordPitch isEqualToString:@"+"]){
        returnChordPitchString = @"♯";
    } else if([chordPitch isEqualToString:@"-"]){
        returnChordPitchString = @"♭";
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



- (void)awesomeMenuDidFinishAnimationClose:(AwesomeMenu *)menu {
    NSLog(@"Menu was closed!");
}
- (void)awesomeMenuDidFinishAnimationOpen:(AwesomeMenu *)menu {
    NSLog(@"Menu is open!");
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"     // Event category (required)
                                                          action:@"button_press"  // Event action (required)
                                                           label:@"open detail menu"          // Event label
                                                           value:nil] build]];    // Event value
    
}

- (void) resetView {
    while ([self.view.subviews count] > 0)
    {
        [[[self.view subviews] objectAtIndex:0] removeFromSuperview];
    }
    
    [self.noteView removeFromSuperview];
    self.noteView = nil;
    
    [self.self.menu removeFromSuperview];
    self.self.menu = nil;
}

- (void)orientationChanged:(NSNotification *)notification
{
    
    if([_appDelegate isPad]){
    
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        
        if( (orientation == UIInterfaceOrientationPortrait) || (orientation == UIInterfaceOrientationLandscapeRight) || (orientation == UIInterfaceOrientationLandscapeLeft)) {
            [_noteScrollView removeFromSuperview];
            [_noteView removeFromSuperview];
            [_menu removeFromSuperview];
            [_prevSong removeFromSuperview];
            [_nextSong removeFromSuperview];
            
            [self initValue];
            
            self.noteScrollView = [[UIScrollView alloc] initWithFrame: CGRectMake(0, 64,_screenWidth,_screenHeight)];
            [self.noteScrollView setBackgroundColor: [UIColor clearColor]];
            [self.view addSubview: self.noteScrollView];
            
            // s: make view
            [self makeView];
            // e: make view
            
            // s: init note
            [self initNote];
            // e: init note
            
            // s: make note
            [self makeNote];
            // e: make note
            
            // s: make menu
            [self makeMenu];
            // e: make menu
            
            [self autoPitch];
            
            if(_isScaled){
                [self setScale:YES];
            }
        }
    
    }
    return;
    
}

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
    
    NSString *queryString = [NSString stringWithFormat:@"%@ ccm", _songInfo.song_title];
    NSString *query = [NSString stringWithFormat:@"http://www.youtube.com/results?search_query=%@", [queryString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
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
