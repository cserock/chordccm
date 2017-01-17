//
//  SongDetailViewController.h
//  codex
//
//  Created by Rock Kang on 2014. 5. 13..
//  Copyright (c) 2014년 neosave.me. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SongInfo.h"
#import "FMDB.h"
#import "AwesomeMenu.h"
#import "AppDelegate.h"

@interface SongDetailViewController : UIViewController <AwesomeMenuDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) NSMutableArray *song;
@property (nonatomic, strong) FMDatabase *database;
@property (nonatomic, strong) AppDelegate *appDelegate;

@property (nonatomic, strong) SongInfo *songInfo;
@property (nonatomic, strong) UIScrollView *noteView;
@property (nonatomic, strong) AwesomeMenu *menu;
@property (nonatomic, assign) BOOL isShowingLandscapeView;
@property (nonatomic, assign) int pitchCount;
@property (nonatomic, assign) int songBarCount;
@property (nonatomic, assign) int songLyricCount;
@property (nonatomic, assign) int tableCount;
@property (nonatomic, assign) int beatCountInBar;
@property (nonatomic, assign) int beatMaxCount;
@property (nonatomic, assign) int lastBeatIndex;

@property (nonatomic, strong) NSArray *chordArray;

@property (nonatomic, strong) NSString *beatAllString;
@property (nonatomic, strong) NSString *lyric_1_AllString;
@property (nonatomic, strong) NSString *lyric_2_AllString;
@property (nonatomic, strong) NSString *lyric_3_AllString;
@property (nonatomic, strong) NSString *lyric_4_AllString;

@property (nonatomic, assign)  CGFloat screenWidth;
@property (nonatomic, assign)  CGFloat screenHeight;
@property (nonatomic, assign)  float startY;
@property (nonatomic, assign)  float lineX;
@property (nonatomic, assign)  float lineHeight;
@property (nonatomic, assign)  float cellHeight;
@property (nonatomic, assign)  float barCountInLine;
@property (nonatomic, assign)  CGFloat menuMarginX;
@property (nonatomic, assign)  CGFloat fontSize;

@property (nonatomic, assign)  float lineMarginY;
@property (nonatomic, assign)  float lyricHeight;
@property (nonatomic, assign)  float chordPadding;


- (void) makeNote;
- (void) makeLine:(int)lineNum;
- (void) makeContent:(int)lineNum;
- (IBAction)backHome;
- (NSString*)upChord:(NSString*) chord;
- (NSString*)downChord:(NSString*) chord;
@end
