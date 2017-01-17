//
//  SongInfo.h
//  codex
//
//  Created by Rock Kang on 2014. 5. 12..
//  Copyright (c) 2014년 neosave.me. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SongInfo : NSObject

@property (nonatomic, assign) int song_info_id;
@property (nonatomic, assign) int song_number;
@property (nonatomic, copy) NSString *song_title;
@property (nonatomic, assign) int category_1;
@property (nonatomic, assign) int category_2;
@property (nonatomic, copy) NSString *song_lyric_start;
@property (nonatomic, copy) NSString *song_lyric_refrain;
@property (nonatomic, copy) NSString *song_lyric_keyword;
@property (nonatomic, copy) NSString *beat;
@property (nonatomic, copy) NSString *chord;
@property (nonatomic, copy) NSString *chord_pitch;
@property (nonatomic, copy) NSString *chord_option;
@property (nonatomic, assign) int bar_count;
@property (nonatomic, assign) int pitch_count;
@property (nonatomic, assign) int lyric_count;

@end
