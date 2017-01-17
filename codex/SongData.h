//
//  SongData.h
//  codex
//
//  Created by Rock Kang on 2014. 5. 12..
//  Copyright (c) 2014년 neosave.me. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SongData : NSObject

@property (nonatomic, assign) int song_data_id;
@property (nonatomic, assign) int song_info_id;
@property (nonatomic, assign) int beat_index;
@property (nonatomic, copy) NSString *chord_1;
@property (nonatomic, copy) NSString *chord_1_pitch;
@property (nonatomic, copy) NSString *chord_1_option;
@property (nonatomic, copy) NSString *chord_2;
@property (nonatomic, copy) NSString *chord_2_pitch;
@property (nonatomic, copy) NSString *chord_2_option;
@property (nonatomic, assign) int rest_type;
@property (nonatomic, assign) int bar_type;
@property (nonatomic, copy) NSString *play_type;
@property (nonatomic, copy) NSString *expression;
@property (nonatomic, copy) NSString *lyric_1;
@property (nonatomic, copy) NSString *lyric_2;
@property (nonatomic, copy) NSString *lyric_3;
@property (nonatomic, copy) NSString *lyric_4;

@end
