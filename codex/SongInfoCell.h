//
//  SongInfoCell.h
//  codex
//
//  Created by Rock Kang on 2014. 5. 12..
//  Copyright (c) 2014년 neosave.me. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SongInfoCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *chordLabel;
@property (weak, nonatomic) IBOutlet UILabel *chordPitchLabel;
@property (weak, nonatomic) IBOutlet UILabel *chordOptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *beatLabel;
@end
