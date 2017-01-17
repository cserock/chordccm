//
//  SongInfoCell.m
//  codex
//
//  Created by Rock Kang on 2014. 5. 12..
//  Copyright (c) 2014년 neosave.me. All rights reserved.
//

#import "SongInfoCell.h"

@implementation SongInfoCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
